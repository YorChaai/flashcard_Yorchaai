# 🚀 Cara Jalankan YorFlashCard v3.0

---

## 🖥️ WINDOWS

### 📌 Opsi 1: Development Mode (Paling Umum)

```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter run -d windows
```

### 📦 Opsi 2: Build Release + Jalankan

```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter build windows --release && build\windows\x64\runner\Release\yor_flashcard.exe
```

### ⚡ Opsi 3: Langsung Buka Executable (Sudah Dibuild)

```bash
cd "D:\2. Organize\1. Projects\flashcard" && build\windows\x64\runner\Release\yor_flashcard.exe
```

### 📂 Lokasi File Release Windows:
```
D:\2. Organize\1. Projects\flashcard\build\windows\x64\runner\Release\yor_flashcard.exe
```

---

## 📱 ANDROID

### 📌 Opsi 1: Run via USB/Emulator (Development Mode)

```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter run -d android
```

**Sebelum run:**
- Hubungkan HP via USB
- Aktifkan **USB Debugging** di Developer Options
- Atau buka emulator Android dulu

### 📦 Opsi 2: Build APK Release (Untuk Install di HP)

```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter build apk --release
```

**Hasil APK ada di:**
```
D:\2. Organize\1. Projects\flashcard\build\app\outputs\flutter-apk\app-release.apk
```

**Cara install ke HP:**
1. Copy APK ke HP
2. Buka file APK di HP
3. Install (izinkan "Install from Unknown Sources" jika diminta)

### ⚡ Opsi 3: Build + Install Langsung ke HP

```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter build apk --release && flutter install
```

### 📂 Lokasi File Release Android:
```
D:\2. Organize\1. Projects\flashcard\build\app\outputs\flutter-apk\app-release.apk
```

---

## 🌐 WEB (Opsional)

### Development:
```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter run -d chrome
```

### Build Release:
```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter build web --release
```

**Hasil build ada di:**
```
D:\2. Organize\1. Projects\flashcard\build\web\
```

---

## 📋 Test Import Sample Data

Setelah app terbuka:

1. Klik **"Import Dataset"**
2. Pilih file: `D:\2. Organize\1. Projects\flashcard\sample_vocabulary.xlsx`
3. Klik dataset yang muncul
4. Set range (default: 1-50)
5. Pilih mode (Normal/Reverse/Random)
6. Klik **"Start Learning"**

---

## 🎯 Command Cepat (Copy-Paste)

### Windows (Development):
```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter run -d windows
```

### Android (Development):
```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter run -d android
```

### Windows (Release - Langsung Buka):
```bash
cd "D:\2. Organize\1. Projects\flashcard" && build\windows\x64\runner\Release\yor_flashcard.exe
```

### Android (Build Release):
```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter build apk --release
```

---

## ✅ Status Build Terakhir:

| Platform | Status | Lokasi File |
|----------|--------|-------------|
| **Windows** | ✅ Built | `build\windows\x64\runner\Release\yor_flashcard.exe` |
| **Android** | ⏳ Belum build | `build\app\outputs\flutter-apk\app-release.apk` |
| **Web** | ⏳ Belum build | `build\web\` |

---

## 🔧 Troubleshooting

### Windows Build Error:
```bash
flutter clean && flutter pub get && flutter build windows --release
```

### Android Build Error:
```bash
flutter clean && flutter pub get && flutter build apk --release
```

### App Not Opening:
- Pastikan Flutter SDK terinstall
- Cek `flutter doctor` untuk dependencies
- Restart terminal/IDE

---

**Selesai!** 🎓
