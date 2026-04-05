# YorFlashCard - Flashcard Learning App

A Flutter-based flashcard application that allows you to import vocabulary datasets from Excel files and study them with various learning modes.

## Features

✅ **Multi-Dataset Support** - Import and manage multiple Excel datasets  
✅ **Number Range Filtering** - Study specific number ranges (e.g., 1-30, 31-60)  
✅ **Three Order Modes**:
  - **Normal** - Ascending order by number
  - **Reverse** - Descending order by number  
  - **Random** - Shuffled order
✅ **Interactive Flashcards** - One card at a time with flip animation
✅ **Progress Tracking** - Mark cards as "Know" or "Don't Know"
✅ **Statistics** - View learning progress and results
✅ **Dataset Management** - Rename and delete datasets
✅ **Local Storage** - All data saved locally for offline use

## Project Structure

```
lib/
├── models/
│   ├── card.dart          # Card data model
│   ├── deck.dart          # Deck dataset model
│   └── order_mode.dart    # Order mode enum
├── providers/
│   └── app_providers.dart # State management (Deck & LearningSession)
├── screens/
│   ├── home_screen.dart           # Dataset list & import
│   ├── deck_detail_screen.dart    # Range filter & mode selection
│   ├── flashcard_screen.dart      # Flashcard display
│   └── result_screen.dart         # Learning statistics
├── services/
│   ├── storage_service.dart       # Local storage (SharedPreferences)
│   └── excel_service.dart         # Excel file parsing
├── widgets/               # Custom widgets (if needed)
└── main.dart            # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (3.38.9 or higher)
- Dart SDK (3.10.8 or higher)
- Windows/Mac/Linux for development
- Android/iOS device or emulator for testing

### Installation

1. **Clone or download the project**
   ```bash
   cd "D:\2. Organize\1. Projects\flashcard"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Windows:**
```bash
flutter build windows
```

**Android:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

## How to Use

### 1. Import a Dataset

- Click the **"Import Dataset"** button
- Select an Excel file (`.xlsx` or `.xls`)
- The file **MUST** have exactly 2 columns:
  - Column A: `no` (number)
  - Column B: `kata` (word/text)

**Example Excel format:**

| no | kata     |
|----|----------|
| 1  | apple    |
| 2  | banana   |
| 3  | cherry   |

### 2. Configure Learning Session

After importing, click on a dataset to configure:

- **Number Range**: Set start and end numbers (e.g., 1-30)
- **Order Mode**: Choose Normal, Reverse, or Random
- Click **"Start Learning"**

### 3. Study with Flashcards

- **Tap the card** to flip and reveal the answer
- **Know** ✅ - Mark as known (green button)
- **Don't Know** ❌ - Mark as unknown (red button)
- **Next/Previous** - Navigate between cards
- **Chart icon** (top right) - View statistics

### 4. View Results

After completing all cards, you'll see:
- Total cards studied
- Number of known cards
- Number of unknown cards
- Success percentage

You can:
- Return **Home** to select another dataset
- **Review Again** to restart the session

## Dataset Management

### Rename a Dataset
- Click the **⋮** menu on any dataset
- Select **"Rename"**
- Enter new name and save

### Delete a Dataset
- Click the **⋮** menu on any dataset
- Select **"Delete"**
- Confirm deletion

## Dependencies

- **provider** (^6.1.2) - State management
- **excel** (^4.0.6) - Excel file parsing
- **file_picker** (^8.1.2) - File selection
- **shared_preferences** (^2.3.3) - Local data storage
- **uuid** (^4.5.1) - Unique ID generation

## File Format Requirements

### Excel File (.xlsx)

**Required format:**
- First row: Headers (any text, will be skipped)
- Column A: Numbers (card numbers)
- Column B: Text (words/phrases to memorize)

**Example:**
```
no  | kata
----|--------
1   | apple
2   | banana
3   | cherry
```

## Troubleshooting

### App doesn't import Excel file
- Ensure the file has `.xlsx` or `.xls` extension
- Verify the file has at least 2 columns with data
- Check that numbers in column A are valid integers

### Cards not showing
- Verify the number range includes existing card numbers
- Check if the dataset has cards imported correctly

### Data lost after restart
- Data is saved locally on your device
- Ensure you're not clearing app data/cache
- Data persists across app restarts

## Future Enhancements (Not in v1)

- AI-powered learning recommendations
- Cloud sync across devices
- User authentication
- Multiplayer/competition modes
- Spaced repetition algorithm
- Audio pronunciation
- Image support for visual flashcards

## License

This project is for personal/educational use.

## Support

For issues or questions, please check:
- Flutter documentation: https://docs.flutter.dev/
- Package documentation on pub.dev

---

**Built with Flutter** ❤️
