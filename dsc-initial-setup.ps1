param (
    [Parameter(Mandatory = $true)]
    [string]$DomainName,
    [Parameter(Mandatory = $true)]
    [string]$AdminUsername,
    [Parameter(Mandatory = $true)]
    [string]$AdminPassword
)

[string]$ScriptUri = "https://raw.githubusercontent.com/kosmolito/v36-azure-arm-template/main/dsc-config.ps1"
$ScriptName = Split-Path $ScriptUri -Leaf
$ScriptPath = "C:\$($ScriptName)"
$DSCConfigFolder = "C:\DSCConfig"
if (!(Test-Path $DSCConfigFolder)) {
    New-Item -Path $DSCConfigFolder -ItemType Directory | Out-Null
}

Invoke-WebRequest -Uri $ScriptUri -OutFile $ScriptPath -UseBasicParsing
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

$Modules = @{
    "xActiveDirectory" = "3.0.0.0"
    "xDSCDomainjoin"   = "1.2.23"
    "xNetworking"      = "5.7.0.0"
}

$Modules.GetEnumerator() | ForEach-Object {
    $ModuleName = $_.Key
    $ModuleVersion = $_.Value
    Install-Module -Name $ModuleName -RequiredVersion $ModuleVersion -Force -Scope AllUsers
}

if (!(Test-Path $ScriptPath)) {
    Write-Error "Script not found at $ScriptPath"
    Exit 1
} else {
    Write-Output "Running $ScriptPath"
    powershell.exe -ExecutionPolicy Bypass -File $ScriptPath -DomainName $DomainName -AdminUsername $AdminUsername -AdminPassword $AdminPassword
}
