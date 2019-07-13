Set-Variable -Name "DefaultCharSet" `
    -Value "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23465789#%&'()*+,-./[\]^_{}~" `
    -Option ReadOnly `
    -Visibility Private 

Function Convert-SecretToPassword() {
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)]$Secret,
        [switch]$AsPlainText)

    If ($Secret) {
        If ($AsPlainText) {
            return $Secret.SecretValueText
        } else {
            return $Secret.SecretValue
        }
    }
}
Function Get-TooManyPassword() {
<#
.SYNOPSIS
Get a password out of an Azure Key Vault
.DESCRIPTION
Given the name of a secret, look for the first Secret & version in the Key Vault, and return its Value
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
    [switch]$AsPlainText)

    $Secret = Get-TooManySecret -Name $Name | Select-Object -First 1
    $Secret | Convert-SecretToPassword -AsPlainText:$AsPlainText 
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
.PARAMETER AsPlainText
If flagged, will return the clear text value of the Secret instead of the SecureString version
.PARAMETER DisablePrevic
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
            Set-TooManyPassword -Name $Name -SecureValue $Secure
         }
        Default { 
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


#region Alias Listings
$aliases = @{ "Get-TooManyPassword"=@("Get-Password","gpwd") }
$aliases += @{ "Set-TooManyPassword"=@("Set-Password","spwd") }
$aliases += @{ "New-TooManyPassword"=@("New-Password","newpwd") }
$aliases += @{ "Get-TooManySecret"=@("Get-Secret") }
$aliases += @{ "Set-TooManySecret"=@("Set-Secret") }
$aliases += @{ "Update-TooManySecret"=@("UPdate-Secret") }

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
