# 🚀 UltraSystemScripts

**Professional Windows System Maintenance Tools by Abhishek's AI Lab**

[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained-Yes-brightgreen.svg)](https://github.com/uniqueabhishek/UltraSystemScripts)

---

## 📦 What's Included

| Script | Description |
|--------|-------------|
| **UltraSweeper.bat** | Comprehensive disk cleanup utility - recovers gigabytes of space |
| **UltraDriverCleaner.bat** | Driver backup, cleanup, and restore tool |

---

## ⚡ Quick Start

1. **Download** the repository
2. **Right-click** on any `.bat` file
3. Select **"Run as Administrator"** (scripts will auto-elevate if needed)
4. **Follow** the on-screen prompts

> ⚠️ **Note**: These scripts require Administrator privileges to clean system files.

---

## 🧹 UltraSweeper

Reclaim disk space by cleaning:

### Automatic (No Prompts)
- ✅ Windows Update cache
- ✅ System & user temp files
- ✅ Print spooler queue
- ✅ Font cache
- ✅ Recycle Bin
- ✅ Thumbnail cache
- ✅ Windows Store/UWP app caches
- ✅ Telemetry & diagnostic data
- ✅ Microsoft Teams cache
- ✅ Outlook cache
- ✅ Office temp files

### Browser Cleanup (After Pause)
- 🌐 Google Chrome (all profiles)
- 🌐 Microsoft Edge (all profiles)
- 🌐 Firefox
- 🌐 Internet Explorer
- 🌐 Edge WebView2

### Developer Tools (Individual Y/N)
- 📦 npm, pip, NuGet, Gradle, Conda
- 🐳 Docker (system prune)
- 💻 VS Code, GitHub Desktop
- 🤖 Ollama (logs only, preserves models)
- 🎭 Playwright browsers
- 🐍 uv/Poetry
- And 20+ more applications!

### Advanced Cleanup (With Warnings)
- 🔄 Windows Restore Points
- 📁 Previous Windows installations (`Windows.old`)

---

## 🔧 UltraDriverCleaner

Professional driver management:

| Feature | Description |
|---------|-------------|
| **Cleanup** | Remove old/unused OEM drivers to free space |
| **Backup** | Export all current drivers to Desktop |
| **Restore** | Reinstall drivers from backup (multiple options) |

### Restore Options
- Add to driver store (Windows installs when device connects)
- Force install (immediately install all drivers)
- Restore specific driver by name

---

## 💡 Tips

1. **First Time?** Run UltraSweeper first to see how much space you can recover
2. **Before Major Updates**: Use UltraDriverCleaner to backup your drivers
3. **Low Disk Space?** Say "Y" to development tool caches - they rebuild automatically
4. **Browser Issues?** The browser cleanup is safe - use Ctrl+Shift+T to restore tabs

---

## 🛡️ Safety Features

- ✅ **Confirmation prompts** before destructive operations
- ✅ **Backup options** before driver cleanup
- ✅ **Error suppression** - skips missing apps gracefully
- ✅ **Laptop detection** - auto-manages hibernation appropriately
- ✅ **No user data deleted** - only caches, temp files, and logs

---

## 📋 System Requirements

- Windows 10 or Windows 11
- Administrator privileges
- ~50MB free space for script execution

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for developer documentation:
- Project structure
- Coding conventions
- How to add new cleanup targets
- Testing guidelines
- Git workflow

---

## 📜 Changelog

### v2.0 (December 2025)
- ✨ Added 12+ new developer tool cleanup targets
- ✨ UltraDriverCleaner: Added professional restore feature
- ✨ Rebranded from Beardsweeper to UltraSweeper
- 🐛 Fixed browser profile iteration for multi-profile users
- 📝 Added comprehensive developer documentation

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

## 👨‍💻 Author

**Abhishek's AI Lab**

If these scripts helped you, consider ⭐ starring the repo!

---

*Made with 💻 for the Windows community*
