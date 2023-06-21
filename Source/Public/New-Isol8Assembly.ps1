function New-Isol8Assembly {
    <#
.SYNOPSIS
    Create a new assembly file with functionality to isolate your module dependencies.
.DESCRIPTION
    Create a new assembly (.dll) file with functionality to isolate your module dependencies.
.EXAMPLE
    PS C:\> New-Isol8Assembly -Name 'MyModule' -ManifestPath "$Dir/MyModule.psd1" -Path "$Dir/dependencies"

    Creates a new assembly file for MyModule in "$Dir/dependencies", and update the NestedModules in the manifest.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The name of the module to isolate dependencies for.
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The path to where the assembly should be created.
        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [ValidatePattern('\.dll$', ErrorMessage = 'Path must be a .dll file!')]
        [string]$Path,

        # The path to the manifest of the module to isolate dependencies for.
        [Parameter(
            Position = 2,
            ValueFromPipelineByPropertyName)]
        [ValidatePattern('\.psd1$', ErrorMessage = 'Path must be a .psd1 file!')]
        [string]$ManifestPath
    )

    begin {
        if (-not (Test-Path ($Parent = Split-Path $Path -Parent))) {
            Write-Verbose "Directory of specified location did not exist, trying to create $Parent."

            if ($PSCmdlet.ShouldProcess($Parent)) {
                $null = New-Item $Parent -ItemType Directory -Force
            }
        }

        if ($PSCmdlet.ShouldProcess($Path)) {
            Get-Item $Path -ErrorAction SilentlyContinue | Remove-Item -Force
        }
    }

    process {
        $ResolverSourceCode = Get-Content "$PSScriptRoot/ModuleIsolation.cs" -Raw
        Add-Type -Language CSharp -TypeDefinition ($ResolverSourceCode + @"
public class ${Name}ModuleInitializer : ModuleInitializer {
    public ${Name}ModuleInitializer() : base("$Name") {}
}
"@) -OutputAssembly $Path

        if ($PSBoundParameters.ContainsKey('ManifestPath')) {
            try {
                $CurrentNestedModules = Get-Metadata -Path $ManifestPath -PropertyName NestedModules
            }
            catch {
                $CurrentNestedModules = @()
            }
            Write-Verbose "Updating NestedModules in $ManifestPath."

            if ($PSCmdlet.ShouldProcess($ManifestPath)) {
                Push-Location (Split-Path $ManifestPath -Parent)
                $NewValue = @(Resolve-Path $Path -Relative) + @($CurrentNestedModules) | Get-Unique
                Pop-Location
                Update-Metadata -Path $ManifestPath -PropertyName NestedModules -Value $NewValue
            }
        }
    }
}