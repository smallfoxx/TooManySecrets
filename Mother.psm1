##region Variables
Set-Variable -Name "DefaultSMFXSubID" `
-Value "" `
-Option AllScope

Set-Variable -Name "DefaultSMFXTenantID" `
-Value "" `
-Option AllScope

#endregion

<# TODO:
    * serch all keyvaults
#>

Function Test-TooManyKeyVault() {
<#
.SYNOPSIS
Verify if a key vault by name exists
.DESCRIPTION
Given the name of a Key Vault, returns a binary response ($true/$false) as to whether it exists
.PARAMETER Name
The name of a Key Vault resource in the current Azure subscription.
.EXAMPLE
PS> Test-TooManyKeyVault -Name "MyVault"

Returns true if there is at least one Key Vault named MyVault in the current subscription, or false if none were found.
.LINK
Get-TooManyKeyVault
Get-AzKeyVault
#>
    param([string]$Name)

    If (Get-TooManyKeyVault -Name $Name) {
        return $true
    } else {
        return $false
    }
}

Function New-TooManyKeyVault() {
<#
.SYNOPSIS
Create a new key vault
.DESCRIPTION
NOT CURRENT IMPLEMENTED!!!! Makes calls to Azure Resource Manager to create a new key vault in the current Azure subscription
.PARAMETER Name
Name to give this Key Vault
#>
}

Function Get-TooManyKeyVault() {
<#
.SYNOPSIS
Retrieve an Azure Key Vault
.DESCRIPTION
Find the first key vault in the current subscription with the give name.
.PARAMETER Name
Name given to the Key Vault
.EXAMPLE
PS> $MyVaut = Get-TooManyKeyVault -Name "MyVault"
#>
param([string]$Name)
#TODO: change code to look for global or module variable 
#TODO: set get-azkeyvault to be more specific, at least by default
    If (Test-TooManyAzure) {
        $KeyVault = Get-AzKeyVault | Where-Object { $_.name -match $Name } | Select-Object -First 1
        return $KeyVault
    }

}

Function Test-TooManyAzure() {
<#
.SYNOPSIS
Return if connected to Azure
.DESCRIPTION
Looks to see if there is a current conext with Azure.  If not, attempt to connect using DefaultTooManyTenantID & DefaultTooManySubID, and prompt for authentication.
.PARAMETER DoNotConnect
If flagged, cmdlet will NOT attempt to login if no current context
.EXAMPLE
PS> If (Test-TooManyAzure) {
    Write-Host "connected!"
} else {
    Write-Host "No Connection to Azure"
}
.LINK
Connect-AzConnect
#> 
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
