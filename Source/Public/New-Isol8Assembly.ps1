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
        [string]$Path
    )
    
    begin {
        if (-not (Test-Path ($Parent = Split-Path $Path -Parent))) {
            $null = New-Item $Parent -ItemType Directory -Force
        }
        Get-Item $Path -ErrorAction SilentlyContinue | Remove-Item -Force
    }
    
    process {
        $SourceCode = Get-Content "$PSScriptRoot/ModuleIsolation.cs" -Raw
        Add-Type -Language CSharp -TypeDefinition ($SourceCode + @"
public class ${Name}ModuleInitializer : ModuleInitializer {
    public ${Name}ModuleInitializer() : base("$Name") {} 
}
"@) -OutputAssembly $Path

        if ($PSBoundParameters.ContainsKey('ManifestPath'))
        {
            $OldValue = (Import-PowerShellDataFile $ManifestPath).NestedModules

            Push-Location (Split-Path $ManifestPath -Parent)
            $NewValue = @(Resolve-Path $Path -Relative) + @($OldValue) | Get-Unique
            $NewValue -join ', '
            Pop-Location

            Update-ModuleManifest -Path $ManifestPath -NestedModules $NewValue
        }
    }
}