#
# Module manifest for module 'PSGet_TooManySecrets'
#
# Generated by: Kit Skinner
#
# Generated on: 7/14/2019
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '0.4.196.0310'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '426237eb-1a68-4db9-a10c-b8206698c3d3'

# Author of this module
Author = 'Kit Skinner'

# Company or vendor of this module
CompanyName = 'SmallFoxx'

# Copyright statement for this module
Copyright = '© 2019 Kit Skinner. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module is useful for storing and retrieving passwords and secrets in Azure Key Vaults.  This allows for passwords and secrets to be shared among users via Azure AD authentication and policies with the relatively inexpensive Azure Key Vault resource. While communications are always encrypted and stored securely when working with the Azure Key Vault, further security can be utilized to independantly encrypting the passwords before they are transmitted to Azure. This is module and companion nested modules are published under the Apache License 2.0 and available via GitHub @ https://github.com/smallfoxx/TooManySecrets/'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
CLRVersion = '4.0'
 
# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName = 'Az.Accounts'; GUID = '17a2feff-488b-47f9-8729-e2cec094624c'; ModuleVersion = '1.5.3'; }, 
               @{ModuleName = 'Az.KeyVault'; GUID = 'cd188042-f215-4657-adfe-c17ae28cf730'; ModuleVersion = '1.2.0'; }, 
               @{ModuleName = 'Az.Resources'; GUID = '48bb344d-4c24-441e-8ea0-589947784700'; ModuleVersion = '1.4.0'; },
               @{ModuleName = 'Az.Storage'; GUID = 'dfa9e4ea-1407-446d-9111-79122977ab20'; ModuleVersion = '1.4.0'; },
               @{ModuleName = 'AzTable'; GUID = '0ed51f07-bcc5-429d-9322-0477168a0926'; ModuleVersion = '2.0.0'; }
               )

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('Whistler.psm1', 
               'Mother.psm1',
               'Liz.psm1',
               'Carl.psm1')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
<# FunctionsToExport = 'Set-TooManySecret', 'Set-TooManySecretyProperty', 
               'Get-TooManySecret', 'Get-TooManyPassword', 'Update-TooManySecret', 
               'Convert-SecretToPassword', 'Get-TooManySecretProperty', 
               'Set-TooManyPassword', 'New-TooManySecret', 'Convert-TooManyKey', 
               'New-TooManyPassword', 'Get-RandomPassword', 'Get-TooManyKeyVault', 
               'Test-TooManyKeyVault', 'Test-TooManyAzure', 'Select-TooManyKeyVault', 
               'New-TooManyKeyVault'
#>

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
# AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PasswordManager','Azure','KeyVault','Password'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/smallfoxx/TooManySecrets/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/smallfoxx/TooManySecrets/'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Implemented MetaData storage with Azure Table and local defaults in JSON config file'

        # External dependent modules of this module
        # ExternalModuleDependencies = ''

    } # End of PSData hashtable
    
 } # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/smallfoxx/TooManySecrets'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

