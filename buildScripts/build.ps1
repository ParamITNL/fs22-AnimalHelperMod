param (
  [string]$nozip = $false
)

$destination = "C:\Users\peter\Documents\My Games\FarmingSimulator2019\mods\"
$destinationFolder = "$($destination)happyAnimals\"
$destinationZip = "$($destination)happyAnimals.zip"

if ($nozip) {
  Write-Output "Copying folder"
  if(![System.IO.File]::Exists($destinationFolder)){
    Write-Output "Creating target directory"
    [System.IO.Directory]::CreateDirectory($destinationFolder)
  }
  Copy-Item -Path *.lua, *.xml, *.dds -Destination "$($destination)\happyAnimals\"
} else {
  Write-Output "Copying zip-file"
  Compress-Archive -Path *.lua, *.xml, *.dds -Force -CompressionLevel Optimal -DestinationPath "$($destination)\happyAnimals.zip"
}