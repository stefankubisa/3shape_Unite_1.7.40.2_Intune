$software = "Microsoft Visual C++ 2012 Redistributable (x64) - 11.0.61030";
$installed = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null
If(-Not $installed) {
    Start-Process -FilePath "C:\3Shape\VC_redist2012.x64.exe" -ArgumentList "/install /quiet /norestart" -Wait;
}
else {
    Write-Host "'$software' is installed."
}

$software = "Microsoft Visual C++ 2015-2022 Redistributable (x64) - 14.34.31931";
$installed = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null
If(-Not $installed) {
    Start-Process -FilePath "C:\3Shape\VC_redist2012.x64.exe" -ArgumentList "/install /quiet /norestart" -Wait;
}
else {
    Write-Host "'$software' is installed."
}

$software = "Microsoft Visual C++ 2015-2019 Redistributable (x86) - 14.29.30037";
$installed = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $software }) -ne $null
If(-Not $installed) {
    Start-Process -FilePath "C:\3Shape\VC_redist2012.x64.exe" -ArgumentList "/install /quiet /norestart" -Wait;
}
else {
    Write-Host "'$software' is installed."
}

# checking and installing all required redistributables if they aren't present 

$MSIArguments = @(
    "/i"
    "C:\3Shape\sqlncli_64bit.msi"
    "/qn"
    "/quiet"
    "ADDLOCAL=ALL"
    "IACCEPTSQLNCLILICENSETERMS=YES"
    )

$SQLArguments = @(
    '/Q'
    '/ACTION=Install'
    '/SAPWD=3SDMdbmspw'
    '/INSTANCENAME=THREESHAPEDENTAL'
    '/INSTANCEID=THREESHAPEDENTAL'
    '/FEATURES=SQL'
    '/SQLSYSADMINACCOUNTS="Builtin\Administrators"'
    '/AGTSVCACCOUNT="NT AUTHORITY\Network Service"'
    '/SECURITYMODE=SQL'
    '/IAcceptSQLServerLicenseTerms=TRUE'
    '/TCPENABLED=1'
    )

# arguments for later use as parameters in installers, also used to reinstall certain parts of the setup 

$service = Get-Service -Name 'MSSQL$THREESHAPEDENTAL' -ErrorAction SilentlyContinue
if($service -eq $null)
{    
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow;
    # SQL server installation 
    start-sleep 10
    Start-Process -FilePath "C:\3Shape\SQLEXPR_x64_ENU\SETUP.exe" -ArgumentList $SQLArguments -Wait; 
    # server instatntiation and setting up 
} else 
{
    Write-Host "SQL Server is already installed."
}

Start-Sleep -Seconds 10 

Import-Certificate -FilePath C:\3Shape\TRIOS\Certificate\certificate.cer -CertStoreLocation Cert:\LocalMachine\TrustedPublisher
# importing of the TRIOS certificate as a trusted publisher on the local machine 
Start-Sleep -Seconds 5

Start-Process -FilePath "C:\3Shape\TRIOS\ScannerSetup.Helper.exe" -ArgumentList "/install" -Wait
# ???

Start-Sleep -Seconds 5

$acl = Get-Acl "C:\Programdata\3Shape\DentalDesktop" 
# getting the security descriptor for the dental desktop frontend app to change it's permissions 
$AccessRule = [System.Security.AccessControl.FileSystemAccessRule]::new("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($AccessRule)
$acl | Set-Acl "C:\Programdata\3Shape\DentalDesktop"
# we apply those permissions so regardless of what account is logged into the device it is able to launch the 3shape unite app 

Start-Sleep -Seconds 5 

Install-PackageProvider NuGet -Force;
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module SQLServer -Repository PSGallery 
# the SQL server that we install here is required to "restore" a database setup that has all configurations for a country 
Restore-SqlDatabase -ServerInstance ".\THREESHAPEDENTAL" -ReplaceDatabase "DentalDesktop" -BackupFile C:\Programdata\3Shape\DentalDesktop\Backup.bak 
# this is the install of the state of the app through a backup restore process 
New-NetFirewallRule -Program "C:\Program Files\3Shape\Dental Desktop\DentalDesktop.exe" -DisplayName 'DentalDesktop.exe' -Profile @('Domain', 'Private', 'Public') -Direction Inbound -Action Allow
New-NetFirewallRule -Program "C:\Program Files\3Shape\Dental Desktop\DentalDesktop.exe" -DisplayName 'DentalDesktop.exe' -Profile @('Domain', 'Private', 'Public') -Direction Outbound -Action Allow 
# those 2 rules facilitate communications between the front-end and back-end of the 3shape unite install 

Start-Sleep -Seconds 5
Copy-Item C:\Programdata\3Shape\DentalDesktop\ConfigurationDownload\downloadedfiles\e07717a5-6cc6-44b1-8827-516fbf4df9cb C:\Programdata\3Shape\DentalDesktop\ServerPackages\DentalDesktopSetup-1.7.40.2.exe
# ??? 

Start-Sleep -Seconds 5

Start-Process -FilePath "C:\Programdata\3Shape\DentalDesktop\ServerPackages\DentalDesktopSetup-1.7.40.2.exe" -ArgumentList "/installationType=0 /silent /norestart /donotrun /nocancel" -Wait;
# initial start of the app 

Start-Sleep -Seconds 5

$service = Get-Service -Name 'DentalDesktopServer' -ErrorAction SilentlyContinue
if($service -eq $null)
{   New-Service -Name "DentalDesktopServer" -BinaryPathName C:\Program Files\3Shape\Dental Desktop\DentalDesktopServer.NTService.exe
}
# starting of the dental desktop server service in the case it didn't, this part used ot be fixed after the installations and restarting by the .bat to .exe to .intunewin thing that had the app installation as a dependency 

Set-Service -Name ThreeShape.DataService -StartupType Automatic
# setting of that service up for automatic starting when the device starts 

New-ItemProperty -Path "HKCU:\SOFTWARE\3Shape\DentalDesktop" -Name "licenseTermsAccepted" -Value "True"  -PropertyType "String" -Force
# license terms of the frontend accepting 

$Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Result = $Time + 'Z'
New-ItemProperty -Path "HKCU:\SOFTWARE\3Shape\DentalDesktop" -Name "licenseTermsAcceptedTimestamp" -Value "$Result"  -PropertyType "String" -Force
New-ItemProperty -Path "HKCU:\SOFTWARE\3Shape\DentalDesktop" -Name "licenseTermsAcceptedVersion" -Value "24-09-2020"  -PropertyType "String" -Force
# setting of the timezone cause the app needs it to be correct 

$hostname = get-content env:computername
if ($Hostname -cmatch 'DRS-SC')
{ New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "TRIOSShell" -Value "C:\Program Files\3Shape\TRIOS Shell\TRIOSShell.exe"  -PropertyType "String" -Force
 }
Else {
    Remove-Item "$Env:USERPROFILE\Desktop\3Shape Unite.lnk" -Force;
    Remove-Item "$Env:PUBLIC\Desktop\3Shape Unite.lnk" -Force;
    Start-Sleep -Seconds 5;
    Copy-Item -Path "C:\3Shape\TRIOS\3Shape Unite.lnk" -Destination "$Env:PUBLIC\Desktop\3Shape Unite.lnk" -Force;
}
# if the hostname matches our scanner pattern the trios shell is set to start and made to take over the screen so clicking on the windows task bar becomes harder 

#this is for later when we no longer need a .bat file to prefix to this deplyment for the .net framework installation 
#Start-Sleep 10
#Restart-Computer -Force
