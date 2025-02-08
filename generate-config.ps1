param (
    [string]$environment
)

# Ensure AWS credentials are set
if (-not $env:AWS_ACCESS_KEY_ID -or -not $env:AWS_SECRET_ACCESS_KEY -or -not $env:AWS_DEFAULT_REGION) {
    Write-Error "🚨 AWS credentials or region not set. Please configure them before running the script."
    exit 1
}

# Import necessary modules
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}
if (-not (Get-Module -ListAvailable -Name AWSPowerShell)) {
    Install-Module -Name AWSPowerShell -Force -Scope CurrentUser
}
Import-Module powershell-yaml
Import-Module AWSPowerShell

# Load YAML file
$yamlPath = ".\variables.yaml"
$yamlContent = Get-Content -Raw -Path $yamlPath
$variables = (ConvertFrom-Yaml $yamlContent).library_sets

# Function to fetch values from AWS Parameter Store
function Get-AwsParameterValue {
    param (
        [string]$parameterName
    )
    try {
        # Validate AWS Region
        if (-not $env:AWS_DEFAULT_REGION) {
            Write-Error "🚨 AWS region not set. Cannot fetch parameter: $parameterName"
            return $null
        }

        $response = Get-SSMParameter -Name $parameterName -WithDecryption $true -Region $env:AWS_DEFAULT_REGION
        return $response.Value
    } catch {
        Write-Output "⚠️ Error fetching parameter '$parameterName': $_"
        return "Error fetching parameter: $parameterName"
    }
}

# Consolidate environment-specific and default values
$consolidatedVars = @{}
foreach ($key in $variables.Keys) {
    $value = $null
    if ($variables[$key] -is [System.Collections.Hashtable]) {
        # **First, check if an environment-specific value exists**
        if ($variables[$key].ContainsKey("environments") -and $variables[$key].environments.ContainsKey($environment)) {
            $value = $variables[$key].environments[$environment]["value"]
        }
        # **If no environment-specific value, fall back to default**
        elseif ($variables[$key].ContainsKey("value")) {
            $value = $variables[$key]["value"]
        }
    }

    # **Replace AWS placeholders with actual values**
    if ($value -match '^\{\{AWS:(.+?)\}\}$') {
        $parameterName = $matches[1]
        $awsValue = Get-AwsParameterValue -parameterName $parameterName
        if ($awsValue -match "Error fetching parameter") {
            Write-Output "⚠️ Keeping placeholder for '$parameterName' due to fetch error."
        } else {
            $value = $awsValue
        }
    }

    # **Preserve values with backslashes correctly**
    if ($value -match '\\') {
        $value = $value -replace '\\', '\\'  # Escape backslashes correctly
    }

    # **Only add valid values to consolidated variables**
    if (![string]::IsNullOrWhiteSpace($key) -and (![string]::IsNullOrWhiteSpace($value))) {
        $consolidatedVars[$key] = $value
    }
}

# Exit if no variables were consolidated
if ($consolidatedVars.Count -eq 0) {
    Write-Output "🚨 No variables found for environment '$environment'. Exiting."
    exit 1
}

# Write the consolidated variables to a PowerShell script
$configFilePath = ".\config.ps1"
$consolidatedVars.GetEnumerator() | ForEach-Object {
    $key = $_.Key
    $value = $_.Value
    if (![string]::IsNullOrWhiteSpace($key) -and (![string]::IsNullOrWhiteSpace($value))) {
        "Set-Variable -Name '${key}' -Value '${value}'"
    } else {
        Write-Output "⚠️ Skipping invalid entry: Key='${key}', Value='${value}'"
    }
} | Out-File -FilePath $configFilePath -Encoding UTF8

Write-Output "✅ Variables successfully written to ${configFilePath}."
