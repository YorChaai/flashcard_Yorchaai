# 📋 PLAN 3.0 - Flashcard Layout Update

## 🎯 **Perubahan Utama:**

### **Konsep Baru:**
- **Kolom 1 (Excel Column A)** = Selalu menjadi **MAIN WORD** (font besar, tengah)
- **Kolom 2-6** = **EXTRA INFO** (font kecil, 1/4 ukuran dari kolom 1)
- **NO** tidak ditampilkan di flashcard (Excel row number otomatis jadi identifier)

---

## 📐 **New Flashcard Layout (2-6 Kolom):**

### **2 Kolom:**
```
┌──────────────────────────┐
│                          │
│        APPLE             │  ← Kolom 1 (32pt), besar, tengah
│                          │
│                          │
└──────────────────────────┘
```

### **3 Kolom:**
```
┌──────────────────────────┐
│        APPLE             │  ← Kolom 1 (32pt), besar, tengah
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│          noun            │  ← Kolom 2 (8pt), kecil, abu-abu, tengah
│                          │
└──────────────────────────┘
```

### **4 Kolom:**
```
┌──────────────────────────┐
│        APPLE             │  ← Kolom 1 (32pt), besar, tengah
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     noun    │   fruit    │  ← Kolom 2 & 3 (8pt), kecil, abu-abu
│                          │
└──────────────────────────┘
```

### **5 Kolom:**
```
┌──────────────────────────┐
│        APPLE             │  ← Kolom 1 (32pt), besar, tengah
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     noun    │   fruit    │  ← Kolom 2 & 3 (8pt), abu-abu
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│            red           │  ← Kolom 4 (8pt), kecil, abu-abu, tengah
│                          │
└──────────────────────────┘
```

### **6 Kolom:**
```
┌──────────────────────────┐
│        APPLE             │  ← Kolom 1 (32pt), besar, tengah
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     noun    │   fruit    │  ← Kolom 2 & 3 (8pt), abu-abu
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     red     │   ...      │  ← Kolom 4 & 5 (8pt), abu-abu
│                          │
└──────────────────────────┘
```

---

## 📊 **Font Size Rules:**

| Element | Font Size | Ratio |
|---------|-----------|-------|
| **Kolom 1 (Main Word)** | 32pt | 100% |
| **Kolom 2-6 (Extra Info)** | 8pt | 25% (1/4 dari kolom 1) |

**Formula:**
```dart
mainFontSize = 32.0
extraFontSize = mainFontSize / 4.0  // = 8.0
```

---

## 🔄 **Import Flow Update:**

### **New Flow:**
```
1. User klik "Import Dataset"
   ↓
2. User pilih file Excel
   ↓
3. Sistem AUTO-DETECT:
   - Jumlah kolom (max 6)
   - Nama file
   - Nama sheet
   - Total data rows
   ↓
4. Preview page muncul:
   ✅ File info (nama file, sheet, kolom)
   ✅ Total rows
   ✅ Preview 30 baris pertama & terakhir
   ↓
5. User klik "Import"
   ↓
6. Dialog input nama dataset
   ↓
7. Dataset tersimpan → Home
```

---

## 📦 **Data Structure Update:**

### **Card Model:**
```dart
Card {
  // NO FIELD (Excel row number implicit)
  col1: String,        // MAIN WORD (besar, tengah)
  col2: String?,       // Extra info 1 (kecil)
  col3: String?,       // Extra-info 2 (kecil)
  col4: String?,       // Extra-info 3 (kecil)
  col5: String?,       // Extra-info 4 (kecil)
  col6: String?,       // Extra-info 5 (kecil)
  columnCount: int,    // 2-6
  known: bool,
}
```

### **Excel Format Expected:**
```
Column A     | Column B | Column C | Column D | Column E | Column F
(Main Word)  | Extra 1  | Extra 2  | Extra 3  | Extra 4  | Extra 5
apple        | noun     | fruit    | red      | sweet    | Malus
banana       | noun     | fruit    | yellow   | tropical | Musa
```

---

## 🎨 **Preview Page Layout (Updated):**

