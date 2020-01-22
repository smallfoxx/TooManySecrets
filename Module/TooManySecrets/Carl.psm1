$ClassModule = "Bishop.psm1"
if (Test-Path "$PSScriptRoot\$ClassModule") {
    #this is to get the class definitions shared between modules
    $script = [ScriptBlock]::Create("using module '$PSScriptRoot\$ClassModule'")
    . $script
}

$ModuleSettings = New-Object TMSModuleSettings

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
        Write-Debug "Using table [$($ModuleSettings.Table.Name)]..."
        $row = Get-AzTableRow -Table $ModuleSettings.Table -PartitionKey "Secrets" -RowKey $Name
        If ($Row) {
            return ($row | Select-Object * -ExcludeProperty $ModuleSettings.SpecialRowProperties)
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
    ForEach ($Prop in ($Property.Keys | Where-Object { $ModuleSettings.ExcludeMetaProperties -notcontains $_ })) { $SetProperties.$Prop = $Property.$Prop}

    If ($InputObject) {
        $Name = $InputObject.Name 
        $PropNames = $InputObject | Get-Member -MemberType *Property | Where-Object { $ModuleSettings.ExcludeMetaProperties -notcontains $_.Name } | ForEach-Object { $_.name }

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
    $addResult = Add-AzTableRow -Table $ModuleSettings.Table -PartitionKey "Secrets" -RowKey $Name -UpdateExisting -Property $SetProperties
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
        #[Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecretIdentityItem]
        $InputObject,
        #[parameter(ParameterSetName="ByTMSSecret",ValueFromPipeline=$true,Mandatory=$true,Position=1)]
        #[TMSSecret]
        #$Secret,
        [switch]$Force
        )

Begin {
    If (Test-TooManyTable) {

    } else {
        exit
    }
}
Process {
    switch -Regex ($InputObject.GetType().Name) {
        "(PSKeyVaultSecret)|(TMSSecret)" {
            Write-Debug "By secret: $($InputObject.GetType())"
            $Metadata = Get-TooManyMeta -Name $InputObject.Name
            If ($Metadata) {
                Write-Debug ("existing props: [{0}]" -f (($InputObject | Get-member -MemberType *Propert* | ForEach-Object { $_.name }) -join ",")) 
                $Properties = $Metadata | Get-Member -MemberType *Propert* | Where-Object { $ModuleSettings.SpecialRowProperties -notcontains $_.name }
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
        Write-Debug "Using table [$($ModuleSettings.Table.Name)]..."
        $allRows = Get-AzTableRow -Table $ModuleSettings.Table -PartitionKey "Secrets" | Sort-Object -Property RowKey 
        If ($allRows) {
            ForEach ($row in $allRows) { $row | Add-Member NoteProperty Name $row.RowKey -ErrorAction SilentlyContinue }
            If ($IncludeMetadata) {
                return ($allRows | Select-Object * -ExcludeProperty $ModuleSettings.SpecialRowProperties)
            } else {
                return ($allRows | Select-Object Name)
            }
        } else {
            return $null
        }

    }

}
