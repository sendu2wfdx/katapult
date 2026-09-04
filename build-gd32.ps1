$ErrorActionPreference = 'Stop'

$Distro = 'T113'
$WslRepo = '/mnt/d/Documents/ChatGPT/创想三维/mcu/Katapult_GD32'
$Targets = ($args -join ' ')

wsl.exe -d $Distro -- bash -lc "cd '$WslRepo' && JOBS=32 sh scripts/build-gd32-matrix.sh $Targets"
if ($LASTEXITCODE -ne 0) {
    throw "GD32 Katapult build failed with exit code $LASTEXITCODE"
}
