$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& "$root/scripts/render-windows.ps1" | Out-Null
$command = "$root/build/windows/mkscript.ps1"
$launcher = "$root/build/windows/mkscript.exe"
$sandbox = Join-Path ([IO.Path]::GetTempPath()) ("mkscript-test-" + [guid]::NewGuid())
New-Item -ItemType Directory $sandbox | Out-Null
$oldLocalAppData=$env:LOCALAPPDATA; $oldBin=$env:MKSCRIPT_BIN_DIR
try {
    $env:LOCALAPPDATA=Join-Path $sandbox 'local'; $env:MKSCRIPT_BIN_DIR=Join-Path $sandbox 'bin'
    Push-Location $sandbox
    & $command demo
    if (-not (Test-Path demo.cmd)) { throw 'default .cmd creation failed' }
    if ((Get-Content demo.cmd -TotalCount 1) -ne '@echo off') { throw 'invalid cmd template' }
    $launcherVersion = & $launcher --version | Out-String
    if ($LASTEXITCODE -ne 0 -or $launcherVersion -notmatch '^mkscript \d') { throw 'standalone Windows launcher failed' }
    & $launcher 'space name'
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path 'space name.cmd')) { throw 'standalone launcher argument quoting failed' }
    & $command -t terraform main.tf
    if (-not (Select-String -Quiet -LiteralPath main.tf -Pattern 'required_version')) { throw 'terraform template failed' }
    & $command -t ansible site.yml
    if (-not (Select-String -Quiet -LiteralPath site.yml -Pattern 'hosts: all')) { throw 'ansible template failed' }
    $additionalTemplates = @(
        @{ Template = 'dockerfile'; Path = 'Dockerfile'; Needle = 'FROM alpine:3.22' }
        @{ Template = 'docker-compose'; Path = 'compose.yaml'; Needle = '  compose:' }
        @{ Template = 'k8s-namespace'; Path = 'namespace.yaml'; Needle = 'kind: Namespace' }
        @{ Template = 'k8s-pod'; Path = 'pod.yaml'; Needle = 'kind: Pod' }
        @{ Template = 'k8s-deployment'; Path = 'deployment.yaml'; Needle = 'kind: Deployment' }
        @{ Template = 'k8s-service'; Path = 'service.yaml'; Needle = 'kind: Service' }
        @{ Template = 'k8s-configmap'; Path = 'configmap.yaml'; Needle = 'kind: ConfigMap' }
        @{ Template = 'k8s-secret'; Path = 'secret.yaml'; Needle = 'kind: Secret' }
        @{ Template = 'k8s-ingress'; Path = 'ingress.yaml'; Needle = 'kind: Ingress' }
        @{ Template = 'k8s-networkpolicy'; Path = 'networkpolicy.yaml'; Needle = 'kind: NetworkPolicy' }
        @{ Template = 'k8s-serviceaccount'; Path = 'serviceaccount.yaml'; Needle = 'kind: ServiceAccount' }
        @{ Template = 'k8s-role'; Path = 'role.yaml'; Needle = 'kind: Role' }
        @{ Template = 'k8s-rolebinding'; Path = 'rolebinding.yaml'; Needle = 'kind: RoleBinding' }
        @{ Template = 'k8s-clusterrole'; Path = 'clusterrole.yaml'; Needle = 'kind: ClusterRole' }
        @{ Template = 'k8s-clusterrolebinding'; Path = 'clusterrolebinding.yaml'; Needle = 'kind: ClusterRoleBinding' }
        @{ Template = 'k8s-persistentvolume'; Path = 'persistentvolume.yaml'; Needle = 'kind: PersistentVolume' }
        @{ Template = 'k8s-persistentvolumeclaim'; Path = 'persistentvolumeclaim.yaml'; Needle = 'kind: PersistentVolumeClaim' }
        @{ Template = 'k8s-storageclass'; Path = 'storageclass.yaml'; Needle = 'kind: StorageClass' }
        @{ Template = 'k8s-statefulset'; Path = 'statefulset.yaml'; Needle = 'kind: StatefulSet' }
        @{ Template = 'k8s-daemonset'; Path = 'daemonset.yaml'; Needle = 'kind: DaemonSet' }
        @{ Template = 'k8s-job'; Path = 'job.yaml'; Needle = 'kind: Job' }
        @{ Template = 'k8s-cronjob'; Path = 'cronjob.yaml'; Needle = 'kind: CronJob' }
        @{ Template = 'k8s-horizontalpodautoscaler'; Path = 'horizontalpodautoscaler.yaml'; Needle = 'kind: HorizontalPodAutoscaler' }
    )
    foreach ($case in $additionalTemplates) {
        & $command -t $case.Template $case.Path
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $case.Path)) { throw "Windows template creation failed: $($case.Template)" }
        if (-not (Select-String -Quiet -LiteralPath $case.Path -Pattern $case.Needle -SimpleMatch)) { throw "Windows template content failed: $($case.Template)" }
    }
    $bashErrorPath = Join-Path $sandbox 'bash-template-error.txt'
    & powershell.exe -NoProfile -File $command -t bash nope 2> $bashErrorPath
    $bashExitCode = $LASTEXITCODE
    $bashError = Get-Content -LiteralPath $bashErrorPath -Raw
    if ($bashExitCode -ne 64 -or $bashError -notmatch 'expected cmd, terraform, ansible, dockerfile, docker-compose, or a supported k8s-\* template') { throw 'Windows bash template rejection failed' }
    & $command -g tool
    if (-not (Test-Path "$env:MKSCRIPT_BIN_DIR/tool.cmd")) { throw 'wrapper creation failed' }
    & $command -c tool
    if ($LASTEXITCODE -ne 0) { throw 'wrapper check failed' }
    & $command -mv tool moved
    if (-not (Test-Path moved.cmd) -or -not (Test-Path "$env:MKSCRIPT_BIN_DIR/moved.cmd") -or (Test-Path "$env:MKSCRIPT_BIN_DIR/tool.cmd")) { throw 'wrapped move failed' }
    $resolved = & $command -f powershell.exe | Out-String
    if ($LASTEXITCODE -ne 0 -or $resolved -notmatch 'command') { throw 'native command lookup failed' }

    $package = Join-Path $sandbox 'package'
    $installed = Join-Path $sandbox 'installed'
    $installedWrappers = Join-Path $sandbox 'installed-bin'
    New-Item -ItemType Directory $package | Out-Null
    Copy-Item "$root/build/windows/*" -Destination $package
    Copy-Item "$root/packaging/windows/*" -Destination $package
    & "$package/install.ps1" -InstallDirectory $installed -WrapperDirectory $installedWrappers -SkipPath
    if (-not (Test-Path "$installed/mkscript.exe") -or -not (Test-Path "$installed/mkscript.cmd") -or -not (Test-Path "$installed/uninstall.cmd")) { throw 'Windows installer failed' }
    Write-Output 'All Windows tests passed.'
} finally {
    Pop-Location -ErrorAction SilentlyContinue
    $env:LOCALAPPDATA=$oldLocalAppData; $env:MKSCRIPT_BIN_DIR=$oldBin
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
}
