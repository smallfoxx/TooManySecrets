$ClassModule = "Bishop.psm1"
if (Test-Path "$PSScriptRoot\$ClassModule") {
    #this is to get the class definitions shared between modules
    $script = [ScriptBlock]::Create("using module '$PSScriptRoot\$ClassModule'")
    . $script
}

$ModuleSettings = New-Object TMSModuleSettings

Function Convert-SecretToPassword() {
    <#
    .SYNOPSIS
    Given a Secret object, return just the secret's value. 
    #>
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)]$Secret,
        [securestring]$Key,
        [switch]$AsPlainText)

    Write-Debug "Attempting to convert secret's value to a password"
    If ($Secret) {
        If ($Key) {
            $SecureSecret = ConvertTo-SecureString -String $Secret.SecretValueText -SecureKey $Key
        } else {
            $SecureSecret = $Secret.SecretValue
        }
        If ($AsPlainText) {
            return ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                    $SecureSecret
                )
            ))
        } else {
            return $SecureSecret
        }
    }
}

Function Get-TooManyPassword() {
<#
.SYNOPSIS
Get a password out of an Azure Key Vault
.DESCRIPTION
Given the name of a secret, look for the first Secret & version in the Key Vault, and return its Value
.PARAMETER Name
Name of the secret value in tye key vault
.PARAMETER Key
Key used to encrypt password stored in the vault if stored cryptically
.PARAMETER AsPlainText
If flagged, will return the clear text value of the Secret instead of the SecureString version
.EXAMPLE
PS> Get-TooManyPassword -Name "MyPWD"
Returns the value of the Secret MyPWD in the current Key Vault as a SecureString
.LINK
Get-TooManySecret
Get-AzKeyVaultSecret
#> 
[CmdletBinding()]
[Alias("Get-Password","gpwd")]
param(
    [securestring]$Key,
    [switch]$AsPlainText)
    DynamicParam {
        $RuntimeParamDic  = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $StandardProps = @('Mandatory','ValueFromPipeline','ValueFromPipelineByPropertyName','ParameterSetName','Position')
        $Attrib = [ordered]@{
            'Name' = @{
                'AttribType' = [string]
                'Mandatory' = $true
                'ValueFromPipeline' = $true
                'ValueFromPipelineByPropertyName' = $true
                'ParameterSetName' = '__AllParameterSets'
                'Position' = 1
                'ValidSet' = (Get-TooManySecretList -UseVault)
            }
        }
        
        ForEach ($AttribName in $Attrib.Keys) {
            #[string]$AttribName = $Key.ToString()
            $ThisAttrib = New-Object System.Management.Automation.ParameterAttribute
            ForEach ($Prop in $StandardProps) {
                If ($null -ne $Attrib.$AttribName.$Prop) {
                    $ThisAttrib.$Prop = $Attrib.$AttribName.$Prop
                }
            }
            $ThisCollection = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
            $ThisCollection.Add($ThisAttrib)

            If ($Attrib.$AttribName.ValidSet) {
                $ThisValidation = New-Object  System.Management.Automation.ValidateSetAttribute($Attrib.$AttribName.ValidSet)
                $ThisCollection.Add($ThisValidation)
            }

            $ThisRuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter($AttribName,  $Attrib.$AttribName.AttribType, $ThisCollection)
            $RuntimeParamDic.Add($AttribName,  $ThisRuntimeParam)
        }

        return  $RuntimeParamDic
      
    }

Process {
    $Name = $PSBoundParameters.Name
    $Secret = Get-TooManySecret -Name $Name -ExcludeMetadata | Select-Object -First 1
    $Secret | Convert-SecretToPassword -AsPlainText:$AsPlainText -Key $Key 
}

}

