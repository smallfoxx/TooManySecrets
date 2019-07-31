Set-Variable -Name "RegPath" `
    -Value "HKCU:\Software\TooManySecrets" `
    -Option ReadOnly `
    -Visibility Private 

    
$ExcludeProperties = @("SettingsFile")


Function Get-ModuleName() {

    If ($PSScriptRoot) {
        return (Split-Path $PSScriptRoot -Leaf)
    } else {
        "TooManySecret"
    }
}
Function Get-SettingPath() {
    param([switch]$UserOnly,
        [switch]$DefaultSettings)

    $DefaultUserPath = "$HOME\AppData\Roaming\$(Get-ModuleName)"
    $DefaultSharedPath = $PSScriptRoot
    $ConfigFileName = "$(Get-ModuleName).json"

    If ($TMSSetting -and -not $UserOnly) {
        return $TMSSetting.SettingsFile
    } elseif ($UserOnly -or (-not $DefaultSettings -and (Test-Path "$DefaultUserPath\$ConfigFileName"))) {
        return "$DefaultUserPath\$ConfigFileName"
    } elseif ( -not $UserOnly -and (Test-Path "$DefaultSharedPath\$ConfigFileName")) {
        return "$DefaultSharedPath\$ConfigFileName"
    }
}

Function Update-ModuleDetails() {

    If ($TMSSettings) {
        $Module = Get-Module ($TMSSettings.ModuleName)
        If ($Module) {
            Set-TooManySetting -Name "ModuleVersion" -Value $Module.Version
            Set-TooManySetting -Name "ModulePath" -Value $Module.Path
        }
    }

}

Function Import-TooManySetting() {
    param([string]$SettingsFile=(Get-SettingPath))

    write-host "Settings file [$SettingsFile]"
    If (Test-Path $SettingsFile) {

    } else {
        $SettingsFile = Get-SettingPath -DefaultSettings
    }

    $Settings = Get-Content $SettingsFile | ConvertFrom-Json 

    If ($Settings) {
        $Settings | Add-Member NoteProperty SettingsFile $SettingsFile -Force
        Set-Variable -Name "TMSSettings" -Value $Settings -Scope Global -Visibility Private
        Update-ModuleDetails
        If ($PassThru) { return $TMSSettings }
    }
}

Function Export-TooManySetting() {
    param([string]$SettingsFile=(Get-SettingPath))

    $JSONSettings = ConvertTo-Json ($TMSSettings | Select-Object * -ExcludeProperty $ExcludeProperties) 
    try {
        Set-Content -path $SettingsFile -Value $JSONSettings
    } catch {
        $UserSettingsFile = Get-SettingPath -UserOnly
        If ($SettingsFile -ne $UserSettingsFile) {
            $Folder = Split-Path $UserSettingsFile
            If (-not (Test-Path $folder)) { New-item -Path $Folder -ItemType Directory | Out-Null } 
            Set-Content -path $UserSettingsFile -Value $JSONSettings -Force
        }
    }
}

Function Get-TooManySetting() {
    param([string]$Name)
    
    If (-Not $TMSSettings) { Import-TooManySetting }
    If ($TMSSettings) {
        return $TMSSettings.$Name
    }

}

Function Set-TooManySetting() {
    param([string]$Name,
        $Value )

    If (-Not $TMSSettings) { Import-TooManySetting }
    If ($TMSSettings) {
        $TMSSettings | Add-Member NoteProperty $Name $Value -Force
        Export-TooManySetting
    }
}

Function Test-TooManySetting() {
    param([string]$Name)

    If (-Not $TMSSettings) { Import-TooManySetting }
    $TMSSettings.ContainsKey($Name)

}

Function Register-TooManySetting() {
    param([string]$Path)

    Write-Warning "The command Register-TooManySetting is depreciated and will be removed in the next deployment.  Use Import-TooManySetting instead."

    Import-TooManySetting -SettingsFile $Path

}


function Get-Variables() {
    Get-Variable
}

#region Alias Listings
$aliases = @{ "Get-TooManySetting"=@() }
$aliases += @{ "Set-TooManySetting"=@() }
$aliases += @{ "Test-TooManySetting"=@() }
$aliases += @{ "Register-TooManySetting"=@() }
$aliases += @{ "Import-TooManySetting"=@() }
$aliases += @{ "Export-TooManySetting"=@() }
$aliases += @{ "Get-Variables"=@() }

#region Publish Members
foreach ($func in $aliases.Keys) {
    If ($aliases[$func].length -gt 0) {
        foreach ($alias in ($aliases[$func])) {
            # If (-not (Get-Command $alias)) { New-Alias -Name $alias -Value $func -PassThru }
            New-Alias -Name $alias -Value $func -PassThru 
        }
        Export-ModuleMember -function $func -alias ($aliases[$func]) 
    } else {
        Export-ModuleMember -function $func
    }
}
#endregion
#endregion
