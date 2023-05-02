$FileSharePath = "\\fileshare\path"
$OutputPath = "C:\Output"
$MaxFileSizeInBytes = 100MB

if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Force -Path $OutputPath
}

function Get-FileShareInventory {
    param (
        [string]$Path
    )

    Get-ChildItem -Path $Path -Recurse -Force | ForEach-Object {
        if (!($_.PSIsContainer)) {
            $fileInfo = @{
                "Name"       = $_.Name
                "FullName"   = $_.FullName
                "Size"       = $_.Length
                "LastWriteTime" = $_.LastWriteTime
            }
            New-Object PSObject -Property $fileInfo
        }
    }
}

function Export-CSVWithFileSizeLimit {
    param (
        [Parameter(Mandatory = $true)][System.Object[]]$Data,
        [Parameter(Mandatory = $true)][string]$OutputPath,
        [Parameter(Mandatory = $true)][int64]$MaxFileSizeInBytes
    )

    $csvFileIndex = 1
    $csvFilePath = Join-Path $OutputPath ("Inventory_{0}.csv" -f $csvFileIndex)
    $csvData = $Data | ConvertTo-Csv -NoTypeInformation
    $currentFileSize = 0

    Set-Content -Path $csvFilePath -Value $csvData[0] -Force
    $csvData[0..($csvData.Count - 1)] | ForEach-Object {
        $currentLine = $_
        $currentLineSize = ([System.Text.Encoding]::UTF8.GetByteCount($currentLine) + 2) # 2 bytes for newline characters

        if (($currentFileSize + $currentLineSize) -gt $MaxFileSizeInBytes) {
            $csvFileIndex++
            $csvFilePath = Join-Path $OutputPath ("Inventory_{0}.csv" -f $csvFileIndex)
            Set-Content -Path $csvFilePath -Value $csvData[0] -Force
            $currentFileSize = 0
        }

        Add-Content -Path $csvFilePath -Value $currentLine
        $currentFileSize += $currentLineSize
    }
}

$inventory = Get-FileShareInventory -Path $FileSharePath
Export-CSVWithFileSizeLimit -Data $inventory -OutputPath $OutputPath -MaxFileSizeInBytes $MaxFileSizeInBytes
