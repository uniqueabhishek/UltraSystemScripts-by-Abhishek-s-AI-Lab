# Developer Documentation

## UltraSystemScripts by Abhishek's AI Lab

Welcome to the UltraSystemScripts project! This guide will help you understand the codebase, contribute effectively, and maintain consistency with existing code.

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Scripts Deep Dive](#scripts-deep-dive)
4. [Coding Conventions](#coding-conventions)
5. [Adding New Features](#adding-new-features)
6. [Testing Guidelines](#testing-guidelines)
7. [Common Patterns](#common-patterns)
8. [Git Workflow](#git-workflow)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

**Purpose**: A collection of Windows system maintenance batch scripts designed to automate disk cleanup, driver management, and system optimization tasks.

**Target Audience**: Windows power users, IT administrators, and anyone needing to reclaim disk space or manage system drivers safely.

**Key Principles**:
- **Safety First**: All destructive operations require user confirmation
- **Admin Required**: Scripts auto-elevate to administrator privileges
- **Comprehensive**: Cover multiple cleanup targets and applications
- **User-Friendly**: Clear prompts and status messages throughout

---

## 📁 Repository Structure

```
UltraSystemScripts/
├── .git/                     # Git version control
├── .gitignore               # Ignored files (local settings, dev scripts)
├── UltraSweeper.bat         # Main disk cleanup script (~880 lines)
├── UltraDriverCleaner.bat   # Driver management script (~415 lines)
├── CONTRIBUTING.md          # This file (developer documentation)
└── README.md                # User-facing documentation (if exists)
```

---

## 🔍 Scripts Deep Dive

### 1. UltraSweeper.bat

**Purpose**: Comprehensive disk cleanup utility that recovers free space from various Windows and application caches.

**Size**: ~880 lines | **Version**: 2.0 (21-12-2025)

#### Execution Flow

```
START
  │
  ├── Check/Request Admin Privileges
  │
  ├── AUTOMATIC CLEANUP (no prompts)
  │   ├── Hibernation file removal
  │   ├── Print spooler cleanup
  │   ├── Font cache reset
  │   ├── Windows Update cache
  │   ├── System temp files
  │   ├── User profile temp files
  │   ├── Windows Store/UWP caches
  │   ├── Recycle Bin
  │   └── Application caches (iTunes, Teams, Outlook, Office)
  │
  ├── BROWSER CLEANUP (requires pause)
  │   ├── Internet Explorer
  │   ├── Google Chrome (all profiles)
  │   ├── Microsoft Edge (all profiles)
  │   ├── Edge WebView2
  │   └── Firefox
  │
  ├── DEVELOPER TOOLS (individual Y/N prompts)
  │   ├── npm cache
  │   ├── pip cache
  │   ├── Gradle cache
  │   ├── Docker system prune
  │   ├── NuGet cache
  │   ├── PowerShell modules
  │   ├── WSL caches
  │   ├── VS Code cache
  │   ├── Brave Browser cache
  │   ├── Chocolatey cache
  │   ├── Android SDK cache
  │   ├── Conda cache
  │   ├── GitHub Desktop cache
  │   ├── Messenger cache
  │   ├── Ollama cache (preserves models)
  │   ├── Playwright browsers
  │   ├── uv/Poetry cache
  │   ├── Zoom cache
  │   ├── Claude Desktop cache
  │   ├── Audacity temp
  │   ├── HandBrake logs
  │   ├── pgAdmin sessions
  │   ├── WinRAR cache
  │   ├── Rufus ISO cache
  │   ├── Everything search index
  │   ├── Avidemux temp
  │   └── Antigravity cache
  │
  ├── DISK CLEANUP MANAGER (cleanmgr)
  │   └── Configures registry and runs built-in cleanup
  │
  ├── RESTORE POINTS (optional with warning)
  │   └── Deletes all shadow copies
  │
  ├── PREVIOUS WINDOWS INSTALLS
  │   ├── Windows.old
  │   ├── $Windows.~BT
  │   └── $Windows.~WS
  │
  └── END (auto-detect laptop/desktop for hibernation)
```

#### Key Labels (Entry Points)

| Label | Line | Description |
|-------|------|-------------|
| `:checkPrivileges` | 10 | Admin elevation logic |
| `:STARTINTRO` | 20 | Script title and info |
| `:WindowsUpdatesCleanup` | 56 | Windows Update service cleanup |
| `:UserProfileCleanup` | 92 | User temp file cleanup |
| `:AggressiveWindowsCleanup` | 105 | UWP and Store caches |
| `:WEbBrowsers` | 204 | Browser cleanup section |
| `:DevelopmentToolsCleanup` | 318 | Developer cache prompt section |
| `:CLEANMGR` | 714 | Registry config + cleanmgr |
| `:RestorePointsCleaup` | 796 | Shadow copy deletion |
| `:detectchassis` | 849 | Laptop/Desktop auto-detection |

---

### 2. UltraDriverCleaner.bat

**Purpose**: Driver management utility with backup, cleanup, and restore capabilities.

**Size**: ~415 lines | **Version**: 2.0

#### Execution Flow

```
START
  │
  ├── Check/Request Admin Privileges
  │
  └── MAIN MENU
      │
      ├── [1] CLEANUP
      │   ├── List all third-party drivers (pnputil /enum-drivers)
      │   ├── Optional: Backup first
      │   └── Remove old OEM drivers
      │
      ├── [2] BACKUP
      │   └── Export all drivers to Desktop folder
      │
      ├── [3] RESTORE
      │   ├── Browse for backup folder
      │   ├── Select from recent backups
      │   ├── Restore ALL drivers
      │   │   ├── Add to store only
      │   │   └── Force install
      │   └── Restore specific driver by name
      │
      └── [4] EXIT
```

#### Key Labels (Entry Points)

| Label | Line | Description |
|-------|------|-------------|
| `:main` | 17 | Main menu display |
| `:cleanup` | 47 | Driver cleanup flow |
| `:backupOnly` | 109 | Backup all drivers |
| `:restore` | 141 | Restore center menu |
| `:restoreBrowse` | 168 | Manual path input |
| `:restoreRecent` | 188 | Find backups on Desktop |
| `:doRestoreAdd` | 279 | Add drivers to store |
| `:doRestoreInstall` | 298 | Force install drivers |
| `:restoreSpecific` | 358 | Restore single driver |

---

## 📝 Coding Conventions

### Naming

- **Labels**: Use `camelCase` for labels (e.g., `:myNewSection`)
- **Variables**: Use `UPPERCASE` for script-wide variables
- **Comments**: Use `::` for single-line comments, `REM` inside loops

### Structure

```batch
:SectionName
    :: Brief description of what this section does
    ECHO Descriptive message for user

    :: Actual command with error suppression
    command /args >nul 2>&1

    :: Next section or conditional jump
    goto NextSection
```

### Error Handling

Always suppress errors for optional cleanup targets:
```batch
DEL /S /Q /F "path\*.*" >nul 2>&1
RD /S /Q "path" >nul 2>&1
```

### User Prompts

Standard Y/N prompt pattern:
```batch
set /p varname=Prompt message [Y/N]?
if /I "%varname%" EQU "Y" goto yesLabel
if /I "%varname%" EQU "N" goto noLabel
```

### Multi-User Iteration

Always iterate over all user profiles:
```batch
For /d %%u in (c:\users\*) do (
    :: Access paths using %%u\AppData\...
    DEL /S /Q /F "%%u\AppData\Local\SomeApp\Cache\" >nul 2>&1
)
```

---

## ➕ Adding New Features

### Adding a New Cleanup Target to UltraSweeper

1. **Choose the appropriate section**:
   - Automatic cleanup → Add near line 100-200
   - Prompted cleanup → Add near line 700 (before `:CLEANMGR`)

2. **Follow this template for prompted cleanup**:

```batch
:myAppCleanupPrompt
    set /p myapp=Do you wish to delete MyApp cache? (Safe, description) [Y/N]?
    if /I "%myapp%" EQU "Y" goto myAppCleanup
    if /I "%myapp%" EQU "N" goto nextAppCleanupPrompt

:myAppCleanup
    ECHO Cleaning MyApp cache for all users
    For /d %%u in (c:\users\*) do (
        RD /S /Q "%%u\AppData\Local\MyApp\Cache" >nul 2>&1
        DEL /S /Q /F "%%u\AppData\Roaming\MyApp\*.log" >nul 2>&1
    )
    :: Fall through to next prompt or use goto
```

3. **Update the development tools echo banner** (line ~322) if adding dev tools

4. **Test on a VM first** before committing!

### Adding a New Menu Option to UltraDriverCleaner

1. Add option to main menu echo section (~line 29-35)
2. Add corresponding `if` statement (~line 38-42)
3. Create new label section with implementation
4. Ensure proper `goto main` for returning to menu

---

## 🧪 Testing Guidelines

### Before Committing

1. **Syntax Check**: Run script with `ECHO ON` temporarily
2. **Permission Test**: Verify admin elevation works
3. **Path Test**: Test on systems with different username formats
4. **Rollback Plan**: For destructive operations, test on VM first

### Test Scenarios

| Test | How |
|------|-----|
| Admin elevation | Run as non-admin, verify UAC prompt |
| User iteration | Test on system with multiple user profiles |
| Missing apps | Verify skips gracefully when app not installed |
| Cancel flow | Press N at every prompt, verify clean exit |

---

## 🔄 Common Patterns

### Pattern 1: Service Stop → Clean → Service Start

```batch
net stop servicename >nul 2>&1
DEL /S /Q /F "service\cache\*.*" >nul 2>&1
net start servicename >nul 2>&1
```

### Pattern 2: Kill Process → Clean

```batch
taskkill /F /IM appname.exe >nul 2>&1
For /d %%u in (c:\users\*) do (
    RD /S /Q "%%u\AppData\...\Cache" >nul 2>&1
)
```

### Pattern 3: Check Before Delete

```batch
IF EXIST "%path%" (
    takeown /F "%path%" /A /R /D Y >nul 2>&1
    icacls "%path%" /grant *S-1-5-32-544:F /T /C /Q >nul 2>&1
    RD /s /q "%path%" >nul 2>&1
)
```

### Pattern 4: Chrome/Edge Profile Iteration

```batch
SETLOCAL EnableDelayedExpansion
SET "dataDir=%%u\AppData\Local\App\User Data"
FOR /D %%A IN ("!dataDir!\Default" "!dataDir!\Profile *") DO (
    :: Clean profile-specific caches
)
ENDLOCAL
```

---

## 🌿 Git Workflow

### Commit Message Format

```
Type: Short description (max 50 chars)

- Detailed bullet point 1
- Detailed bullet point 2
```

**Types**:
- `Add` - New feature or cleanup target
- `Fix` - Bug fix
- `Update` - Modify existing functionality
- `Refactor` - Code restructure without behavior change
- `Docs` - Documentation only

### Branch Strategy

- `main` - Stable, tested code only
- `feature/xyz` - New features in development
- `fix/issue-name` - Bug fixes

### PR Checklist

- [ ] Tested on Windows 10/11
- [ ] Tested with admin elevation
- [ ] No hardcoded paths (use `%USERPROFILE%`, `%systemdrive%`, etc.)
- [ ] Error output suppressed (`>nul 2>&1`)
- [ ] User prompts are clear
- [ ] Comments explain non-obvious logic

---

## 🔧 Troubleshooting

### Script Won't Run

- Ensure Windows PowerShell execution allows scripts
- Right-click → Run as Administrator
- Check if antivirus is blocking

### Services Won't Restart

Some services are dependent on others. Check with:
```batch
sc query servicename
sc queryex type= service state= all | find "servicename"
```

### Variables Not Expanding

Enable delayed expansion for variables inside loops:
```batch
SETLOCAL EnableDelayedExpansion
:: Use !var! instead of %var% inside loops
ENDLOCAL
```

### Path Issues with Spaces

Always quote paths:
```batch
DEL /S /Q /F "%USERPROFILE%\Desktop\My Files\*.*"
```

---

## 📞 Contact & Contribution

**Maintainer**: Abhishek's AI Lab
**Repository**: UltraSystemScripts

For questions or suggestions, open an issue on GitHub!

---

*Last Updated: December 2025*
