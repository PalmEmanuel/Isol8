function New-Isol8Assembly {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory, 
            Position = 0, 
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [ValidatePattern('\.dll$', ErrorMessage = 'Path must be a .dll file!')]
        [string]$Path,

        [Parameter(
            Position = 2,
            ValueFromPipelineByPropertyName)]
        [ValidatePattern('\.psd1$', ErrorMessage = 'Path must be a .psd1 file!')]
        [string]$ManifestPath
    )
    
    begin {
        if (-not (Test-Path ($Parent = Split-Path $Path -Parent))) {
            Write-Verbose "Directory of specified location did not exist, trying to create $Parent."
            $null = New-Item $Parent -ItemType Directory -Force
        }
        Get-Item $Path -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    
    process {
        $ResolverSourceCode = Get-Content "$PSScriptRoot/ModuleIsolation.cs" -Raw
        Add-Type -Language CSharp -TypeDefinition ($ResolverSourceCode + @"
public class ${Name}ModuleInitializer : ModuleInitializer {
    public ${Name}ModuleInitializer() : base("$Name") {} 
}
"@) -OutputAssembly $Path

        if ($PSBoundParameters.ContainsKey('ManifestPath'))
        {
            $CurrentNestedModules = Get-Metadata -Path $ManifestPath -PropertyName NestedModules
            Write-Verbose "Updating NestedModules in $ManifestPath."

            Push-Location (Split-Path $ManifestPath -Parent)
            $NewValue = @(Resolve-Path $Path -Relative) + @($CurrentNestedModules) | Get-Unique
            Pop-Location
            
            Update-Metadata -Path $ManifestPath -PropertyName NestedModules -Value $NewValue
        }
    }
}