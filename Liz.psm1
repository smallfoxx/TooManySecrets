Set-Variable -Name "RegPath" `
    -Value "HKCU:\Software\TooManySecrets" `
    -Option ReadOnly `
    -Visibility Private 

Set-Variable -Name "TMSSettingsTable" `
    -Value $null `
    -Option AllScope
    
$ExcludeSettingProperties = @("SettingsFile")


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
            If ($Module.Path -like "$HOME*") { 
                Set-TooManySetting -Name "ModulePath" -Value ("{0}{1}" -f "`$HOME",($Module.Path.Remove(0,$HOME.Length)))
            } else {
                Set-TooManySetting -Name "ModulePath" -Value $Module.Path
            }
        }
    }

}

Function Reset-TooManySettings() {
    param([switch]$DoNotImport,
        [switch]$Save)

    If ($TMSSettings) {
        write-host "Resetting..."
    
        If ($Save) {
            Export-TooManySetting
        }

        Set-Variable -Name "TMSSettings" -Scope Global -Value $TMSSettings -Visibility Public
        Remove-Variable -Name "TMSSettings" -Scope Global -Force
    }

    If (-not $DoNotImport) {
        Import-TooManySetting
    }
}
Function Import-TooManySetting() {
    param([string]$SettingsFile=(Get-SettingPath),
        [switch]$UpdateFromTable)

    write-Debug "Settings file [$SettingsFile]"
    If (Test-Path $SettingsFile) {

    } else {
        $SettingsFile = Get-SettingPath -DefaultSettings
    }

    $Settings = Get-Content $SettingsFile | ConvertFrom-Json 

    If ($Settings) {
        $Settings | Add-Member NoteProperty SettingsFile $SettingsFile -Force
        Set-Variable -Name "TMSSettings" -Value $Settings -Scope Global #-Visibility Private
        Update-ModuleDetails
        If ($TMSSettings.SettingsTableName) {
            If (-not $TMSSettingsTable) { Select-TooManySettingsTable }
            If ($TMSSettingsTable) {
                $SettingsRow = Get-AzTableRow -Table $TMSTable -PartitionKey "Secrets" -RowKey "TMSSettings" | Select-Object * -ExcludeProperty $SpecialRowProperties
                ForEach ($Column in ($SettingsRow | Get-Member -MemberType *Property)) {
                    Set-TooManySetting -Name $Column.Name -Value $SettingsRow.($ColumnName) -DoNotOverwrite:(-not $UpdateFromTable)
                }
            }
        }
        If ($PassThru) { return $TMSSettings }
    }
}

Function Export-TooManySetting() {
    param([string]$SettingsFile=(Get-SettingPath))

    #Write-Debug "Using settings file [$SettingsFile]..."
    If ($SettingsFile -ne (Get-TooManySetting -Name SettingsFile)) { $TMSSettings.SettingsFile = $SettingsFile }
    $SettingsToExport = ($TMSSettings | Select-Object * -ExcludeProperty $ExcludeSettingProperties)
    $SettingsHash = @{}
    ForEach ($SettingProperty in ($SettingsToExport | Get-Member -MemberType *Property )) {
        $SettingsHash.($SettingProperty.Name) = $TMSSettings.($SettingProperty.Name)
    }
    If ($TMSSettingsTable) {
        Add-AzTableRow -Table $TMSSettingsTable -PartitionKey "Secrets" -RowKey "TMSSettings" `
            -UpdateExisting -property $SettingsHash | Out-Null
    }
    $JSONSettings = ConvertTo-Json $SettingsToExport 
    try {
        Write-Debug "Writing settings to file [$SettingsFile]..."
        Set-Content -path $SettingsFile -Value $JSONSettings -ErrorAction Continue
    } catch {
        $UserSettingsFile = Get-SettingPath -UserOnly
        Write-Debug "Attempting to write settings to user profile [$UserSettingsFile]..."
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
        $Value,
        [switch]$DoNotOverwrite )

    If (-Not $TMSSettings) { Import-TooManySetting }
    If ($TMSSettings) {
        If (-not ($DoNotOverwrite -and $TMSSettings.$Name)) {
            $TMSSettings | Add-Member NoteProperty $Name $Value -Force
            Export-TooManySetting
        }
    }
}

Function Select-TooManySettingsTable() {
    param([string]$TableName=(Get-TooManySetting -Name "SettingsTableName"),
        [string]$StorageAccountName=(Get-TooManySetting -Name "StorageAccountName"),
        [string]$StorageAccountRG=(Get-TooManySetting -Name "StorageAccountRG") )

    If ($TMSSettings) {
        If ($TableName -and $StorageAccountName -and $StorageAccountRG) {
            If ($TMSStorage.StorageAccountName -eq $StorageAccountName -and $TMSStorage.ResourceGroupName -eq $StorageAccountRG) {
                $SettingsStorage = $TMSStorage
            } else {
                $SettingsStorage = Get-AzStorageAccount -ResourceGroupName $StorageAccountRG `
                    -Name $StorageAccountName
            }
            If ($SettingsStorage) {
                $TMSSettingsTable = (Get-AzStorageTable -Name $TableName -Context $SettingsStorage.Context -ErrorAction SilentlyContinue).CloudTable
                If ($TMSSettingsTable) {
                    Set-TooManySetting -Name "StorageAccountName" -Value $StorageAccountName -DoNotOverwrite
                    Set-TooManySetting -Name "StorageAccountRG" -Value $StorageAccountRG -DoNotOverwrite
                    Set-TooManySetting -Name "SettingsTableName" -Value $TableName
                }
            }
        }

    }
}

Function Test-TooManySetting() {
    param([string]$Name)

    If (-Not $TMSSettings) { Import-TooManySetting }
    return ($null -ne ($TMSSettings | Get-Member $Name))

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
$aliases += @{ "Select-TooManySettingsTable"=@() }
$aliases += @{ "Reset-TooManySettings"=@() }
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