Function Set-TooManyPassword() {
<#
.SYNOPSIS
Set the password to a new value
.DESCRIPTION
Using either a SecureString or plain text, add a new version to a Secret in an Azure Key Vault. If a secret does
not exist with this name, a new one is created.  A SecureString or clear String value will be returned.  The
type returned is determined by the AsPlainText switch; if selected, a clear String is returned; otherwise, a
SecureString object is returned
.PARAMETER Name
TODO:  More about parameter needed
.PARAMETER Value
TODO:  More about parameter needed
.PARAMETER SecureValue
TODO:  More about parameter needed
.PARAMETER KeyVault
TODO:  More about parameter needed
.PARAMETER Key
A 128-bit, 192-bit, or 256-bit key used to encrypted the value within the key vault.  Must be in SecureString format.
.PARAMETER AsPlainText
If flagged, will return the clear text value of the Secret instead of the SecureString version
.PARAMETER DisablePrevious
TODO:  More about parameter needed
.EXAMPLE
PS> Set-TooManyPassword -Name "MyPWD" -Value "MyNewPWD"
Adds a new version to the MyPWD secret as MyNewPWD and returns that MyNewPWD in a SecureString object
.OUTPUTS
SecureString
String
.LINK
Get-TooManySecret
Get-AzKeyVaultSecret
#> 
[CmdletBinding(DefaultParameterSetname="PlainText")]
[Alias("Set-Password","spwd")]
param([parameter(Mandatory=$true)][ValidatePattern("^[0-9a-zA-Z-]+$")][string]$Name,
        [parameter(ParameterSetName="PlainText",Mandatory=$true)][string]$Value,
        [parameter(ParameterSetName="SecureString",Mandatory=$true)][SecureString]$SecureValue,
        [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault),
        [SecureString]$Key,
        [switch]$AsPlainText,
        [switch]$DisablePrevious
        )
    
    If ($DisablePrevious) {
        $OldSecret = Get-TooManySecret -Name $Name -ExcludeMetadata
        if ($OldSecret) {
            $OldSecret | Update-AzKeyVaultSecret -Enable:$false
        }
    }

    switch ($PSCmdlet.ParameterSetName) {
        "PlainText" { 
            $Secure = ConvertTo-SecureString -String $Value -AsPlainText -Force
            Set-TooManyPassword -Name $Name -SecureValue $Secure -AsPlainText:$AsPlainText -DisablePrevious:$DisablePrevious -KeyVault $KeyVault -Key $Key
         }
        Default {
            If ($Key) {
                #If a seed key for value is supplied, convert the secure string to an encrypted value using the string
                $Encrypted = ConvertFrom-SecureString -SecureString $SecureValue -SecureKey $key
                #Then convert that encrypted value back to a SecureString for storage in the vault
                $SecureEncrypted = ConvertTo-SecureString -String $Encrypted -AsPlainText -Force
                $SecureValue = $SecureEncrypted
            }
            $Secret = Set-AzKeyVaultSecret -VaultName $KeyVault.VaultName -SecretValue  $SecureValue -Name $Name -NotBefore (Get-Date)
            If ($script:TMSSecretList -and $script:TMSSecretList.Names -notcontains $Name) {
                $script:TMSSecretList.Names += $Name
            }
            $Secret | Convert-SecretToPassword -AsPlainText:$AsPlainText
        }
    }    
}

Function New-TooManyPassword() {
    [Alias("New-Password","newpwd")]
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)][ValidatePattern("^[0-9a-zA-Z-]+$")][string]$Name,
        [switch]$ReturnPlainText,
        [switch]$DisablePrevious)

    Set-TooManyPassword -Name $Name -SecureValue (Get-RandomPassword) -DisablePrevious:$DisablePrevious -AsPlainText:$ReturnPlainText

}


