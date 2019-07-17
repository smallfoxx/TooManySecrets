# TooManySecrets
PowerShell module for managing secrets, passwords, and keys in Azure.

## Purpose
Someone once asked why worry about managing passwords and secrets as we move to a passwordless system. However, that is almost exactly why it is needed more now than ever. By utilizing a passwordless system to access these secrets, we can focus on ensuring only those legacy systems that don't yet support a passwordless system are stored and protected here. Hopefully we can get to the point were these systems are also being updated and changed at a regular pace to minimize the impact of password hashes. We hope for the day that this becomes completely obsolete and passwords are no longer needed. Until then, we'll deal with TooManySecrets.

# Installation
This module is also published to PowerShell Gallery and can be installed with the simple command:
  Install-Module TooManySecrets

You can also download this module and copy the folder to either of these two locations:
* %SystemRoot%\System32\WindowsPowerShell\v1.0\Modules\
* C:\Users\%Username%\Documents\WindowsPowerShell\Modules\

# Usage
Once installed, simply import the module to an active PowerShell session:
  Import-Module TooManySecrets

If you have more than one Key Vault in your Azure Subscription, use the following command to set your default Key Vault for this session:
  Select-TooManyKeyVault -Name <KeyVaultName>

Common commands:

 `Get-Password -Name <PasswordName>` 
 
>  _Returns a SecureString object of the password contained in the secret named "PasswordName"_
 
  
  `Get-Password -Name <Pass> -AsPlainText | Set-Clipboard`
  
>  _Copies the password kept in the secret named "Pass" directly to the clipboard as clear text_
 
 
   `Set-Password -Name <MyPassword> -Value "P@ssword1234"`
  
>  _Creates a secret or password named "MyPassword" with the text P@ssword1234_
 
 
   `$cred = Get-Credential MyUser@domain.com; 
   
  Set-Password -Name $cred.username -SecureValue $cred.password`
  
>  _Prompts the user for a username & password, and stores those values to the key vault with the username as the name as the secret and the password as the value_
 
 
 `$username = "MyUser@domain.com"; 
 
  $cred = New-Object PSCredential ($username, (Get-Password -Name $username))`
  
>  _Gets a secret with the user's login name "MyUser@domain.com" & passowrd, and stores it as a PSCredential called $cred_



# Goals
Initially, we're trying to make an inexpensive, shared, open-source based solution to share and retrieve password with a select group of users that allows for a few key goals:
* Secure, encrypted storage for passwords and secrets
* Multi-user access
* Multi-Factor Authentication of users accounts option
* Integration with systems via command-line and/or API
* Ability to log and record access to secrets
* Open and auditable interface with secure storage
* Integration with other services

Additional desired options:
* Change secrets on a regular basis
* Store and retrieve metadata as well
* Provide GUI interface with same data as available via GUI
