
#region Classes
class TMSPresets {
    TMSPresets() {
        $this.Initialize()
    }

    hidden [void] Initialize() {
        $this | Add-Member -Force ScriptProperty SpecialRowProperties  { @("Etag","PartitionKey","RowKey","TableTimestamp") }
        $this | Add-Member -Force ScriptProperty CommonParameters { @("Debug","ErrorAction","ErrorVariable","Force","InformationAction","InformationVariable","OutVariable","OutBuffer","PipelineVariable","Verbose","WarningAction","WarningVariable","WhatIf","Confirm","PassThru") }
        $this | Add-Member -Force ScriptProperty ExcludeMetaProperties { 
            $this.SpecialRowProperties + `
                $this.CommonParameters + `
                @("Secret","Name","Property","SecureValue","DisablePrevious","ImportTags","Attributes","ContentType","Created","Enabled","Expires","Id","NotBefore","SecretValueText","Tags","TagsTable","Updated","VaultName","Version")
        }

        $this | Add-Member -Force ScriptProperty RegPath {"HKCU:\Software\TooManySecrets" }
        $this | Add-Member -Force NoteProperty TMSSettingsTable $null 
        $this | Add-Member -Force ScriptProperty ExcludeSettingProperties { @("SettingsFile") }
     
        $this | Add-Member -Force ScriptProperty DefaultCharSet { "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23465789#%&'()*+,-./[\]^_{}~" }

    }
}

class TMSSecret {
    hidden [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecret] $_AzSecret
    hidden [string[]]$IncludeProperties = @('SecretID','URL','Username','Created', `
        'Enabled','Expires','Id','Name','NotBefore','SecretValue','Updated', `
        'VaultName','Version')

    [string]$Name
    [SecureString]$SecretValue

    TMSSecret() {
        $this.Initialize()
    }

    TMSSecret([Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecret]$Secret) {
        $this._AzSecret = $Secret
        $this.UpdateFromSecret($Secret)
        $this.Initialize()
    }

    hidden [void] Initialize() {
        $this | Add-Member -MemberType ScriptProperty -Name Credential `
            -Value { [PSCredential]::New($this.Username,$this.SecretValue) } `
            -SecondValue { if ($value -is [PSCredential]) { $this.Username = $Value.Username; $this.SecretValue = $Value.Password } }
    }

    hidden [void] UpdateFromSecret() {
        If ($this._AzSecret) {
            $this.UpdateFromSecret($this._AzSecret)
        }
    }

    hidden [void] UpdateFromSecret([Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecret]$Secret) {
        $Properties = $Secret | get-Member -type *propert* | Where-Object { $this.IncludeProperties -contains $_.name}
        ForEach ($Prop in $Properties) {
            Write-Debug "Populating [$($Prop.name)] property"
            if ($null -ne $Secret.($Prop.Name)) {
                $this.AddProp($Prop.Name,$Secret.($Prop.Name))
            }
        }
    }

    [void] CopyToClipboard() {
        $this.CopyToClipboard(-1)
    }

    [void] CopyToClipboard([int]$timer=-1) {
        $this.CopyToClipboard($timer,10)
    }

    [void] CopyToClipboard([int]$timer=-1,[int]$MaxClear=10) {
        $this.CopyToClipboard($timer,$MaxClear,$MaxClear)
    }

    [void] CopyToClipboard([int]$timer=-1,[int]$MaxClear=10,[int]$MaxPreface=$MaxClear) {
        If ($timer -gt 0) {
            #put random values into the clipboard before the actual value is added
             1..(Get-Random -minimum 3 -Maximum $MaxPreface) | ForEach-Object { (1..(Get-Random -minimum 8 -Maximum 64) | ForEach-Object { [char](Get-Random -Minimum 32 -Maximum 127)} ) -join '' | Set-Clipboard }
        }

        ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto( `
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.SecretValue) `
        )) | Set-Clipboard

        If ($timer -gt 0) {
            $wait = 0
            Do {
                Write-Progress -Activity "Copied secret [$($this.name)] to clipboard." -status "Will clear clipboard in [$($timer-$wait)] seconds" -PercentComplete (100*$wait/$timer) -Completed:($wait -ge $timer)
                Start-Sleep -Seconds 1
                $wait++
            } Until ($wait -gt $timer)
            1..(Get-Random -minimum 3 -Maximum $MaxClear) | ForEach-Object { (1..(Get-Random -minimum 8 -Maximum 64) | ForEach-Object { [char](Get-Random -Minimum 32 -Maximum 127)} ) -join '' | Set-Clipboard }
            ' ' | Set-Clipboard
        }
    }

    [void] AddProp([string]$Name, $Value) {
        $this | Add-Member -Force NoteProperty $Name $Value
    }
}

#endregion Classes

 
<#
function Verb-Noun {
<#
.SYNOPSIS
Short summary
.DESCRIPTION
Detailed description.
.PARAMETER Param1
What the parameter is used for
.PARAMETER Param2
What the parameter is used for
.PARAMETER CommonOptionalParam3
What the parameter is used for
.EXAMPLE
PS> Verb-Noun -Param1 'Value' -CommonOptionalParam3 $Something
Description of what this example does
.EXAMPLE
PS> @($Param2Input, ParamTwoInput) | Verb-Noun -CommonOptionalParam3 "Another entry"
Description of what this example does
.LINK
External link #1
External link #2
#
    [CmdletBinding(DefaultParameterSetName="ParamSet1")]
    param (
        [parameter(ValueFromPipeline=$true,Mandatory=$true,ParameterSetName="ParamSet1",Position=1)][type1]$Param1,
        [parameter(ValueFromPipeline=$true,Mandatory=$true,ParameterSetName="ParamSet2",Position=1)][type2]$Param2,
        [parameter(Position=2)][type]$CommonOptionalParam3
    )
    
    begin {
        # Run once before any iteration
    }
    
    process {
        # Run at least once and for each instance from the pipeline
    }
    
    end {
        # Run once after all iteration
    }
}

#region Alias Listings
$aliases = @{ "Verb-Function1"=@("Alias1","AliasOne") }
$aliases += @{ "Verb-Function2"=@() }
$aliases += @{ "Verb-Function3"=@("Alias3","AliasThree") }
 
#region Publish Members
foreach ($func in $aliases.Keys) {
    If ($aliases[$func].length -gt 0) {
        foreach ($alias in ($aliases[$func])) {
            # If (-not (Get-Command alias)) { New-Alias -Name alias -Value func -PassThru }
            New-Alias -Name $alias -Value $func -PassThru 
        }
        Export-ModuleMember -function $func -alias ($aliases[$func]) 
    } else {
        Export-ModuleMember -function $func
    }
}
#endregion
#endregion

#>