Function Get-TooManySecret() {
    [CmdletBinding(DefaultParameterSetName="Filtered")]
    [Alias("Get-Secret")]
    param(
        [parameter(Position=2)]
          [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault), 
        [parameter(Position=1,ParameterSetName="Filtered",ValueFromPipelineByPropertyName=$True)]
          [string]$Filter='*',
        [parameter(Position=3,ParameterSetName="Named",ValueFromPipelineByPropertyName=$True)][string]$Version,
        [parameter(ParameterSetName="Filtered")][switch]$RegEx,
        [parameter(ParameterSetName="Filtered")][switch]$Like=(-not $RegEx),
        [switch]$ExcludeMetadata,
        [switch]$IncludeVersions,
        [switch]$ReturnVaultSecret
    )
    DynamicParam {
        $RuntimeParamDic  = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $StandardProps = @('Mandatory','ValueFromPipeline','ValueFromPipelineByPropertyName','ParameterSetName','Position')
        $Attrib = [ordered]@{
            'Name' = @{
                'AttribType' = [string]
                'Mandatory' = $true
                'ValueFromPipeline' = $true
                'ValueFromPipelineByPropertyName' = $true
                'ParameterSetName' = 'Named'
                'Position' = 1
                'ValidSet' = (Get-TooManySecretList -UseVault)
            }
        }
        
        ForEach ($AttribName in $Attrib.Keys) {
            #[string]$AttribName = $Key.ToString()
            $ThisAttrib = New-Object System.Management.Automation.ParameterAttribute
            ForEach ($Prop in $StandardProps) {
                If ($null -ne $Attrib.$AttribName.$Prop) {
                    $ThisAttrib.$Prop = $Attrib.$AttribName.$Prop
                }
            }
            $ThisCollection = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
            $ThisCollection.Add($ThisAttrib)

            If ($Attrib.$AttribName.ValidSet) {
                $ThisValidation = New-Object  System.Management.Automation.ValidateSetAttribute($Attrib.$AttribName.ValidSet)
                $ThisCollection.Add($ThisValidation)
            }

            $ThisRuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter($AttribName,  $Attrib.$AttribName.AttribType, $ThisCollection)
            $RuntimeParamDic.Add($AttribName,  $ThisRuntimeParam)
        }

        return  $RuntimeParamDic
      
    }
        
Begin {

    If ($PSCmdlet.ParameterSetName -eq 'Filtered') {
        #write-output (Get-AzContext)
        #Write-output (Get-TooManyKeyVault)
        $Secrets = $KeyVault | Get-AzKeyVaultSecret
    }
}

Process {
    switch ($PSCmdlet.ParameterSetName) {

        'Filtered' {
            If ($RegEx) {
                $FilteredSecrets = $Secrets | Where-Object { $_.Name -match $Filter }
            } else {
                $FilteredSecrets = $Secrets | Where-Object { $_.Name -like $Filter }
            }
            ForEach ($Secret in $FilteredSecrets) {
                $IndividualSecret = $KeyVault | Get-AzKeyVaultSecret -Name $Secret.Name -IncludeVersions:$IncludeVersions
                if ($ReturnVaultSecret) {
                    $IndividualSecret
                } elseIf ($ExcludeMetadata) {
                    New-Object TMSSecret($IndividualSecret)
                } elseif ($IncludeVersions) {
                    (New-Object TMSSecret($IndividualSecret)) | Add-TooManyMeta -Force
                } else  {
                    #Add-TooManyMeta -Secret $IndividualSecret -Force
                    (New-Object TMSSecret($IndividualSecret)) | Add-TooManyMeta -Force
                }
            }
        } 
        Default {
            $Name = $PSBoundParameters.Name

            If ($Version -eq "") {
                $Secret = $KeyVault | Get-AzKeyVaultSecret -Name $Name -IncludeVersions:$IncludeVersions
            } else {
                $Secret = $KeyVault | Get-AzKeyVaultSecret -Name $Name -Version $Version
            }

            If ($ReturnVaultSecret) {
                $Secret
            } elseIf ($ExcludeMetadata) {
                New-Object TMSSecret($Secret)
            } elseif ($Secret) {
                if ($IncludeVersions) {
                    (New-Object TMSSecret($Secret)) | Add-TooManyMeta -Force
                } else {
                    (New-Object TMSSecret($Secret)) | Add-TooManyMeta -Force
                }
            }
        }
    }
}
End {

}
}

