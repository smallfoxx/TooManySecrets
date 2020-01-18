$ClassModule = "Bishop.psm1"
if (Test-Path "$PSScriptRoot\$ClassModule") {
    #this is to get the class definitions shared between modules
    $script = [ScriptBlock]::Create("using module '$PSScriptRoot\$ClassModule'")
    . $script
}

$ModuleSettings = New-Object TMSModuleSettings

<# TODO:
    * search all keyvaults
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
        [switch]$Refresh,
        [switch]$Force)

    if (-not $Refresh -and (($ModuleSettings.KeyVault -and (-not $name -or ($ModuleSettings.KeyVault.Name -eq $name))))) {
        $ModuleSettings.KeyVault
    } else {
        If (Test-TooManyAzure) {
            If ($ModuleSettings.KeyVault -and (($ModuleSettings.KeyVault.VaultName -eq $Name) -xor (-not $Name))) {
                Write-Debug "Using existing vault [$($ModuleSettings.KeyVault.VaultName)]..."
                $KeyVault = $ModuleSettings.KeyVault
            } elseif (-not $Name -and (Test-TooManySetting -Name "KeyVault")) {
                $Name = Get-TooManySetting -Name "KeyVault"
                Write-Debug "Key vault name is [$Name] and should be [$(Get-TooManySetting -Name 'KeyVault')]"
                $KeyVault = Get-AzKeyVault -VaultName $Name
            }

            If (-not $KeyVault) {
                $KeyVault = Get-AzKeyVault | Where-Object { $_.VaultName -match $Name } | Select-Object -First 1
                Set-TooManySetting -Name "KeyVault" -Value $KeyVault.VaultName
                Write-Debug "Got new vault [$($KeyVault.VaultName)]..."
            }

            If (-not $ModuleSettings.KeyVault -or $Force) {
                $ModuleSettings.KeyVault = $KeyVault
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
            $ModuleSettings.KeyVault = $KeyVault
        } elseif (Test-TooManyAzure) {
            If ($ModuleSettings.KeyVault -and (($ModuleSettings.KeyVault.VaultName -eq $Name) -xor (-not $Name))) {
                Write-Debug "Using existing vault [$($ModuleSettings.KeyVault.VaultName)]..."
            } else {
                $KeyVault = Get-AzKeyVault | Where-Object { $_.VaultName -match $Name } | Select-Object -First 1
                $ModuleSettings.KeyVault = $KeyVault
                Write-Debug "Got new vault [$($ModuleSettings.KeyVault.VaultName)]..."
            }

        }
    
        Set-TooManySetting -Name "KeyVault" -Value $ModuleSettings.KeyVault.VaultName
        Return $ModuleSettings.KeyVault
    }

Function Select-TooManyTable() {
    <#
    .SYNOPSIS
    Sets the default table to be used by the module.
    .DESCRIPTION
    Find the first table in the current subscription with the give name.
    .EXAMPLE
    PS> $MyTable = Select-TooManyKeyVault -Name "MyVault"
    .LINK
    Get-AzKeyVault
    #>
    param(
        #Name given to the Table
        [parameter(ParameterSetName="ByString",Position=1)][string]$Name,
        #Azure table object to use
        [parameter(ParameterSetName="ByObject",Mandatory=$true,Position=1)][Microsoft.Azure.Cosmos.Table.CloudTable]$Table,
        #Azure Storage Account object containing the table
        [Microsoft.Azure.Commands.Management.Storage.Models.PSStorageAccount]$StorageAccount
        )
        If ($Table) {
            $ModuleSettings.Table = $Table
        } elseif (Test-TooManyAzure) {
            If ($ModuleSettings.Table -and (($ModuleSettings.Table.Name -eq $Name) -xor (-not $Name))) {
                Write-Debug "Using existing table [$($ModuleSettings.Table.Name)]..."
            } else {
                If ($StorageAccount) {
                    $ModuleSettings.Storage = $StorageAccount
                } elseif ($ModuleSettings.Storage) {
                } elseif (Test-TooManySetting -Name "StorageAccountName") {
                    $ModuleSettings.Storage = Get-AzStorageAccount -ResourceGroupName (Get-TooManySetting -Name "StorageAccountRG") `
                        -Name (Get-TooManySetting -Name "StorageAccountName")
                } else {
                    $ModuleSettings.Storage = Get-AzStorageAccount | Where-Object{ $_.StorageAccountName -match "tmsmeta" }
                }
                If ($ModuleSettings.Storage) {
                    Set-TooManySetting -Name "StorageAccountRG" -Value $ModuleSettings.Storage.ResourceGroupName
                    Set-TooManySetting -Name "StorageAccountName" -Value $ModuleSettings.Storage.StorageAccountName
                    If (-not $Name) { $Name = Get-TooManySetting -Name KeyVault }
                    write-Debug "TMSStorage: $($ModuleSettings.Storage.StorageAccountName) - $($ModuleSettings.Storage.Context.Gettype())"
                    write-Debug "Name: $Name - $($Name.GetType())"
                    
                    $Table = (Get-AzStorageTable -Name $Name -Context $ModuleSettings.Storage.Context).CloudTable
                    If ($Table) {
                        $ModuleSettings.Table = $Table
                        Write-Debug "Using found table [$($ModuleSettings.Table.Name)]" 
                    }
                }
                Write-Debug "Got new table [$($ModuleSettings.Table.Name)]..."
            }

        }

        If ($ModuleSettings.Table) {
            Set-TooManySetting -Name "Table" -Value $ModuleSettings.Table.Name
            Return $ModuleSettings.Table
        }
    
    }

Function Test-TooManyTable() {
    <#
    .SYNOPSIS
    Check to see if table for TMS is available
    .OUTPUTS
    boolean
    #>
    param()

    If ($ModuleSettings.Table) {
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
.LINK
Register-TooManySecret
Connect-AzAccount
Set-AzContext
#>
    [Cmdletbinding()]
    param(
        #Causes the switch to the appropriate context without prompting user.
        [switch]$Force)

    $TenantID = Get-TooManySetting -Name "TenantID"
    $SubID = Get-TooManySetting -Name "SubscriptionID"
    $Context = Get-AzContext

    If ($Context.Tenant.Id -ne $TenantID -or $Context.Subscription.Id -ne $SubID) {
        $PossibleContexts = Get-AzContext -ListAvailable | Where-Object { $_.Tenant.Id -eq $TenantID }
        If ($PossibleContexts) {
            If (-not $Force) {
                Do {
                    $Response = Read-Host "Existing subscription [$($Context.Subscription.Id)] does not match previous [$SubID]. Switch context? [Y/n]"
                    If ($Response -eq '') { $Response = 'Y' }
                } Until ($Response -match "\A(Y(es)?)|(N(o)?)\Z")
            }
            If ($Force -or $Response -match '\A(Y(es)?)\Z') {
                $ExactContext = $PossibleContexts | Where-Object { $_.Subscription.Id -eq $SubID} | Select-Object -First 1
                If ($ExactContext) { 
                    $Context = $ExactContext | Set-AzContext
                } else {
                    $PossibleContexts | Select-Object -First 1 | Set-AzContext | Out-Null
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
Connect-TooManySecret
#> 
    param(
        #If flagged, cmdlet will NOT attempt to login if no current context
        [switch]$DoNotConnect,
        #Prompt the user for connection if needed
        [switch]$Prompt,
        #Switch context if existing context is not intended AzureAD/Sub
        [switch]$SwitchContext)

    $Result = $False
    $TenantID = Get-TooManySetting -Name "TenantID"
    $SubID = Get-TooManySetting -Name "SubscriptionID"
    $context = Get-AzContext

    if (-not ($context -or $DoNotConnect)) {
        $context = Connect-AzAccount -Tenant $TenantID -Subscription $SubID #-Tenant $DefaultTooManyTenantID -Subscription $DefaultTooManySubID
    } elseIf ($Prompt -or $SwitchContext) {
        Connect-TooManySecret -Force:($SwitchContext -or -not $Prompt)
    }

    If ($context) {
        If ($UpdateSettings -or (-not $TenantID)) { Set-TooManySetting -Name "TenantID" -Value $Context.Tenant.ToString() }
        If ($UpdateSettings -or (-not $SubscriptionID)) { Set-TooManySetting -Name "SubscriptionID" -Value $Context.Subscription.ToString() }
        $Result = $true
    }

    return $Result
}

Function Register-TooManySecret() {
<#
.DESCRIPTION
Sets the local settings for the Azure key vault and storage account to use by default as well as the subscription and Azure AD tenant.
.ExAMPLE
PS> Register-TooManySecret -VaultName TMSVault -ResourceGroupName TMS-rg -TableName TMSMeta -StorageAccountName mycompsa2314 `
  -StorageAccountRG Storage-rg -AADTenantID 12345678-abcd-4321-fedc-123456789012 -SubscriptionID 87654321-1234-dcba-4321-cba987654321

This will set it so you will you use the key vault TMSVault in the TMS-rg resource group in the subscription
87654321-1234-dcba-4321-cba987654321 under Azure AD 12345678-abcd-4321-fedc-123456789012.  Also, all metadata
will be stored in the table TMSMeta within the storage account mycompsa2314 within the Storage-rg resource
group of that subscription.
.LINK
Connect-TooManySecret
#>
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
