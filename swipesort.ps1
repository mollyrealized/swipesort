<#
.NOTES
    File Name      : swipesort.ps1
    Author         : MollyInanna
    Prerequisite   : None
    Copyright      : (c) 2024 MollyInanna
    License        : AGPL-3.0
    Version        : 1.0
    Creation Date  : 2024
    Last Modified  : 2024-07-27

.SYNOPSIS
    Tinder-like PowerShell script for sorting text file contents via keyboard input, creating separate files for accepted and rejected items.

.DESCRIPTION
    [to be determined]

.PARAMETER inputFileName
    The name of the input file to process. This should be a text file.

.EXAMPLE
    .\swipesort.ps1 input.txt

.LINK
    https://github.com/mollyrealized/swipesort
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$inputFileName
)

# Function to handle errors consistently
function Write-ErrorAndExit {
    param([string]$ErrorMessage)
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    exit 1
}

# Check if more than one argument is provided
if ($args.Count -gt 0) {
    Write-ErrorAndExit "Only a single filename should be provided."
}

# Check if the input file exists and is a text file
if (-not (Test-Path $inputFileName -PathType Leaf)) {
    Write-ErrorAndExit "Input file not found or is not a file."
}

try {
    $fileContent = Get-Content $inputFileName -Raw -ErrorAction Stop
    if ($fileContent -match '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]') {
        Write-ErrorAndExit "File contains non-text characters."
    }
    if ([string]::IsNullOrWhiteSpace($fileContent)) {
        Write-ErrorAndExit "Input file is empty."
    }
} catch {
    Write-ErrorAndExit "The specified file is not a valid text file or cannot be read."
}

# Derive left and right output files from input file name
$leftFileName = $inputFileName -replace '\.(\w+)$', '-left.$1'
$rightFileName = $inputFileName -replace '\.(\w+)$', '-right.$1'
$configFilePath = Join-Path ([System.Environment]::GetFolderPath('ApplicationData')) "swipesort.cfg"

function Append-ToFile {
    param(
        [string]$Path,
        [string]$Content
    )

    try {
        Add-Content $Path $Content -ErrorAction Stop
    } catch {
        Write-ErrorAndExit "Unable to write to file $Path. Please check permissions and try again."
    }
}

try {
    $currentIndex = Read-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName

    $lines = Get-Content $inputFileName

    do {
        Clear-Host
        if ($currentIndex -ge $lines.Length) { break }
        $currentLine = $lines[$currentIndex]
        Write-Host $currentLine
        Write-Host "Swipe Left <- | Swipe Right -> | Undo ^ | Quit Q"

        $key = $null
        while ($null -eq $key) {
            $input = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            switch ($input.VirtualKeyCode) {
                37 { # Left arrow key code
                    Append-ToFile -Path $leftFileName -Content $currentLine
                    $currentIndex++
                    $key = 'left'
                }
                39 { # Right arrow key code
                    Append-ToFile -Path $rightFileName -Content $currentLine
                    $currentIndex++
                    $key = 'right'
                }
                38 { # Up arrow key code
                    if ($currentIndex -gt 0) {
                        $currentIndex--
                        # Remove the last line from the respective file
                        $lastChoice = if(Test-Path $rightFileName) { (Get-Content $rightFileName)[-1] } else { $null }
                        if ($lastChoice -eq $currentLine) {
                            $allLines = Get-Content $rightFileName
                            $allLines = $allLines[0..($allLines.Count - 2)]
                            $allLines | Set-Content $rightFileName -Force
                        } else {
                            $allLines = Get-Content $leftFileName
                            $allLines = $allLines[0..($allLines.Count - 2)]
                            $allLines | Set-Content $leftFileName -Force
                        }
                    }
                    $key = 'up'
                }
                81 { # Q key code
                    Write-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName -LastIndex $currentIndex
                    Write-Host "Progress saved. Exiting..."
                    return
                }
                default { 
                    Write-Host "Invalid key. Please use arrow keys or 'Q' to quit." -ForegroundColor Yellow
                    $key = $null 
                }
            }
        }

        Write-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName -LastIndex $currentIndex
    } while ($currentIndex -lt $lines.Length)

    Write-Host "All lines processed. Files for left and right swipes are up to date."
} catch {
    Write-ErrorAndExit "An unexpected error occurred: $_"
} finally {
    if ($currentIndex -lt $lines.Length) {
        Write-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName -LastIndex $currentIndex
    }
}
