
$SpecialRowProperties = @("Etag","PartitionKey","RowKey","TableTimestamp")
 
Function Get-TooManyMeta() {
<#
.SYNOPSIS
Get the metadata associated with a secret
.DESCRIPTION

.PARAMETER Name
The name of a Secret in the current Azure subscription.
.EXAMPLE
PS> Get-TooManyMeta -Name "MySecret"

.LINK
Get-TooManyKeyVault
Get-TooManySecret
Get-AzKeyVault
#>
    param([string]$Name)

    If (Test-TooManyTable) {
        Write-Debug "Using table [$($TMSTable.Name)]..."
        $row = Get-AzTableRow -Table $TMSTable -PartitionKey "Secrets" -RowKey $Name
        If ($Row) {
            return ($row | Select-Object -ExcludeProperty $SpecialRowProperties)
        } else {
            return $null
        }
    }
}

Function Set-TooManyMeta() {
    <#
    .SYNOPSIS
    Get the metadata associated with a secret
    .DESCRIPTION
    
    .PARAMETER Name
    The name of a Secret in the current Azure subscription.
    .EXAMPLE
    PS> Get-TooManyMeta -Name "MySecret"
    
    .LINK
    Get-TooManyKeyVault
    Get-TooManySecret
    Get-AzKeyVault
    AzTable
    #>
        param([string]$Name,
            [hashtable]$Property)
    
        $addResult = Add-AzTableRow -Table $TMSTable -PartitionKey "Secrets" -RowKey $Name -UpdateExisting -Property $Property
        If ($addResult) {
            If ($addResult.HttpStatusCode -lt 400 -and $addResult.HttpStatusCode -ge 200) {
                return $addResult.Result.Properties 
            }
        }
    }

function Add-TooManyMeta () {
    param(
        [parameter(ParameterSetName="ByIdentityItem",ValueFromPipeline=$true,Mandatory=$true,Position=1)][Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecretIdentityItem]$InputObject,
        [switch]$Force
        )

Begin {}
Process {
    switch ($InputObject.GetType().Name) {
        "PSKeyVaultSecret" {
            Write-Debug "By secret: $($InputObject.GetType())"
            $Metadata = Get-TooManyMeta -Name $InputObject.Name
            If ($Metadata) {
                $Properties = $Metadata | Get-Member -MemberType *Propert* | Where-Object { $SpecialRowProperties -notcontains $_.name }
                ForEach ($Property in $Properties) {
                    $InputObject | Add-Member -MemberType $Property.MemberType -Name $Property.Name -Value ($Metadata.($Property.Name)) -Force:$Force
                }
            }
            $InputObject
        }
        Default {
            If ($InputObject) {
                Write-Debug "By ident: $($InputObject.GetType())"
                $Secret = Get-TooManySecret -Name $InputObject.Name -Version $InputObject.Version -ExcludeMetadata
                $Secret | Add-TooManyMeta -Force:$Force
            }
        }
    }
}
}

#region Alias Listings
$aliases = @{ "Get-TooManyMeta"=@() }
$aliases += @{ "Set-TooManyMeta"=@() }
$aliases += @{ "Add-TooManyMeta"=@() }
#$aliases += @{ "Tes-TooManyKeyVault"=@() }
#$aliases += @{ "Select-TooManyKeyVault"=@("Select-KeyVault") }

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
