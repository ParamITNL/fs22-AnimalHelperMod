param (
  [Boolean]$nozip = $false,
  [Boolean]$startFS = $false,
  [Boolean]$clearLog = $true
)

Write-Output "Create folder instead of zip: $($nozip)"

$destination = "D:\FS22\Mods\"
$destinationFolder = "$($destination)FS22_AnimalHelper\"
$destinationZip = "$($destination)FS22_AnimalHelper.zip"
$fsExecutable = "D:\Program Files (x86)\Farming Simulator 2022\FarmingSimulator2022.exe"
$sourcePath = "*.lua", "*.xml", "*.dds", "gui", "i18n"

if ($nozip -eq $true) {
  Write-Output "Copying folder"
  if(![System.IO.File]::Exists($destinationFolder)){
    Write-Output "Creating target directory"
    [System.IO.Directory]::CreateDirectory($destinationFolder)
  }

  if ([System.IO.File]::Exists($destinationZip)) {
    Write-Warning "ZIP File exists, will be deleted!"
    [System.IO.File]::Delete($destinationZip)
  }
  Copy-Item -Path $sourcePath -Destination "$($destinationFolder)" -Recurse -Force
} else {
  if ([System.IO.Directory]::Exists($destinationFolder)) {
    Write-Warning "Mod-folder exists, will be deleted!"
    [System.IO.Directory]::Delete($destinationFolder, $true)
  }

  Write-Output "Creating zip-file $($destinationZip)"
  Compress-Archive -Path $sourcePath -Force -CompressionLevel Optimal -DestinationPath "$($destinationZip)"
}

if ($startFS -eq $true) {
  if ($clearLog -eq $true) {
    $logFileLocation = "$([Environment]::GetFolderPath("MyDocuments"))\My Games\FarmingSimulator2022\log.txt"
    Write-Output "Checking if logfile exists: $($logFileLocation)"
    [System.IO.File]::Delete($logFileLocation);
  }
  if ([System.IO.File]::Exists($fsExecutable)) {
    Write-Output "Starting FS22"
    & $fsExecutable -restart
  }
}