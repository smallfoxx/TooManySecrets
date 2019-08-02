
function Verb-Noun {
<#
.SYNOPSIS
Short summary
.DESCRIPTION
Detailed description.
.PARAMETER Param1
What the parameter is used for
.PARAMETER Param2
What the parameter is used for
.PARAMETER CommonOptionalParam3
What the parameter is used for
.EXAMPLE
PS> Verb-Noun -Param1 'Value' -CommonOptionalParam3 $Something
Description of what this example does
.EXAMPLE
PS> @($Param2Input, ParamTwoInput) | Verb-Noun -CommonOptionalParam3 "Another entry"
Description of what this example does
.LINK
External link #1
External link #2
#>
    [CmdletBinding(DefaultParameterSetName="ParamSet1")]
    param (
        [parameter(ValueFromPipeline=$true,Mandatory=$true,ParameterSetName="ParamSet1",Position=1)][type1]$Param1,
        [parameter(ValueFromPipeline=$true,Mandatory=$true,ParameterSetName="ParamSet2",Position=1)][type2]$Param2,
        [parameter(Position=2)][type]$CommonOptionalParam3
    )
    
    begin {
        # Run once before any iteration
    }
    
    process {
        # Run at least once and for each instance from the pipeline
    }
    
    end {
        # Run once after all iteration
    }
}

#region Alias Listings
$aliases = @{ "Verb-Function1"=@("Alias1","AliasOne") }
$aliases += @{ "Verb-Function2"=@() }
$aliases += @{ "Verb-Function3"=@("Alias3","AliasThree") }
 
#region Publish Members
foreach ($func in $aliases.Keys) {
    If ($aliases[$func].length -gt 0) {
        foreach ($alias in ($aliases[$func])) {
            # If (-not (Get-Command alias)) { New-Alias -Name alias -Value func -PassThru }
            New-Alias -Name $alias -Value $func -PassThru 
        }
        Export-ModuleMember -function $func -alias ($aliases[$func]) 
    } else {
        Export-ModuleMember -function $func
    }
}
#endregion
#endregion

