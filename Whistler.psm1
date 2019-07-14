Set-Variable -Name "DefaultCharSet" `
    -Value "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23465789#%&'()*+,-./[\]^_{}~" `
    -Option ReadOnly `
    -Visibility Private 

Function Convert-SecretToPassword() {
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

Function Convert-TooManySecureStringToKeyedSecureString() {
    param([SecureString]$SecureString,
        [SecureString]$Key)
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
param([parameter(ValueFromPipeline=$true,Mandatory=$true)][string]$Name,
    [securestring]$Key,
    [switch]$AsPlainText)

    $Secret = Get-TooManySecret -Name $Name | Select-Object -First 1
    $Secret | Convert-SecretToPassword -AsPlainText:$AsPlainText -Key $Key 
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
param([parameter(Mandatory=$true)][string]$Name,
        [parameter(ParameterSetName="PlainText",Mandatory=$true)][string]$Value,
        [parameter(ParameterSetName="SecureString",Mandatory=$true)][SecureString]$SecureValue,
        [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault),
        [SecureString]$Key,
        [switch]$AsPlainText,
        [switch]$DisablePrevious
        )
    
    If ($DisablePrevious) {
        $OldSecret = Get-TooManySecret -Name $Name
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
            Set-AzKeyVaultSecret -VaultName $KeyVault.VaultName -SecretValue  $SecureValue -Name $Name -NotBefore (Get-Date) | Convert-SecretToPassword -AsPlainText:$AsPlainText
        }
    }    
}

Function New-TooManyPassword() {
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)][string]$Name,
        [switch]$ReturnPlainText,
        [switch]$DisablePrevious)

    Set-TooManyPassword -Name $Name -SecureValue (Get-RandomPassword) -DisablePrevious:$DisablePrevious -AsPlainText:$ReturnPlainText
}

Function Get-TooManySecret() {
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)][string]$Name,
        [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault)
    )
Begin {
    $Secrets = $KeyVault | Get-AzKeyVaultSecret
}

Process {
    ForEach ($Secret in ($Secrets | Where-Object { $_.Name -match $name })) {
        $DetailedSecret = $KeyVault | Get-AzKeyVaultSecret -Name $Secret.Name
        $DetailedSecret
    }
}

}

Function Set-TooManySecret() {

}

Function Update-TooManySecret() {
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)][PSKeyVaultSecret]$Secret,
        [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault))

Process {
    $Secret | Update-AzKeyVaultSecret
}

}

Function New-TooManySecret() {

}

Function Get-TooManySecretProperty() {

}

Function Set-TooManySecretyProperty() {

}

Function Get-RandomPassword() {
    param([char[]]$CharSet=$DefaultCharSet,
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
        $Length = Get-Random -Minimum $MinLength -Maximum $MaxLength+1
        $LastChar = ""
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
    [CmdletBinding(DefaultParameterSetname="BySecureString")]
    Param(
        [parameter(ParameterSetName="ByBytes",Mandatory=$true)][byte[]]$ByteKey,
        [parameter(ParameterSetName="ByString",Mandatory=$true)][string]$StringKey,
        [parameter(ParameterSetName="ByInput",Mandatory=$true)][charp[]]$CharKey,
        [parameter(ParameterSetName="BySecureString",Mandatory=$true)][securestring]$SecureKey
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
                Write-Error ("Key length invalid. Must in one of these lengths: {0}-bits" -f (($ValidKeyLengths | ForEach-Object{ $_ * 8 }) -join "-bits, "))
            }
        }
        "ByInput" {
            Convert-TooManyKey -StringKey ($CharKey -join "")
        }
        Default {}
    }
    Return $SecureKey
}


#region Alias Listings
$aliases = @{ "Get-TooManyPassword"=@("Get-Password","gpwd") }
$aliases += @{ "Set-TooManyPassword"=@("Set-Password","spwd") }
$aliases += @{ "New-TooManyPassword"=@("New-Password","newpwd") }
$aliases += @{ "Get-TooManySecret"=@("Get-Secret") }
$aliases += @{ "Set-TooManySecret"=@("Set-Secret") }
$aliases += @{ "Update-TooManySecret"=@("Update-Secret") }
$aliases += @{ "Convert-TooManyKey"=@("Convert-Key") }

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
