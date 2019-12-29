##region Variables
Set-Variable -Name "DefaultSMFXSubID" `
-Value "" `
-Option AllScope
 
Set-Variable -Name "DefaultSMFXTenantID" `
-Value "" `
-Option AllScope

Set-Variable -Name "TMSKeyVault" `
    -Value $null `
    -Option AllScope

Set-Variable -Name "TMSStorage" `
    -Value $null `
    -Option AllScope

Set-Variable -Name "TMSTable" `
    -Value $null `
    -Scope Global -Visibility Public

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
    param([string]$Name,
        [switch]$Refresh)

    if (-not $Refresh -and (($TMSKeyVault -and (-not $name -or ($TMSKeyVault.Name -eq $name))))) {
        $TMSKeyVault
    } else {
        If (Test-TooManyAzure) {
            If ($TMSKeyVault -and (($TMSKeyVault.VaultName -eq $Name) -xor (-not $Name))) {
                Write-Debug "Using existing vault [$($TMSKeyVault.VaultName)]..."
                $KeyVault = $TMSKeyVault
            } elseif (-not $Name -and (Test-TooManySetting -Name "KeyVault")) {
                $Name = Get-TooManySetting -Name "KeyVault"
                $KeyVault = Get-AzKeyVault -VaultName $Name
            }

            If (-not $KeyVault) {
                $KeyVault = Get-AzKeyVault | Where-Object { $_.VaultName -match $Name } | Select-Object -First 1
                Set-TooManySetting -Name "KeyVault" -Value $KeyVault.VaultName
                Write-Debug "Got new vault [$($KeyVault.VaultName)]..."
            }

            If (-not $TMSKeyVault) {
                $TMSKeyVault = $KeyVault
            }

            $KeyVault
        }
    
    }
}
    
Function Select-TooManyKeyVault() {
    <#
    .SYNOPSIS
    Sets the default key vault to be used by the module.
    .DESCRIPTION
    Find the first key vault in the current subscription with the give name.
    .PARAMETER Name
    Name given to the Key Vault
    .EXAMPLE
    PS> $MyVaut = Select-TooManyKeyVault -Name "MyVault"
    .LINK
    Get-AzKeyVault
    #>
    [Alias('Select-KeyVault')]
    param([parameter(ParameterSetName="ByString",Mandatory=$true,Position=1)][string]$Name,
        [parameter(ParameterSetName="ByObject",Mandatory=$true,Position=1)][ Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultIdentityItem]$KeyVault
        )
        If ($KeyVault) {
            $TMSKeyVault = $KeyVault
        } elseif (Test-TooManyAzure) {
            If ($TMSKeyVault -and (($TMSKeyVault.VaultName -eq $Name) -xor (-not $Name))) {
                Write-Debug "Using existing vault [$($TMSKeyVault.VaultName)]..."
            } else {
                $KeyVault = Get-AzKeyVault | Where-Object { $_.VaultName -match $Name } | Select-Object -First 1
                $TMSKeyVault = $KeyVault
                Write-Debug "Got new vault [$($TMSKeyVault.VaultName)]..."
            }

        }
    
        Set-TooManySetting -Name "KeyVault" -Value $TMSKeyVault.VaultName
        Return $TMSKeyVault
    }