```
┌──────────────────────────────────────────────────┐
│  ← Import Preview                                │
├──────────────────────────────────────────────────┤
│                                                  │
│  📄 File Information                             │
│  ┌────────────────────────────────────────────┐  │
│  │ • File Name: sample_vocabulary.xlsx        │  │
│  │ • Sheet Name: Data                         │  │
│  │ • Total Columns: 4                         │  │
│  │ • Total Data: 150 rows                     │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  📊 Column Structure                             │
│  ┌────────────────────────────────────────────┐  │
│  │ [1] Main Word  [2] Type  [3] Category      │  │
│  │ [4] Meaning                                 │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  👀 Data Preview (First 30 & Last 3 rows)       │
│  ┌────────────────────────────────────────────┐  │
│  │ Main Word  │ Type │ Category │ Meaning      │  │
│  ├────────────────────────────────────────────┤  │
│  │ apple      │ noun │ fruit    │ buah apel    │  │
│  │ banana     │ noun │ fruit    │ buah pisang  │  │
│  │ ... (148 more rows hidden) ...              │  │
│  │ umbrella   │ noun │ item     │ payung       │  │
│  │ violin     │ noun │ instrument│ biola       │  │
│  │ waterfall  │ noun │ nature   │ air terjun   │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
│  📈 Summary                                      │
│  Total rows to import: 150 cards                 │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │         [Cancel]      [Import Dataset]     │  │
│  └────────────────────────────────────────────┘  │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## 🛠️ **Files to Create/Modify:**

### **CREATE:**
1. ✨ `lib/screens/import_preview_screen.dart` - Full screen preview page

### **MODIFY:**
1. 🔄 `lib/screens/flashcard_screen.dart` - Update layout logic:
   - Remove `no` from display
   - Kolom 1 = main word (32pt)
   - Kolom 2-6 = extra info (8pt = 32/4)
2. 🔄 `lib/screens/home_screen.dart` - Simplify import flow
3. 🔄 `lib/services/excel_service.dart` - Add metadata & preview functions
4. 🔄 `lib/providers/app_providers.dart` - Auto-detect columns
5. 🔄 `lib/screens/deck_detail_screen.dart` - Update column labels

### **DELETE (optional):**
1. 🗑️ `lib/screens/column_selection_dialog.dart` - No longer needed

---

## 📐 **Layout Logic (Updated):**

```dart
Widget _buildCardBack(Card card) {
  final mainWord = card.col1;  // Kolom 1 = MAIN
  final extraCols = card.extraColumns;  // Kolom 2-6
  final mainFontSize = 32.0;
  final extraFontSize = mainFontSize / 4.0;  // = 8.0
  
  return Column(
    children: [
      // MAIN WORD (Kolom 1)
      Text(mainWord, style: TextStyle(fontSize: mainFontSize)),
      
      if (extraCols.isNotEmpty) ...[
        Divider(),
        // Layout extra cols based on count
        _buildExtraColumnsLayout(extraCols, extraFontSize),
      ],
    ],
  );
}

Widget _buildExtraColumnsLayout(List<String> extraCols, double fontSize) {
  int count = extraCols.length;
  
  if (count == 1) {
    // 2 kolom total: 1 extra
    return Text(extraCols[0], style: TextStyle(fontSize: fontSize));
  } else if (count == 2) {
    // 3 kolom total: 2 extras horizontal
    return Row(children: [
      Expanded(child: Text(extraCols[0])),
      Expanded(child: Text(extraCols[1])),
    ]);
  } else if (count == 3) {
    // 4 kolom total: 2 + 1 dengan divider
    return Column(children: [
      Row(children: [
        Expanded(child: Text(extraCols[0])),
        Expanded(child: Text(extraCols[1])),
      ]),
      Divider(),
      Text(extraCols[2]),
    ]);
  } else if (count >= 4) {
    // 5-6 kolom total: 2 + 2 dengan divider
    return Column(children: [
      Row(children: [
        Expanded(child: Text(extraCols[0])),
        Expanded(child: Text(extraCols[1])),
      ]),
      Divider(),
      Row(children: [
        Expanded(child: Text(extraCols[2])),
        Expanded(child: Text(extraCols[3])),
      ]),
      if (count == 5) Text(extraCols[4]),
    ]);
  }
}
```

---

## ✅ **Implementation Steps:**

### **Phase 1: Excel Service**
1. ✅ Add `getFileMetadata()` function
2. ✅ Add `getPreviewData()` function (first 29 + last 3 rows)

### **Phase 2: Preview Screen**
3. ✅ Create `ImportPreviewScreen` widget
4. ✅ Add file info card
5. ✅ Add column structure display
6. ✅ Add data preview table with skip indicator

### **Phase 3: Flashcard Layout**
7. ✅ Update `flashcard_screen.dart`:
   - Remove `no` display
   - Kolom 1 = main word (32pt)
   - Kolom 2-6 = extra info (8pt)
   - Update divider logic

### **Phase 4: Simplify Import Flow**
8. ✅ Remove column selection dialog
9. ✅ Update HomeScreen import flow
10. ✅ Add auto-detect columns logic

### **Phase 5: Testing**
11. ✅ Test all column counts (2-6)
12. ✅ Test preview page with large files
13. ✅ Test flashcard display
14. ✅ Build & verify

---

## 📝 **Notes:**

1. **Font ratio 1:4** - Main word 4x larger than extra info
2. **No number display** - Excel row number implicit, not shown on card
3. **Kolom 1 selalu utama** - Regardless of content type
4. **Max 6 kolom** - Excel columns beyond 6 will be ignored
5. **Preview page** - Shows 30 rows max (29 first + last 3 with skip indicator)

---

**Ready for implementation!** 🚀