Function Test-TooManySecret {
    Param(
        [parameter(Mandatory=$true)]
        [string]$Name
    )

    ((Get-TooManySecretList) -contains $name)
}
Function Set-TooManySecret() {
    [CmdletBinding(DefaultParameterSetName="Name")]
    [Alias('Set-Secret')]
    param(
        [parameter(ParameterSetName="ByObject",ValueFromPipeline=$true,Mandatory=$true,Position=1)][PSObject]$Secret,
        [parameter(ParameterSetName="ByName",Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=1)][ValidatePattern("^[0-9a-zA-Z-]+$")][string]$Name,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$URL,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$Username,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$Server,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$Domain,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$FQDN,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$UPN,
        [parameter(ValueFromPipelineByPropertyName=$true)]
            [Alias('Password')]
            [SecureString]$SecureValue,
        [parameter(ValueFromPipelineByPropertyName=$true)][switch]$DisablePrevious,
        [parameter(ValueFromPipelineByPropertyName=$true)][switch]$PassThru,
        [parameter(ValueFromPipelineByPropertyName=$true)][switch]$ImportTags,
        [parameter(ValueFromPipelineByPropertyName=$true)][switch]$Force,
        [parameter(ValueFromPipelineByPropertyName=$true)][hashtable]$Property=@{}
    )
Process {
    $SetProperties = @{}
    ForEach ($Prop in $Property.Keys) { $SetProperties.$Prop = $Property.$Prop}

    ForEach ($ParamName in $PSCmdlet.MyInvocation.BoundParameters.Keys) {
        $SetProperties.$ParamName = $PSCmdlet.MyInvocation.BoundParameters.$ParamName
    }

    If ($Secret) {
        $Name = $Secret.Name
        $SetProperties.SecretID = $Secret.Id
        $MetaResult = Set-TooManyMeta -InputObject $Secret -Property $SetProperties -ImportTags:$ImportTags
    } else {
        If (Test-TooManySecret -Name $name) {
            $Secret = Get-TooManySecret -Name $Name
        } elseif ($Force) {
            $Secret = New-TooManySecret -Name $name -SecureValue $SecureValue -PassThru
        } else {
            Write-Warning "Secret [$Name] does not exists. Use -Force to force creation of a new secret."
        }

        If ($Secret) {
            $SetProperties.SecretID = $Secret.Id
            $MetaResult = Set-TooManyMeta -Name $Name -Property $SetProperties
        }
    }

    If ($Secret) {
        If ($SecureValue) {
            Set-TooManyPassword -SecureValue $SecureValue -Name $Name -DisablePrevious:$DisablePrevious | Out-Null
        }

        $SecretUpdate = $Secret | Update-TooManySecret

        If ($PassThru) {
            Get-TooManySecret -Name $Name
        }
    }
}

}

Function ConvertFrom-TMSToAzure {
    Param([parameter(ValueFromPipeline=$true,Mandatory=$true)][TMSSecret]$Secret)

    If ($Secret.id -match "\Ahttp(s)?://(?<vaultName>[^\.\/]+)\.vault\.(?<domain>[^:/]+)(:443)?/secrets/(?<name>[^/]+)(/(?<version>[^/]*))?\Z") {
        Get-AzKeyVaultSecret -VaultName $matches.vaultName -Name $matches.name -Version $matches.version
    }
}

Function Update-TooManySecret() {
    [CmdletBinding(DefaultParameterSetName="AzSecret")]
    [Alias("Update-Secret")]
    param([parameter(ValueFromPipeline=$true,ParameterSetName='AzSecret',Mandatory=$true)][PSObject]$Secret
    )

Process {
    switch ($Secret.GetType().Name) {
        'TMSSecret' {
            $AzSecret = $Secret | ConvertFrom-TMSToAzure 
            $AzSecret.SecretValue = $Secret.SecretValue
            $AzSecret | Update-AzKeyVaultSecret  }
        'PSKeyVaultSecret' { $Secret | Update-AzKeyVaultSecret}
        default     { }
    }
}

}

