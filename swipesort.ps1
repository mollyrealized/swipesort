<#
.NOTES
    File Name      : swipesort.ps1
    Author         : MollyInanna
    Prerequisite   : PowerShell V3 or higher
    Copyright      : (c) 2024 MollyInanna
    License        : AGPL-3.0
    Version        : 1.0
    Creation Date  : 2024
    Last Modified  : 2024-07-27

.SYNOPSIS
    A Tinder-like PowerShell script for sorting text file contents via keyboard input.

.DESCRIPTION
    This script allows users to process text files line by line, sorting each line into 'left' or 'right' categories
    using arrow key inputs. It supports a configurable UI mode and remembers progress between sessions.

.PARAMETER inputFileName
    The name of the input file to process. This should be a text file.

.PARAMETER ui
    Used to set the UI mode. Use '-ui on' for verbose mode or '-ui off' for minimal mode.

.EXAMPLE
    Set UI mode to verbose:
    .\swipesort.ps1 -ui on

.EXAMPLE
    Set UI mode to minimal:
    .\swipesort.ps1 -ui off

.EXAMPLE
    Process a file:
    .\swipesort.ps1 input.txt

.LINK
    https://github.com/mollyrealized/swipesort

#>

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$inputFileName,
    [Parameter(Mandatory=$false)]
    [string]$ui
)

# Function to handle errors consistently
function Write-ErrorAndExit {
    param([string]$ErrorMessage)
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    exit 1
}

$uiConfigFilePath = Join-Path ([System.Environment]::GetFolderPath('ApplicationData')) "swipesort-ui.cfg"

# Handle UI configuration
function Set-UiConfig {
    param([string]$Value)
    Set-Content -Path $uiConfigFilePath -Value $Value -Force
}

function Get-UiConfig {
    if (Test-Path $uiConfigFilePath) {
        return Get-Content $uiConfigFilePath
    }
    return "1"  # Default to verbose if file doesn't exist
}

# Handle UI setting command
if ($ui -eq "on") {
    Set-UiConfig "1"
    exit 0
} elseif ($ui -eq "off") {
    Set-UiConfig "0"
    exit 0
}

# If no input file is provided and no UI command, show usage
if (-not $inputFileName) {
    Write-Host "Usage:"
    Write-Host "  Set UI mode: .\swipesort.ps1 -ui on|off"
    Write-Host "  Run script: .\swipesort.ps1 <input_file>"
    exit 0
}

$uiMode = Get-UiConfig

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

# Function definitions
function Read-LastIndexConfig {
    param(
        [string]$ConfigFilePath,
        [string]$InputFileName
    )

    $config = @{}
    if (Test-Path $ConfigFilePath) {
        $configContent = Get-Content $ConfigFilePath -ErrorAction Stop
        foreach ($line in $configContent) {
            $pair = $line -split '=',2
            if($pair.Count -eq 2) {
                $config[$pair[0]] = [int]$pair[1]
            }
        }
    }
    if ($config.ContainsKey($InputFileName)) {
        return $config[$InputFileName]
    } else {
        return 0
    }
}

function Write-LastIndexConfig {
    param(
        [string]$ConfigFilePath,
        [string]$InputFileName,
        [int]$LastIndex
    )

    $config = @{}
    if (Test-Path $ConfigFilePath) {
        $configContent = Get-Content $ConfigFilePath -ErrorAction Stop
        foreach ($line in $configContent) {
            $pair = $line -split '=',2
            if($pair.Count -eq 2) {
                $config[$pair[0]] = $pair[1]
            }
        }
    }
    $config[$InputFileName] = $LastIndex
    $config.GetEnumerator() | ForEach-Object {
        "$($_.Key)=$($_.Value)"
    } | Out-File $ConfigFilePath -Force -ErrorAction SilentlyContinue
}

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

# Main script logic
try {
    $currentIndex = Read-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName

    $lines = Get-Content $inputFileName

    do {
        Clear-Host
        if ($currentIndex -ge $lines.Length) { break }
        $currentLine = $lines[$currentIndex]
        Write-Host $currentLine
        if ($uiMode -eq "1") {
            Write-Host "Swipe Left <- | Swipe Right -> | Undo ^ | Quit Q"
        }

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
                    if ($uiMode -eq "1") {
                        Write-Host "Progress saved. Exiting..."
                    }
                    return
                }
                default { 
                    if ($uiMode -eq "1") {
                        Write-Host "Invalid key. Please use arrow keys or 'Q' to quit." -ForegroundColor Yellow
                    }
                    $key = $null 
                }
            }
        }

        Write-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName -LastIndex $currentIndex
    } while ($currentIndex -lt $lines.Length)

    if ($uiMode -eq "1") {
        Write-Host "All lines processed. Files for left and right swipes are up to date."
    }
} catch {
    Write-ErrorAndExit "An unexpected error occurred: $_"
} finally {
    if ($currentIndex -lt $lines.Length) {
        Write-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName -LastIndex $currentIndex
    }
}
