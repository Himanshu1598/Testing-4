param (
    [string]$Action,
    [string]$DacpacFilePath,
    [string]$PublishProfileFilePath,
    [string]$OutputFilePath,
    [string]$SqlCmdVariables,
    [string]$SqlPackageProperties,
    [string]$SqlPackageParameters,
    [string]$ConnectionString
)

# Define the log file location
$LogFile = "C:\Deployment\debug_log.txt"

# Ensure the directory exists
$LogDir = Split-Path -Path $LogFile
if (!(Test-Path -Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force
}

# Log the received parameters
Write-Output "----- Parameter Test Log -----" | Out-File -FilePath $LogFile -Append
Write-Output "Action: $Action" | Out-File -FilePath $LogFile -Append
Write-Output "DacpacFilePath: $DacpacFilePath" | Out-File -FilePath $LogFile -Append
Write-Output "PublishProfileFilePath: $PublishProfileFilePath" | Out-File -FilePath $LogFile -Append
Write-Output "OutputFilePath: $OutputFilePath" | Out-File -FilePath $LogFile -Append
Write-Output "SqlCmdVariables: $SqlCmdVariables" | Out-File -FilePath $LogFile -Append
Write-Output "SqlPackageProperties: $SqlPackageProperties" | Out-File -FilePath $LogFile -Append
Write-Output "SqlPackageParameters: $SqlPackageParameters" | Out-File -FilePath $LogFile -Append
Write-Output "ConnectionString: $ConnectionString" | Out-File -FilePath $LogFile -Append
Write-Output "------------------------------" | Out-File -FilePath $LogFile -Append

# Simulate success response
Write-Output "Test Execution Complete"
Exit 0