Function Update-TooManySecretList {
    [CmdletBinding(DefaultParameterSetName='ViaMeta')]
    [Alias('Update-SecretList')]
    param(
        [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault),
        [parameter(ParameterSetName="ViaMeta")][switch]$IncludeMetadata,
        [parameter(ParameterSetName="ViaKeyVault",Mandatory=$true)][switch]$UseVault
    )
Process {
    If (-not $script:TMSSecretList) {
        Write-Debug "Creating list of secrets"
        $script:TMSSecretList = [PSCustomObject]@{
            Names = @()
            Meta = @()
            LastUpdateTime = (Get-Date)
        }
        $script:TMSSecretList | Add-Member ScriptProperty Age { ((Get-Date) - $this.LastUpdateTime).TotalSeconds }
    }
    switch ($PSCmdlet.ParameterSetName) {
        'ViaKeyVault' {
            If ($UseVault) {
                $script:TMSSecretList.Names = $KeyVault | Get-AzKeyVaultSecret | ForEach-Object { $_.Name }
                $script:TMSSecretList.Meta = @()
                $script:TMSSecretList.LastUpdateTime = (Get-Date)
            }
        }
        Default {
            $script:TMSSecretList.Meta = Get-TooManyMetaList -IncludeMetadata:$IncludeMetadata
            $script:TMSSecretList.Names = $script:TMSSecretList.Meta | ForEach-Object { $_.Name }
            $script:TMSSecretList.LastUpdateTime = (Get-Date)
        }
    }
}
}
Function Get-TooManySecretList() {
    [CmdletBinding(DefaultParameterSetName='ViaMeta')]
    [Alias("Get-SecretList")]
    param(
        [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault),
        [parameter(ParameterSetName="ViaMeta")][switch]$IncludeMetadata,
        [parameter(ParameterSetName="ViaKeyVault",Mandatory=$true)][switch]$UseVault,
        [int]$MaxAge = 3600
    )

Process {
    If (-not $Script:TMSSecretList -or ($Script:TMSSecretList.Age -ge $MaxAge)) {
        switch ($PSCmdlet.ParameterSetName) {
            'ViaKeyVault' { Update-TooManySecretList -KeyVault $KeyVault -UseVault:$UseVault }
            Default { Update-TooManySecretList -KeyVault $KeyVault -IncludeMetadata:$IncludeMetadata }
        }
    }
    If ($IncludeMetadata) {
        $Script:TMSSecretList.Meta
    } else {
        $Script:TMSSecretList.Names
    }
}

}

Function New-TooManySecret() {
    [CmdletBinding()]
    [Alias("New-Secret")]
    param(
        [parameter(Mandatory=$true)]
        [ValidatePattern("^[0-9a-zA-Z-]+$")]
        [string]$Name,
        [SecureString]$SecureValue,
        [SecureString]$Key,
        [switch]$PassThru
    )
Process {

    If (Test-TooManySecret -Name $Name) {
        Write-Warning "Secret named [$Name] already exists."
    } else {
        If ($SecureValue) {
            Set-TooManyPassword -Name $Name -SecureValue $SecureValue -Key $Key | Out-Null
        } else {
            New-TooManyPassword -Name $Name | Out-Null
        }
        If ($PassThru) { Get-TooManySecret -Name $Name }
    }
}
}

Function Get-TooManySecretProperty() {

}

Function Set-TooManySecretyProperty() {

}

