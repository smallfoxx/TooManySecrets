
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

    $row = Get-AzTableRow -Table $TMSTable -PartitionKey "Secrets" -RowKey $Name
    If ($Row) {
        return ($row | Select-Object -ExcludeProperty $SpecialRowProperties)
    } else {
        return $null
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


#region Alias Listings
$aliases = @{ "Get-TooManyMeta"=@() }
$aliases += @{ "Set-TooManyMeta"=@() }
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