Function Select-TooManyTable() {
    <#
    .SYNOPSIS
    Sets the default table to be used by the module.
    .DESCRIPTION
    Find the first table in the current subscription with the give name.
    .PARAMETER Name
    Name given to the Table
    .EXAMPLE
    PS> $MyTable = Select-TooManyKeyVault -Name "MyVault"
    .LINK
    Get-AzKeyVault
    #>
    param([parameter(ParameterSetName="ByString",Position=1)][string]$Name,
        [parameter(ParameterSetName="ByObject",Mandatory=$true,Position=1)][Microsoft.Azure.Cosmos.Table.CloudTable]$Table,
        [Microsoft.Azure.Commands.Management.Storage.Models.PSStorageAccount]$StorageAccount
        )
        If ($Table) {
            $TMSTable = $Table
        } elseif (Test-TooManyAzure) {
            If ($TMSTable -and (($TMSTable.Name -eq $Name) -xor (-not $Name))) {
                Write-Debug "Using existing table [$($TMSTable.Name)]..."
            } else {
                If ($StorageAccount) {
                    $TMSStorage = $StorageAccount
                } elseif ($TMSStorage) {
                } elseif (Test-TooManySetting -Name "StorageAccountName") {
                    $TMSStorage = Get-AzStorageAccount -ResourceGroupName (Get-TooManySetting -Name "StorageAccountRG") `
                        -Name (Get-TooManySetting -Name "StorageAccountName")
                } else {
                    $TMSStorage = Get-AzStorageAccount | Where-Object{ $_.StorageAccountName -match "tmsmeta" }
                }
                If ($TMSStorage) {
                    Set-TooManySetting -Name "StorageAccountRG" -Value $TMSStorage.ResourceGroupName
                    Set-TooManySetting -Name "StorageAccountName" -Value $TMSStorage.StorageAccountName
                    If (-not $Name) { $Name = Get-TooManySetting -Name KeyVault }
                    write-Debug "TMSStorage: $($TMSStorage.StorageAccountName) - $($TMSStorage.Context.Gettype())"
                    write-Debug "Name: $Name - $($Name.GetType())"
                    
                    $Table = (Get-AzStorageTable -Name $Name -Context $TMSStorage.Context).CloudTable
                    If ($Table) {
                        Set-Variable -Name "TMSTable" -Value $Table -Scope Global -Visibility Private
                        Write-Debug "Using found table [$($TMSTable.Name)]" 
                    }
                }
                Write-Debug "Got new table [$($TMSTable.Name)]..."
            }

        }

        If ($TMSTable) {
            Set-TooManySetting -Name "Table" -Value $TMSTable.Name
            Return $TMSTable
        }
    
    }

Function Test-TooManyTable() {
    param()

    If ($TMSTable) {
        $true
    } elseif (Select-TooManyTable) {
        $true
    } else {
        $false
    }
}

Function Connect-TooManySecret {
<#
.SYNOPSIS
Connect to Azure and use existing context if available.
#>
    param([switch]$Force)

    $TenantID = Get-TooManySetting -Name "TenantID"
    $SubID = Get-TooManySetting -Name "SubscriptionID"
    $Context = Get-AzContext

    If ($Context.Tenant.Id -ne $TenantID -or $Context.Subscription.Id -ne $SubID) {
        $PossibleConext = Get-AzContext -ListAvailable | Where-Object { $_.Tenant.Id -eq $TenantID }
        If ($PossibleConext) {
            If (-not $Force) {
                Do {
                    $Response = Read-Host "Existing subscription [$($Context.Subscription.Id)] does not match previous [$SubID]. Switch context? [Y/n]"
                    If ($Response -eq '') { $Response = 'Y' }
                } Until ($Response -match "\A(Y(es)?)|(N(o)?)\Z")
            }
            If ($Force -or $Response -match '\A(Y(es)?)\Z') {
                $ExactContext = $PossibleConext | Where-Object { $_.Subscription.Id -eq $SubID} | Select-Object -First 1
                If ($ExactContext) { 
                    $Context = $ExactContext | Set-AzContext
                } else {
                    $PossibleConext | Select-Object -First 1 | Set-AzContext | Out-Null
                    $Context = Set-AzContext -Subscription $SubID
                }
            }
        } else {
            $Context = Connect-AzAccount -Subscription $SubID -Tenant $TenantID
        }
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
    param([switch]$DoNotConnect,
        [switch]$Prompt,
        [switch]$SwitchContext)

    $Result = $False
    $context = Get-AzContext
    If ($Context) {
        $Result = $true
    } elseif (-not $DoNotConnect) {
        $TenantID = Get-TooManySetting -Name "TenantID"
        $SubID = Get-TooManySetting -Name "SubscriptionID"
        $context = Connect-AzAccount -Tenant $TenantID -Subscription $SubID #-Tenant $DefaultTooManyTenantID -Subscription $DefaultTooManySubID
    }

    If ($Prompt -or $SwitchContext) {
        Connect-TooManySecret -Force:($SwitchContext -or -not $Prompt)
    }
    If ($context) {
        Set-TooManySetting -Name "TenantID" -Value $Context.Tenant.ToString()
        Set-TooManySetting -Name "SubscriptionID" -Value $Context.Subscription.ToString()
        $Result = $true
    }

    return $Result
}

Function Register-TooManySecret() {
    [Alias('Register-TooManySecrets')]
    param([parameter(ValueFromPipelineByPropertyName=$true)][string]$VaultName,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$TableName,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$ResourceGroupName,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$StorageAccountName,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$StorageAccountRG = $ResourceGroupName,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$AADTenantID = $DefaultTooManyTenantID,
        [parameter(ValueFromPipelineByPropertyName=$true)][string]$SubscriptionID = $DefaultTooManySubID)

    Import-TooManySetting

    If ($VaultName) { Set-TooManySetting -Name "KeyVault" -Value $VaultName }
    If ($TableName) { Set-TooManySetting -Name "TMSTable" -Value $TableName }
    If ($ResourceGroupName) { Set-TooManySetting -Name "ResourceGroupName" -Value $ResourceGroupName }
    If ($StorageAccountName) { Set-TooManySetting -Name "StorageAccountName" -Value $StorageAccountName }
    If ($StorageAccountRG) { Set-TooManySetting -Name "StorageAccountRG" -Value $StorageAccountRG }
    If ($AADTenantID) { Set-TooManySetting -Name "TenantID" -Value $AADTenantID }
    If ($SubscriptionID) { Set-TooManySetting -Name "SubscriptionID" -Value $SubscriptionID }

}
