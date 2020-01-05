$ClassModule = "Bishop.psm1"
if (Test-Path "$PSScriptRoot\$ClassModule") {
    #this is to get the class definitions shared between modules
    $script = [ScriptBlock]::Create("using module '$PSScriptRoot\$ClassModule'")
    . $script
}

$ModuleSettings = New-Object TMSModuleSettings

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

    If ($ModuleSettings.Configs) {
        $Module = Get-Module ($ModuleSettings.Configs.ModuleName)
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

    If ($ModuleSettings.Configs) {
        write-host "Resetting..."
    
        If ($Save) {
            Export-TooManySetting
        }

        #Set-Variable -Name "TMSSettings" -Scope Global -Value $ModuleSettings.Configs -Visibility Public
        #Remove-Variable -Name "TMSSettings" -Scope Global -Force
        $ModuleSettings.Configs = $Null
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
        #Set-Variable -Name "TMSSettings" -Value $Settings -Scope Global -Visibility Private
        $ModuleSettings.Configs = $Settings
        Update-ModuleDetails
        If ($ModuleSettings.Configs.SettingsTableName) {
            If (-not $ModuleSettings.SettingsTable) { Select-TooManySettingsTable }
            If ($ModuleSettings.SettingsTable) {
                $SettingsRow = Get-AzTableRow -Table $ModuleSettings.Table -PartitionKey "Secrets" -RowKey "TMSSettings" | Select-Object * -ExcludeProperty $ModuleSettings.SpecialRowProperties
                ForEach ($Column in ($SettingsRow | Get-Member -MemberType *Property)) {
                    Set-TooManySetting -Name $Column.Name -Value $SettingsRow.($ColumnName) -DoNotOverwrite:(-not $UpdateFromTable)
                }
            }
        }
        If ($PassThru) { return $ModuleSettings.Configs }
    }
}

Function Export-TooManySetting() {
    param([string]$SettingsFile=(Get-SettingPath))

    #Write-Debug "Using settings file [$SettingsFile]..."
    If ($SettingsFile -ne (Get-TooManySetting -Name SettingsFile)) { $ModuleSettings.Configs.SettingsFile = $SettingsFile }
    $SettingsToExport = ($ModuleSettings.Configs | Select-Object * -ExcludeProperty $ModuleSettings.ExcludeSettingProperties)
    $SettingsHash = @{}
    ForEach ($SettingProperty in ($SettingsToExport | Get-Member -MemberType *Property )) {
        $SettingsHash.($SettingProperty.Name) = $ModuleSettings.Configs.($SettingProperty.Name)
    }
    If ($ModuleSettings.SettingsTable) {
        Add-AzTableRow -Table $ModuleSettings.SettingsTable -PartitionKey "Secrets" -RowKey "TMSSettings" `
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
    
    If (-Not $ModuleSettings.Configs) { Import-TooManySetting }
    If ($ModuleSettings.Configs) {
        return $ModuleSettings.Configs.$Name
    }

}

Function Set-TooManySetting() {
    param([string]$Name,
        $Value,
        [switch]$DoNotOverwrite )

    If (-Not $ModuleSettings.Configs) { Import-TooManySetting }
    If ($ModuleSettings.Configs) {
        If (-not ($DoNotOverwrite -and $ModuleSettings.Configs.$Name)) {
            $ModuleSettings.Configs | Add-Member NoteProperty $Name $Value -Force
            Export-TooManySetting
        }
    }
}

Function Select-TooManySettingsTable() {
    param([string]$TableName=(Get-TooManySetting -Name "SettingsTableName"),
        [string]$StorageAccountName=(Get-TooManySetting -Name "StorageAccountName"),
        [string]$StorageAccountRG=(Get-TooManySetting -Name "StorageAccountRG") )

    If ($ModuleSettings.Configs) {
        If ($TableName -and $StorageAccountName -and $StorageAccountRG) {
            If ($ModuleSettings.Table.StorageAccountName -eq $StorageAccountName -and $ModuleSettings.Table.ResourceGroupName -eq $StorageAccountRG) {
                $SettingsStorage = $ModuleSettings.Table
            } else {
                $SettingsStorage = Get-AzStorageAccount -ResourceGroupName $StorageAccountRG `
                    -Name $StorageAccountName
            }
            If ($SettingsStorage) {
                $ModuleSettings.SettingsTable = (Get-AzStorageTable -Name $TableName -Context $SettingsStorage.Context -ErrorAction SilentlyContinue).CloudTable
                If ($ModuleSettings.SettingsTable) {
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

    If (-Not $ModuleSettings.Configs) { Import-TooManySetting }
    return ($null -ne ($ModuleSettings.Configs | Get-Member $Name))

}

Function Register-TooManySetting() {
    param([string]$Path)

    Write-Warning "The command Register-TooManySetting is depreciated and will be removed in the next deployment.  Use Import-TooManySetting instead."

    Import-TooManySetting -SettingsFile $Path

}
