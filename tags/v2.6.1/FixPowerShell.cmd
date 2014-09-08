@echo off
echo By default, PowerShell is configured to block the
echo execution of unsigned scripts on your local system.
echo This command file will attempt to modify your
echo PowerShell ExecutionPolicy to "Unrestricted"
echo which means that local scripts can be run without
echo being signed.  This is required to use the RomWBW
echo build process.
echo.
PowerShell -command Write-Host "Your PowerShell ExecutionPolicy is currently set to: `'(Get-ExecutionPolicy)`'"
echo.
echo In order to modify the ExecutionPolicy, this command
echo file *MUST* be run with administrator privileges.
echo Generally, this means you want to right-click the
echo command file called FixPowerShell.cmd and choose
echo "Run as Administrator".  If you attempt to continue
echo without administrator privileges, the modification
echo will fail with an error message, but no harm is done.
echo.
choice /m "Do you want to proceed"
if errorlevel 2 goto :eof
echo.
echo Attempting to change Execution Policy...
echo.
PowerShell Set-ExecutionPolicy Unrestricted
echo.
PowerShell -command Write-Host "Your new PowerShell ExecutionPolicy is now set to: `'(Get-ExecutionPolicy)`'"
echo.
pause