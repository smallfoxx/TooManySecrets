#region Variables
Set-Variable -Name "DefaultTooManySubID" `
    -Value "994659af-22e1-4a1f-b459-06a16b637a68" `
    -Option AllScope

Set-Variable -Name "DefaultTooManyTenantID" `
    -Value "ff96a852-896e-4ca3-ba21-b02cc3996b37" `
    -Option AllScope

#endregion

Function Test-TooManyKeyVault() {
    param([string]$Name)

    If (Get-TooManyKeyVault -Name $Name) {
        return $true
    } else {
        return $false
    }
}

Function New-TooManyKeyVault() {

}

Function Get-TooManyKeyVault() {
param([string]$Name)
#TODO: change code to look for global or module variable 
#TODO: set get-azkeyvault to be more specific, at least by default
    If (Test-TooManyAzure) {
        $KeyVault = Get-AzKeyVault | Where-Object { $_.name -match $Name } | Select-Object -First 1
        return $KeyVault
    }

}

Function Test-TooManyAzure() {
    param([switch]$DoNotConnect)

    $Result = $False
    $context = Get-AzContext
    If ($Context) {
        $Result = $true
    } elseif (-not $DoNotConnect) {
        $context = Connect-AzAccount -Tenant $DefaultTooManyTenantID -Subscription $DefaultTooManySubID
        If ($context) { $Result = $true}
    }

    return $Result
}

#region Alias Listings
$aliases = @{ "Test-TooManyKeyVault"=@() }
$aliases += @{ "New-TooManyKeyVault"=@() }
$aliases += @{ "Get-TooManyKeyVault"=@() }

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
