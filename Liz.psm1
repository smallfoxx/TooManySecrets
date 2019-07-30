Set-Variable -Name "RegPath" `
    -Value "HKCU:\Software\TooManySecrets" `
    -Option ReadOnly `
    -Visibility Private 

Function Get-TooManySetting() {
    param([string]$Path = $RegPath,
        [string]$Name)
    
    Get-ItemProperty -Path $Path -Name $Name
}

Function Set-TooManySetting() {
    param([string]$Path = $RegPath,
        [string]$Name,
        $Value )
    
    If (Test-TooManySetting -Path $Path) {
        Set-ItemProperty -Path $Path -Name $Name -Value $Value
    } else {
        Write-Error "Module not currently registered.  Run Register-TooManySecret to register module."
    } 
}

Function Test-TooManySetting() {
    param([string]$Path = $RegPath,
        [string]$Name)

    Test-path "$Path\$Name"
}

Function Register-TooManySetting() {
    param([string]$Path = $RegPath)

    If (Test-TooManySetting $Path) {

    } else {
        New-Item -Path $Path | Out-Null 
    }

    If (Test-TooManySetting -Path $Path -Name "Registered") {

    } else {
        Set-TooManySetting -Path $Path -Name "Registered" -Value ("{0:yyyy-MM-dd HH:mm:ss}" -f (Get-Date))
    }
}

#region Alias Listings
$aliases = @{ "Get-TooManySetting"=@() }
$aliases += @{ "Set-TooManySetting"=@() }
$aliases += @{ "Test-TooManySetting"=@() }
$aliases += @{ "Register-TooManySetting"=@() }

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
