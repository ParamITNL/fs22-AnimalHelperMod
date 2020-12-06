param (
  [Boolean]$nozip = $false
)

Write-Output "Create folder instead of zip: $($nozip)"

$destination = "D:\FS19\Mods\"
$destinationFolder = "$($destination)AnimalHelper\"
$destinationZip = "$($destination)FS19_AnimalHelper.zip"

if ($nozip -eq $true) {
  Write-Output "Copying folder"
  if(![System.IO.File]::Exists($destinationFolder)){
    Write-Output "Creating target directory"
    [System.IO.Directory]::CreateDirectory($destinationFolder)
  }
  Copy-Item -Path *.lua, *.xml, *.dds -Destination "$($destination)\happyAnimals\"
} else {
  Write-Output "Creating zip-file $($destinationZip)"
  Compress-Archive -Path *.lua, *.xml, *.dds -Force -CompressionLevel Optimal -DestinationPath "$($destinationZip)"
}