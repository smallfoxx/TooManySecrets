class TMSSecret {
    hidden [Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecret] $_AzSecret
    hidden [string[]]$IncludeProperties = @('SecretID','URL','Username','Created', `
        'Enabled','Expires','Id','Name','NotBefore','SecretValue','Updated', `
        'VaultName','Version')

    [string]$Name
    [SecureString]$SecretValue
    [string]$UserName
    [string]$SecretID
    [string]$URL
    [datetime]$Created
    [bool]$Enabled
    [datetime]$Expires
    [string]$Id
    [datetime]$NotBefore
    [datetime]$Updated
    [string]$VaultName
    [string]$Version

    TMSSecret () {
    }

    TMSSecret ([Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecret]$Secret) {
        $this._AzSecret = $Secret
        $this.UpdateFromSecret($Secret)
    }

    hidden [void] UpdateFromSecret() {
        If ($this._AzSecret) {
            $this.UpdateFromSecret($this._AzSecret)
        }
    }

    hidden [void] UpdateFromSecret([Microsoft.Azure.Commands.KeyVault.Models.PSKeyVaultSecret]$Secret) {
        $Properties = $Secret | get-Member -type *propert* | Where-Object { $this.IncludeProperties -contains $_.name}
        ForEach ($Prop in $Properties) {
            Write-Debug "Populating [$($Prop.name)] property"
            if ($Secret.($Prop.Name)) {
                $this.($Prop.Name) = $Secret.($Prop.Name)
            }
        }
    }

    [void] CopyToClipboard() {
        $this.CopyToClipboard(-1)
    }

    [void] CopyToClipboard([int]$timer=-1) {
        $this.CopyToClipboard($timer,10)
    }

    [void] CopyToClipboard([int]$timer=-1,[int]$MaxClear=10) {
        ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto( `
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.SecretValue) `
        )) | Set-Clipboard
        If ($timer -gt 0) {
            $wait = 0
            Do {
                Write-Progress -Activity "Copied secret [$($this.name)] to clipboard." -status "Will clear clipboard in [$($timer-$wait)] seconds" -PercentComplete (100*$wait/$timer)
                Start-Sleep -Seconds 1
                $wait++
            } Until ($wait -gt $timer)
            1..(Get-Random -minimum 3 -Maximum $MaxClear) | ForEach-Object { (1..(Get-Random -minimum 8 -Maximum 64) | ForEach-Object { [char](Get-Random -Minimum 32 -Maximum 127)} ) -join '' | Set-Clipboard }
            ' ' | Set-Clipboard
        }
    }

    [void] AddProp([string]$Name, $Value) {
        $this | Add-Member NoteProperty $Name $Value
    }
}

