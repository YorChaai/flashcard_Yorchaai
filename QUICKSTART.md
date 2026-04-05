# YorFlashCard - Quick Start Guide

## 🚀 Run the App

```bash
cd "D:\2. Organize\1. Projects\flashcard"
flutter run -d windows
```

## 📦 Sample Data

A sample Excel file (`sample_vocabulary.xlsx`) with 50 English words has been created for testing.

## 📋 Excel File Format

Your Excel file MUST have this format:

| Column A | Column B |
|----------|----------|
| no       | kata     |
| 1        | apple    |
| 2        | banana   |
| 3        | cherry   |

**Important:**
- First row = headers (will be skipped)
- Column A = numbers only
- Column B = text (words to memorize)

## 🎯 User Flow

1. **Open app** → See empty dataset list
2. **Click "Import Dataset"** → Select Excel file
3. **Click on imported dataset** → Configure settings
4. **Set number range** (e.g., 1-30)
5. **Choose order mode**:
   - Normal (1, 2, 3, 4, 5...)
   - Reverse (5, 4, 3, 2, 1...)
   - Random (shuffled)
6. **Click "Start Learning"**
7. **Study flashcards**:
   - Tap card → Flip to see answer
   - Click ✅ Know / ❌ Don't Know
   - Navigate with Next/Previous buttons
8. **View results** → See your statistics

## 🎮 Controls

### Flashcard Screen
- **Tap card** → Flip between front (number) and back (word)
- **✅ Know** → Mark card as known (green)
- **❌ Don't Know** → Mark card as unknown (red)
- **← Previous** → Go to previous card
- **Next →** → Go to next card
- **📊 (top right)** → View statistics

### Home Screen
- **⋮ (menu)** → Rename or Delete dataset
- **Tap dataset** → Open learning configuration
- **+ Import Dataset** → Add new Excel file

## ⚙️ Build Commands

### Development
```bash
flutter run              # Run on connected device/emulator
flutter run -d windows   # Run on Windows
flutter run -d chrome    # Run in browser
```

### Production Build
```bash
flutter build windows    # Windows executable
flutter build apk        # Android APK
flutter build ios        # iOS app
```

The built app is located at:
- Windows: `build\windows\x64\runner\Release\yor_flashcard.exe`
- Android: `build\app\outputs\flutter-apk\app-release.apk`

## 🔧 Troubleshooting

### "No valid data found in Excel file"
- Check that your Excel file has 2 columns
- Ensure column A contains numbers
- Ensure column B contains text
- Remove any merged cells or formatting

### Import button not working
- Make sure you're using a real Excel file (.xlsx or .xls)
- Try restarting the app
- Check file permissions

### Data not saving
- Data is saved locally on your device
- Don't clear app data/cache
- Data persists between app restarts

## 📱 Supported Platforms

✅ Windows  
✅ Android  
✅ iOS  
✅ Web  
✅ macOS  
✅ Linux  

## 🎨 Customization

To change the app theme, edit `lib/main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF4A90E2),  // Change this color
  brightness: Brightness.light,
),
```

## 📊 Features Implemented

✅ Import Excel files  
✅ Multiple datasets support  
✅ Rename/Delete datasets  
✅ Number range filtering  
✅ 3 order modes (Normal, Reverse, Random)  
✅ Flashcard with flip animation  
✅ Mark cards as Know/Don't Know  
✅ Progress tracking  
✅ Statistics display  
✅ Local storage (offline)  
✅ Clean, modern UI  

## ❌ NOT Implemented (as per spec)

- AI features
- Login/Authentication
- Cloud sync
- Multiplayer
- Spaced repetition
- Audio/Images

---

**Ready to use! Open the app and start learning! 🎓**
