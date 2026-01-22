# Switor

A macOS menu bar app for quickly changing display resolution and refresh rate with keyboard shortcuts.

## Features

- Change display resolution from the menu bar
- Switch between HiDPI and non-HiDPI modes
- Global keyboard shortcuts for quick resolution switching
- Supports multiple displays

## Requirements

- macOS 13.0 or later
- Xcode Command Line Tools

## Build

```bash
# Clone the repository
git clone https://github.com/yourusername/switor.git
cd switor

# Build the app
./build-app.sh

# Run
open Switor.app

# Or install to Applications
cp -r Switor.app /Applications/
```

## Usage

1. Click the menu bar icon to open the resolution picker
2. Use the slider or dropdown to change resolution
3. Toggle HiDPI mode if available
4. Configure keyboard shortcuts in Settings

## Configuration

Settings are stored in `~/.config/switor/config.json`

## License

Personal use. If you want to use it, build it yourself.
