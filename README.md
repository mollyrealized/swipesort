# SwipeSort

SwipeSort is a versatile tool for quickly sorting through lines of a text file using a Tinder-like swipe interface. It's available as an executable (EXE), a PowerShell script (PS1), and a batch file (BAT) for running from the Command Shell. Perfect for rapidly categorizing large lists of items.

## Features

- Tinder-like interface for sorting text file contents
- Left and right swipe functionality using arrow keys
- Rewind feature for correcting mistakes (can go back multiple steps)
- Progress saving between sessions
- Configurable UI mode (verbose or minimal)
- Compatible with any text file format

## Requirements

- Windows operating system
- For PS1/BAT version: PowerShell V3 or higher

## Installation

1. Download the SwipeSort package from the releases page.
2. Choose your preferred version:
   - EXE: Place `swipesort.exe` in a directory that's already in your system PATH.
   - PS1/BAT: 
     - Place both `swipesort.bat` and `swipesort.ps1` in a directory that's already in your system PATH, or
     - Place the files in your desired location and edit `swipesort.bat` to reflect the full path of `swipesort.ps1` on your system.
3. For PS1 version: Ensure PowerShell execution policy allows running scripts.

## Usage

### Setting UI Mode

You can set the UI mode to verbose or minimal:

```
swipesort -ui on  # Verbose mode
swipesort -ui off # Minimal mode
```

### Processing a File

To start sorting a file:

```
swipesort path\to\your\file.txt
```

### Controls

- Left Arrow: Swipe left (reject)
- Right Arrow: Swipe right (accept)
- Up Arrow: Rewind (undo last action, can be used multiple times)
- Q: Quit and save progress

## How It Works

1. The tool reads the input file line by line.
2. Each line is displayed on the screen.
3. Use the left or right arrow key to categorize the line.
4. The line is appended to either the 'left' or 'right' output file based on your choice.
5. Use the up arrow to rewind if you make a mistake. You can go back multiple steps.
6. Progress is automatically saved, allowing you to resume later.

## Output

SwipeSort creates two output files in the same directory as the input file:

- `inputfilename-left.txt`: Contains all left-swiped (rejected) items
- `inputfilename-right.txt`: Contains all right-swiped (accepted) items

## Configuration

SwipeSort uses two configuration files stored in the user's AppData folder:

- `swipesort.cfg`: Stores the last processed index for each input file
- `swipesort-ui.cfg`: Stores the UI mode preference (0 for minimal, 1 for verbose)

## License

This project is licensed under the AGPL-3.0 License. See the LICENSE file for details.

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/mollyrealized/swipesort/issues).

## Author

**MollyInanna**

- GitHub: [@mollyrealized](https://github.com/mollyrealized)
