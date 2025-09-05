# Mac Downloads Directory Smart File Renamer 🏷️

A native macOS menu bar application that automatically renames generic filenames in your Downloads folder with intelligent, descriptive names using on-device content analysis.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## 🎯 Problem It Solves

Tired of your Downloads folder looking like this?
- `IMG_1234.jpg`
- `Screenshot 2025-01-05 at 10.23.45.png`
- `document(1).pdf`
- `untitled.docx`
- `download.zip`

This app intelligently renames them to:
- `Vacation_Beach_2025-01-05.jpg`
- `Screenshot_Xcode_2025-01-05.png`
- `Invoice_Apple_2025-01-05.pdf`
- `Document_Project_Proposal_2025-01-05.docx`
- `Archive_Source_Code_2025-01-05.zip`

## ✨ Features

### Smart Content Analysis
- **PDFs**: Extracts text to identify invoices, receipts, and documents
- **Images**: Uses Vision framework to extract text and understand content
- **Code Files**: Detects programming languages and patterns
- **Documents**: Analyzes content for meaningful titles

### Safe & Non-Destructive
- ✅ **Only renames files** - never moves or deletes
- ✅ **Waits 1 hour** before touching any file (configurable)
- ✅ **Skips already descriptive names** - won't rename meaningful filenames
- ✅ **All processing on-device** - no cloud, no privacy concerns

### Intelligent Naming
- Detects invoices and adds vendor names
- Recognizes receipts with merchant information
- Identifies vacation photos vs regular photos
- Extracts app names from screenshots
- Adds dates for easy chronological sorting

## ⚠️ IMPORTANT: macOS Permissions

The app needs permission to access your Downloads folder. When you first run it:

1. Click the menu bar icon (document with arrow)
2. Click **"Request Permissions"** 
3. Select your Downloads folder in the dialog
4. Click **"Grant Access"**

The app will save this permission for future use. You can also grant permission through System Settings > Privacy & Security > Files and Folders if needed.

## 🚀 Installation

### Option 1: Build from Source

1. **Clone the repository**
```bash
git clone https://github.com/azz0r/mac-downloads-dir-filename-monitor.git
cd mac-downloads-dir-filename-monitor
```

2. **Build the app**
```bash
chmod +x build.sh
./build.sh
```

3. **Run the app**
```bash
./build/SmartOrganizer
```

### Option 2: Using Xcode

1. Open `SmartOrganizer.xcodeproj` in Xcode
2. Select your development team (if needed)
3. Build and run (⌘R)

## 🎮 Usage

### Menu Bar Controls
- **Rename Files Now** - Manually trigger renaming
- **Request Permissions** - Grant access to Downloads folder
- **View Rename History** - See all renamed files
- **Preferences** - Configure settings
- **Launch at Login** - Auto-start with macOS

### Default Behavior
- Monitors Downloads folder every 30 minutes
- Only renames files older than 1 hour
- Skips files with descriptive names (>20 chars)
- Shows notifications when files are renamed

## ⚙️ Configuration

### Preferences
- **Check Interval**: 15 min / 30 min / 1 hour / 2 hours
- **File Age Threshold**: How old files must be before renaming
- **Smart Renaming**: Toggle content-based analysis
- **Skip Descriptive Names**: Avoid renaming meaningful filenames

### Generic Patterns Detected
The app automatically renames files matching these patterns:
- `IMG_####` → Camera photos
- `DSC####` → Digital camera photos
- `Screenshot YYYY-MM-DD` → Screenshots
- `Untitled` → Unnamed documents
- `Document#` → Generic documents
- `download` → Browser downloads
- `temp` → Temporary files

## 🔧 Technical Details

### Technologies Used
- **Swift 5.9** & SwiftUI
- **Vision Framework** - OCR and image analysis
- **NaturalLanguage Framework** - Text analysis
- **PDFKit** - PDF content extraction
- **CoreML** - Ready for future ML models

### File Processing Pipeline
1. **Monitor** - Watches Downloads folder for changes
2. **Filter** - Only processes files older than threshold
3. **Analyze** - Extracts content using appropriate framework
4. **Categorize** - Determines file type and category
5. **Generate** - Creates descriptive name based on content
6. **Rename** - Safely renames with conflict resolution

## 🛡️ Privacy & Security

- **100% Local Processing** - No internet connection required
- **No Data Collection** - Your files never leave your Mac
- **Sandboxed** - Limited permissions for safety
- **Open Source** - Inspect the code yourself

## 📝 Examples

### Before & After

| Original | Renamed | Why |
|----------|---------|-----|
| `IMG_4521.jpg` | `Vacation_Beach_2025-01-05.jpg` | Detected beach/vacation content |
| `invoice.pdf` | `Invoice_Adobe_2025-01-05.pdf` | Found Adobe in invoice text |
| `Screenshot 2025-01-05 at 14.32.11.png` | `Screenshot_VSCode_2025-01-05.png` | Detected VS Code interface |
| `document.docx` | `Document_Meeting_Notes_2025-01-05.docx` | Extracted title from content |
| `xyz123.py` | `Python_Code_WebScraper_2025-01-05.py` | Detected Python web scraping code |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Areas for improvement:

- [ ] Support for more file types
- [ ] Custom naming patterns
- [ ] Batch rename with preview
- [ ] Machine learning model integration
- [ ] Support for other folders beyond Downloads
- [ ] Localization for other languages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Inspired by the frustration of messy Downloads folders everywhere and the belief that AI should help with the small, annoying tasks in life.

## ⚠️ Disclaimer

While this app is designed to be safe and non-destructive, always maintain backups of important files. The app only renames files and never deletes or moves them.

## 🐛 Known Issues

- Vision framework OCR accuracy varies with image quality
- Some PDF formats may not extract text properly
- File rename history is stored locally and cleared on app reinstall

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on [GitHub](https://github.com/azz0r/mac-downloads-dir-filename-monitor/issues)
- Check existing issues for solutions

## 🚦 Roadmap

- **v1.1**: Custom folder support beyond Downloads
- **v1.2**: Batch operations with preview
- **v2.0**: Apple Intelligence API integration when available
- **v2.1**: iCloud sync for settings and history

---

**Made with ❤️ for everyone tired of generic filenames**