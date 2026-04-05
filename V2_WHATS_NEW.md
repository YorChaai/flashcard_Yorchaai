# 🎉 YorFlashCard 2.0 - What's New

## ✅ **FITUR BARU YANG SUDAH DITAMBAHKAN:**

### 1. **Dynamic Columns (2-6 Kolom)**
- ✅ Bisa import Excel dengan **2, 3, 4, 5, atau 6 kolom**
- ✅ User dipilih jumlah kolom sebelum import
- ✅ Validasi otomatis: jika kolom tidak sesuai → error message
- ✅ Preview data sebelum import

### 2. **Dark/Light Theme**
- ✅ Toggle tema di pojok kanan atas (icon ☀️/🌙)
- ✅ Tema tersimpan otomatis
- ✅ Support Dark Mode & Light Mode

### 3. **Layout Flashcard Dinamis**

#### **2 Kolom:**
```
┌─────────────────┐
│                 │
│     APPLE       │  ← Besar (32pt)
│                 │
└─────────────────┘
```

#### **3 Kolom:**
```
┌─────────────────┐
│     APPLE       │  ← Besar (32pt)
│      noun       │  ← Kecil (14pt), abu-abu
└─────────────────┘
```

#### **4 Kolom:**
```
┌─────────────────┐
│     APPLE       │  ← Besar (28pt)
│ ─────────────── │  ← Garis hitam 50%
│  noun  │ fruit  │  ← Kecil (12pt), abu-abu
└─────────────────┘
```

#### **5 Kolom:**
```
┌─────────────────┐
│     APPLE       │  ← Besar (26pt)
│ ─────────────── │  ← Garis hitam 50%
│  noun  │ fruit  │  ← Baris 1 (11pt)
│ ─────────────── │  ← Garis hitam 50%
│       red       │  ← Baris 2, tengah (11pt)
└─────────────────┘
```

#### **6 Kolom:**
```
┌─────────────────┐
│     APPLE       │  ← Besar (24pt)
│ ─────────────── │  ← Garis hitam 50%
│  noun  │ fruit  │  ← Baris 1 (10pt)
│ ─────────────── │  ← Garis hitam 50%
│  red   │ ...    │  ← Baris 2 (10pt)
└─────────────────┘
```

### 4. **Home Screen Update**
- ✅ Tampil jumlah kolom per dataset (contoh: "50 cards | 4 columns")
- ✅ Tampil nama header kolom di Dataset Detail
- ✅ Icon theme toggle di AppBar

### 5. **Import Flow Baru**
```
1. Klik "Import Dataset"
   ↓
2. Pilih jumlah kolom (2/3/4/5/6)
   ↓
3. Pilih file Excel
   ↓
4. Validasi otomatis:
   ❌ Jika kolom tidak sesuai → error
   ✅ Jika sesuai → preview 3 baris pertama
   ↓
5. Input nama dataset
   ↓
6. Tersimpan!
```

---

## 📦 **Sample Excel Files**

Sudah disiapkan 5 sample files untuk testing:

| File | Kolom | Contoh Isi |
|------|-------|------------|
| `sample_2columns.xlsx` | no, kata | 1, apple |
| `sample_3columns.xlsx` | no, kata, type | 1, apple, noun |
| `sample_4columns.xlsx` | no, kata, type, meaning | 1, apple, noun, buah apel |
| `sample_5columns.xlsx` | no, kata, type, meaning, example | 1, apple, noun, buah apel, I eat an apple |
| `sample_6columns.xlsx` | no, kata, type, meaning, example, synonym | 1, apple, noun, buah apel, I eat an apple, fruit |

---

## 🚀 **Cara Menjalankan:**

### Windows:
```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter run -d windows
```

### Langsung buka executable:
```bash
cd "D:\2. Organize\1. Projects\flashcard" && build\windows\x64\runner\Release\yor_flashcard.exe
```

### Android:
```bash
cd "D:\2. Organize\1. Projects\flashcard" && flutter run -d android
```

---

## 📁 **File Structure (Update):**

```
lib/
├── models/
│   ├── card.dart              ✅ UPDATED (col1-col6, columnCount)
│   ├── deck.dart              ✅ UPDATED (columnCount, columnHeaders)
│   └── order_mode.dart
├── providers/
│   ├── app_providers.dart     ✅ UPDATED (dynamic column support)
│   └── theme_provider.dart    ✨ NEW (dark/light theme)
├── screens/
│   ├── home_screen.dart       ✅ UPDATED (theme toggle, new import flow)
│   ├── deck_detail_screen.dart ✅ UPDATED (show column info)
│   ├── flashcard_screen.dart   ✅ UPDATED (dynamic layout 2-6 columns)
│   ├── result_screen.dart
│   ├── column_selection_dialog.dart   ✨ NEW
│   └── validation_preview_dialog.dart ✨ NEW
├── services/
│   ├── storage_service.dart
│   └── excel_service.dart     ✅ UPDATED (parse 2-6 columns)
└── main.dart                  ✅ UPDATED (theme support)
```

---

## 🎨 **Theme Support:**

### Light Theme:
- Background: White
- Card: White with shadow
- Text: Dark

### Dark Theme:
- Background: #121212 (Dark gray)
- Card: Dark gray with shadow
- Text: Light

**Toggle:** Klik icon ☀️/🌙 di pojok kanan atas

---

## 📊 **Backward Compatibility:**

✅ **Data lama tetap works!**
- Dataset yang sudah ada tidak perlu di-import ulang
- `columnCount` default ke 2 jika null
- Semua fitur baru bersifat additive (tidak breaking)

---

## ✨ **Testing Checklist:**

- [ ] Import file 2 kolom
- [ ] Import file 3 kolom
- [ ] Import file 4 kolom
- [ ] Import file 5 kolom
- [ ] Import file 6 kolom
- [ ] Test validasi error (kolom tidak sesuai)
- [ ] Test preview sebelum import
- [ ] Test dark/light theme toggle
- [ ] Test flashcard display untuk semua layout
- [ ] Test garis pemisah di 4, 5, 6 kolom
- [ ] Test rename/delete dataset
- [ ] Test filter range
- [ ] Test mode urutan (normal/reverse/random)
- [ ] Test statistik

---

## 🎯 **Next Steps (Optional):**

Fitur yang bisa ditambahkan nanti:
- [ ] Export dataset ke Excel
- [ ] Edit card individual
- [ ] Add/delete card manual
- [ ] Spaced repetition algorithm
- [ ] Search/filter cards dalam dataset
- [ ] Bookmark cards favorit

---

**YorFlashCard 2.0 is READY!** 🚀

Built with ❤️ using Flutter
