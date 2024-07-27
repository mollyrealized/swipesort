param(
    [string]$inputFileName = "input.txt" # Default input file name
)

# Derive left and right output files from input file name
$leftFileName = $inputFileName -replace '\.(\w+)$', '-left.$1'
$rightFileName = $inputFileName -replace '\.(\w+)$', '-right.$1'
$configFilePath = Join-Path ([System.Environment]::GetFolderPath('ApplicationData')) "swipesort.cfg"

function Read-LastIndexConfig {
    param(
        [string]$ConfigFilePath,
        [string]$InputFileName
    )

    $config = @{} # Create a dictionary to hold filename-index pairs
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

    $config = @{} # Create a dictionary to hold filename-index pairs
    if (Test-Path $ConfigFilePath) {
        $configContent = Get-Content $ConfigFilePath -ErrorAction Stop
        foreach ($line in $configContent) {
            $pair = $line -split '=',2
            if($pair.Count -eq 2) {
                $config[$pair[0]] = $pair[1]
            }
        }
    }
    $config[$InputFileName] = $LastIndex # Update the index for the current file
    $config.GetEnumerator() | ForEach-Object {
        "$($_.Key)=$($_.Value)" # Convert each dictionary entry to a string line
    } | Out-File $ConfigFilePath -Force -ErrorAction SilentlyContinue # Save to file
}

function Append-ToFile {
    param(
        [string]$Path,
        [string]$Content
    )

    Add-Content $Path $Content -ErrorAction SilentlyContinue
}

try {
    $currentIndex = Read-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName

    if (-not (Test-Path $inputFileName)) {
        throw "Input file not found."
    }

    $lines = Get-Content $inputFileName

    do {
        Clear-Host
        if ($currentIndex -ge $lines.Length) { break }
        $currentLine = $lines[$currentIndex]
        Write-Host $currentLine
        # Write-Host "Swipe Left <- | Swipe Right -> | Undo ^ | Quit Q"

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
                    # Write-Host "Progress saved. Exiting..."
                    return
                }
                default { $key = $null }
            }
        }

        Write-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName -LastIndex $currentIndex
    } while ($currentIndex -lt $lines.Length)

    Write-Host "All lines processed. Files for left and right swipes are up to date."
} catch {
    Write-Host "An error occurred: $_"
} finally {
    if ($currentIndex -lt $lines.Length) {
        Write-LastIndexConfig -ConfigFilePath $configFilePath -InputFileName $inputFileName -LastIndex $currentIndex
    }
}
