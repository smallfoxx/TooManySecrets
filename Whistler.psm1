Set-Variable -Name "DefaultCharSet" `
    -Value "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23465789#%&'()*+,-./[\]^_{}~" `
    -Option ReadOnly `
    -Visibility Private 

Function Get-TooManyPassword() {
param([parameter(ValueFromPipeline=$true,Mandatory=$true)][string]$Name,
    [switch]$AsPlainText)

    $Secret = Get-TooManySecret -Name $Name | Select-Object -First 1
    If ($Secret) {
        If ($AsPlainText) {
            return $Secret.SecretValueText
        } else {
            return $Secret.SecretValue
        }
    }
}

Function Set-TooManyPassword() {
    param([parameter(Mandatory=$true)][string]$Name,
        [parameter(ParameterSetName="PlainText",Mandatory=$true)][string]$Value,
        [parameter(ParameterSetName="SecureString",Mandatory=$true)][SecureString]$SecretValue,
        [PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault),
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
            Set-TooManyPassword -Name $Name -SecureString $Secure
         }
        Default { 
            Set-AzKeyVaultSecret -VaultName $KeyVault.VaultName -SecretValue $SecretValue -Name $Name -NotBefore (Get-Date)
        }
    }    
}

Function New-TooManyPassword() {
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)][string]$Name,
        [switch]$DisablePrevious)

    Set-TooManyPassword -Name $Name -SecretValue (Get-RandomPassword) -DisablePrevious:$DisablePrevious
}

Function Get-TooManySecret() {
    param([parameter(ValueFromPipeline=$true,Mandatory=$true)][string]$Name,
        [PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault)
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
        [PSKeyVaultIdentityItem]$KeyVault = (Get-TooManyKeyVault))

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

        write-host "CHarset: $charset"
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
