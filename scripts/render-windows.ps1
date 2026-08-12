param([string] $InputPath = 'src/mkscript.ps1.in', [string] $OutputDirectory = 'build/windows')
$version = (Get-Content -LiteralPath VERSION -Raw).Trim()
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$scriptPath = Join-Path $OutputDirectory 'mkscript.ps1'
(Get-Content -LiteralPath $InputPath -Raw).Replace('@VERSION@', $version) | Set-Content -LiteralPath $scriptPath -Encoding UTF8
@'
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0mkscript.ps1" %*
exit /b %errorlevel%
'@ | Set-Content -LiteralPath (Join-Path $OutputDirectory 'mkscript.cmd') -Encoding ASCII
$encodedScript = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((Get-Content -LiteralPath $scriptPath -Raw)))
$launcherSource = @"
using System;
using System.Diagnostics;
using System.IO;
using System.Text;

internal static class MkScriptLauncher
{
    private const string EncodedScript = "$encodedScript";
    private static string Quote(string value)
    {
        if (value.Length > 0 && value.IndexOfAny(new[] { ' ', '\t', '\n', '\v', '"' }) < 0) return value;
        var result = new StringBuilder("\"");
        var slashes = 0;
        foreach (var character in value)
        {
            if (character == '\\') { slashes++; continue; }
            if (character == '"') { result.Append('\\', slashes * 2 + 1).Append('"'); slashes = 0; continue; }
            result.Append('\\', slashes).Append(character); slashes = 0;
        }
        result.Append('\\', slashes * 2).Append('"');
        return result.ToString();
    }
    public static int Main(string[] args)
    {
        var temporaryScript = Path.Combine(Path.GetTempPath(), "mkscript-" + Guid.NewGuid().ToString("N") + ".ps1");
        try
        {
            File.WriteAllBytes(temporaryScript, Convert.FromBase64String(EncodedScript));
            var arguments = new StringBuilder("-NoLogo -NoProfile -ExecutionPolicy Bypass -File ").Append(Quote(temporaryScript));
            foreach (var argument in args) arguments.Append(' ').Append(Quote(argument));
            using (var process = Process.Start(new ProcessStartInfo("powershell.exe", arguments.ToString()) { UseShellExecute = false }))
            {
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        finally { try { File.Delete(temporaryScript); } catch { } }
    }
}
"@
$compilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters
$compilerParameters.CompilerOptions = '/platform:x64'
$compilerParameters.GenerateExecutable = $true
$compilerParameters.OutputAssembly = Join-Path $OutputDirectory 'mkscript.exe'
[void] $compilerParameters.ReferencedAssemblies.Add('System.dll')
$compiler = New-Object Microsoft.CSharp.CSharpCodeProvider
$compilerResult = $compiler.CompileAssemblyFromSource($compilerParameters, $launcherSource)
if ($compilerResult.Errors.HasErrors) {
    throw (($compilerResult.Errors | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine)
}
Write-Output $scriptPath
