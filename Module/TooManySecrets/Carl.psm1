
Set-Variable -Name "SpecialRowProperties" `
    -Value @("Etag","PartitionKey","RowKey","TableTimestamp") `
    -Option AllScope
#$SpecialRowProperties = @("Etag","PartitionKey","RowKey","TableTimestamp")
$CommonParameters = @("Debug","ErrorAction","ErrorVariable","Force","InformationAction","InformationVariable","OutVariable","OutBuffer","PipelineVariable","Verbose","WarningAction","WarningVariable","WhatIf","Confirm","PassThru")
$ExcludeMetaProperties = $SpecialRowProperties + `
    $CommonParameters + `
    @("Secret","Name","Property","SecureValue","DisablePrevious","ImportTags","Attributes","ContentType","Created","Enabled","Expires","Id","NotBefore","SecretValueText","Tags","TagsTable","Updated","VaultName","Version")
   

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
            return ($row | Select-Object * -ExcludeProperty $SpecialRowProperties)
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
    PS> Set-TooManyMeta -Name "MySecret" -Property @{ "Col1"="Value1"; "Col2"="Value2" }
    
    .LINK
    Get-TooManyKeyVault
    Get-TooManySecret
    Get-AzKeyVault
    AzTable
    #>
    param([parameter(ParameterSetName="ByObject",ValueFromPipeline=$true,Mandatory=$true,Position=1)][PSObject]$InputObject,
        [parameter(ParameterSetName="ByObject",Mandatory=$true,Position=1)][switch]$ImportTags,
        [parameter(ParameterSetName="ByName",Mandatory=$true,Position=1)][string]$Name,
        [hashtable]$Property=@{})

Process {
    $SetProperties = @{}
    ForEach ($Prop in ($Property.Keys | Where-Object { $ExcludeMetaProperties -notcontains $_ })) { $SetProperties.$Prop = $Property.$Prop}

    If ($InputObject) {
        $Name = $InputObject.Name 
        $PropNames = $InputObject | Get-Member -MemberType *Property | Where-Object { $ExcludeMetaProperties -notcontains $_.Name } | ForEach-Object { $_.name }

        $SetProperties.SecretID = $InputObject.ID
        ForEach ($PropName in $PropNames) {
            If (-not $SetProperties.ContainsKey($PropName)) {
                $SetProperties.$PropName = $InputObject.$PropName
            }
        }

        If ($ImportTags -and $InputObject.Tags) {
            ForEach ($Tag in ($InputObject.Tags.Keys | Where-Object{ -not $SetProperties.ContainsKey( $_ ) } ) ) {
                $SetProperties.$Tag = $InputObject.Tags.$Tag
            }
        }
    }

    write-Debug "Meta for [$Name]"
    $addResult = Add-AzTableRow -Table $TMSTable -PartitionKey "Secrets" -RowKey $Name -UpdateExisting -Property $SetProperties
    If ($addResult) {
        If ($addResult.HttpStatusCode -lt 400 -and $addResult.HttpStatusCode -ge 200) {
            return $addResult.Result.Properties 
        }
    }
}

}

function Add-TooManyMeta () {
    param(
        [parameter(ParameterSetName="ByIdentityItem",ValueFromPipeline=$true,Mandatory=$true,Position=1)]
        [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecretIdentityItem]
        $InputObject,
        [switch]$Force
        )

Begin {
    If (Test-TooManyTable) {

    } else {
        exit
    }
}
Process {
    switch ($InputObject.GetType().Name) {
        "PSKeyVaultSecret" {
            Write-Debug "By secret: $($InputObject.GetType())"
            $Metadata = Get-TooManyMeta -Name $InputObject.Name
            If ($Metadata) {
                Write-Debug ("existing props: [{0}]" -f (($InputObject | Get-member -MemberType *Propert* | %{ $_.name }) -join ",")) 
                $Properties = $Metadata | Get-Member -MemberType *Propert* | Where-Object { $SpecialRowProperties -notcontains $_.name }
                ForEach ($Property in $Properties) {
                    Write-Debug "Adding member [$($Property.Name)]" #-ForegroundColor Yellow
                    $InputObject | Add-Member -MemberType $Property.MemberType -Name $Property.Name -Value ($Metadata.($Property.Name)) -Force:$Force
                }
            } else {
                Write-Debug "No meta data"
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

Function Get-TooManyMetaList() {
    param(
        [switch]$IncludeMetadata
    )

    If (Test-TooManyTable) {
        Write-Debug "Using table [$($TMSTable.Name)]..."
        $allRows = Get-AzTableRow -Table $TMSTable -PartitionKey "Secrets" | Sort-Object -Property RowKey 
        If ($allRows) {
            ForEach ($row in $allRows) { $row | Add-Member NoteProperty Name $row.RowKey -ErrorAction SilentlyContinue }
            If ($IncludeMetadata) {
                return ($allRows | Select-Object * -ExcludeProperty $SpecialRowProperties)
            } else {
                return ($allRows | Select-Object Name)
            }
        } else {
            return $null
        }

    }

}

#region Alias Listings
$aliases = @{ "Get-TooManyMeta"=@() }
$aliases += @{ "Set-TooManyMeta"=@() }
$aliases += @{ "Add-TooManyMeta"=@() }
$aliases += @{ "Get-TooManyMetaList"=@() }

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
