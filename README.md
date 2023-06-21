# Isol8

[![Isol8Downloads]][Isol8Gallery]

A PowerShell module to handle AssemblyLoadContext management for module authoring.

```PowerShell
# Install the module from PSGallery
Install-Module Isol8

# Create a new .dll file for your module, and update the NestedModules in the manifest
New-Isol8Assembly -Name 'MyModule' -ManifestPath "$Dir/MyModule.psd1" -Path "$Dir/dependencies"
```

<!-- References -->
[Isol8Downloads]: https://img.shields.io/powershellgallery/dt/Isol8
[Isol8Gallery]: https://www.powershellgallery.com/packages/Isol8/