Function Get-RandomPassword() {
    param([char[]]$CharSet=$ModuleSettings.DefaultCharSet,
        [int]$MinLength=15,
        [int]$MaxLength=30,
        [switch]$AsPlainText,
        [switch]$AllANSI,
        [switch]$NoConsecutive)

    Write-Debug "Charset: $charset"
    If ($AllANSI) {
        $CharSet += 33..126 | ForEach-Object{ [char]$_ }
        $CharSet = $CharSet | Select-Object -Unique
    }

    If ($AsPlainText) {
        [int]$Length = Get-Random -Minimum $MinLength -Maximum ($MaxLength+1)
        $LastChar = ""
        Write-Debug "Length [$length]"
        ( 1..$Length | ForEach-Object {
            do { 
                $ThisChar = Get-Random -InputObject $charSet -Count 1
            } until ((-not $NoConsecutive) -or ($thisChar -cne $lastChar))
            If ($NoConsecutive) { $lastChar = $thisChar }
            $thisChar
        } ) -join ""
        #(Get-Random -InputObject $charSet -Count (Get-Random -Minimum $MinLength -Maximum $MaxLength)) -join ""
    } else {
        ConvertTo-SecureString -String ((Get-Random -InputObject $charSet -Count (Get-Random -Minimum $MinLength -Maximum $MaxLength)) -join "") -AsPlainText -Force
    }

}

Function Convert-TooManyKey() {
<#
.SYNOPSIS
Convert a key to a secure string for encrypting values.
.DESCRIPTION
Changes a 128-bit, 192-bit, or 256-bit key into a secure string to be used for encrypting secret values in
the key vault.  By default, all Secrets are stored securely with limited access in Azure. However, for those
people that require an added level to not be easily viewed in Azure, the secret can be stored with an Encrpted
value within the Secret in Azure
.PARAMETER StringKey
An string of either 16, 24, or 32 ASCII characters long
.PARAMETER ByteKey
An array of bytes either 16, 24, or 32 in length
.PARAMETER CharKey
An array of ASCII characters either 16, 24, or 32 in length
.PARAMETER SecureKey
A SecureString holding a string of 16, 24, or 32 ASCII characters long 
.EXAMPLE
PS> Convert-TooManyKey -StringKey "h|nD#iCDp8\}(Jqw"
Converts the given string to a secure string to be used for a key
.EXAMPLE
PS> Convert-TooManyKey -ByteKey @(104, 124, 110, 68, 35, 105, 67, 68, 112, 56, 92, 125, 40, 74, 113, 119)
Converts the given byte array to a secure string to be used for a key
.OUTPUTS
SecureString
String
.LINK
Get-TooManyPassword
Set-TooManyPassword
#> 
    [CmdletBinding(DefaultParameterSetname="BySecureString")]
    [Alias('Convert-Key')]
    Param(
        [parameter(ParameterSetName="ByString",Mandatory=$true,Position=1)][string]$StringKey,
        [parameter(ParameterSetName="ByBytes",Mandatory=$true,Position=1)][byte[]]$ByteKey,
        [parameter(ParameterSetName="ByChars",Mandatory=$true,Position=1)][char[]]$CharKey,
        [parameter(ParameterSetName="BySecureString",Mandatory=$true,Position=1)][securestring]$SecureKey
    )
    $ValidKeyLengths = @(16,24,32)

    Switch ($PSCmdlet.ParameterSetName) {
        "ByBytes" {
            Convert-TooManyKey -StringKey ([char[]]$ByteKey -join "")
        }
        "ByString" {
            If ($ValidKeyLengths -contains $StringKey.Length) {
                $SecureKey = ConvertTo-SecureString -String $StringKey -AsPlainText -Force
            } else {
                Write-Error ("Key length invalid. Must be in one of these lengths: {0}-bits" -f (($ValidKeyLengths | ForEach-Object{ $_ * 8 }) -join "-bits, "))
            }
        }
        "ByChars" {
            Convert-TooManyKey -StringKey ($CharKey -join "")
        }
        Default {}
    }
    Return $SecureKey
}
