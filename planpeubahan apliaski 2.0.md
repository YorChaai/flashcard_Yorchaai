📋 **PLAN - Dynamic Multi-Column Flashcard (2-6 Kolom)**

## **1. Perubahan Struktur Data**

### **Model Card (Update)**
```dart
Card {
  no: number,
  col1: string,        // Kolom utama (kata)
  col2: string?,       // Opsional
  col3: string?,       // Opsional
  col4: string?,       // Opsional
  col5: string?,       // Opsional
  col6: string?,       // Opsional
  columnCount: number  // 2, 3, 4, 5, atau 6
}
```

### **Model Deck (Update)**
```dart
Deck {
  id: string,
  name: string,
  columnCount: number,    // 2-6
  columnHeaders: string[], // Nama header tiap kolom
  cards: Card[]
}
```

---

## **2. User Flow Import (UPDATE TOTAL)**

### **Step-by-Step:**

```
1. User klik "Import Dataset"
   ↓
2. User PILIH JUMLAH KOLOM (Dialog)
   "Berapa kolom yang mau dipakai?"
   [2] [3] [4] [5] [6]
   ↓
3. User pilih file Excel
   ↓
4. Sistem VALIDASI kolom di Excel
   ↓
5. Jika TIDAK SESUAI:
   ❌ "File harus memiliki X kolom, tapi ditemukan Y kolom"
   → Retry atau Cancel
   
   Jika SESUAI:
   ✅ Tampilkan preview 3 baris pertama
   → "Data sesuai, lanjutkan?"
   ↓
6. User input NAMA DATASET
   ↓
7. Data tersimpan & tampil di Home
```

---

## **3. Layout Flashcard Berdasarkan Jumlah Kolom**

### **2 Kolom:**
```
┌──────────────────────────┐
│                          │
│        APPLE             │  ← Besar (32pt), tengah
│                          │
└──────────────────────────┘
```

### **3 Kolom:**
```
┌──────────────────────────┐
│                          │
│        APPLE             │  ← Besar (32pt), tengah
│        noun              │  ← Kecil (14pt), abu-abu
│                          │
└──────────────────────────┘
```

### **4 Kolom:**
```
┌──────────────────────────┐
│        APPLE             │  ← Besar (28pt), tengah
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     noun    │   fruit    │  ← Kecil (12pt), abu-abu
│                          │
└──────────────────────────┘
```

### **5 Kolom:**
```
┌──────────────────────────┐
│        APPLE             │  ← Besar (26pt), tengah
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     noun    │   fruit    │  ← Kecil (11pt), abu-abu
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│            red           │  ← Kecil (11pt), abu-abu, tengah
│                          │
└──────────────────────────┘
```

### **6 Kolom:**
```
┌──────────────────────────┐
│        APPLE             │  ← Besar (24pt), tengah
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     noun    │   fruit    │  ← Kecil (10pt), abu-abu
│  ──────────────────────  │  ← Garis hitam, opacity 50%
│     red     │   ...      │  ← Kecil (10pt), abu-abu
│                          │
└──────────────────────────┘
```

**Garis Pemisah:**
- Warna: hitam dengan opacity 50% (`Colors.black.withValues(alpha: 0.5)`)
- Thickness: 1px
- Horizontal divider setelah kolom utama
- Vertical divider (`|`) antar kolom tambahan

---

## **4. Home Screen (UPDATE)**

### **Tampilan Dataset List:**
```
┌──────────────────────────────────────┐
│  YorFlashCard              [+Import] │
├──────────────────────────────────────┤
│                                      │
│  📘 Bahasa Inggris 1         [⋮]    │
│     50 cards | 2 kolom               │
│                                      │
│  📘 JLPT N5                  [⋮]    │
│     100 cards | 4 kolom              │
│                                      │
│  📘 Kosakata Medis           [⋮]    │
│     200 cards | 6 kolom              │
│                                      │
└──────────────────────────────────────┘
```

**Info per dataset:**
- Nama dataset
- Jumlah cards
- **Jumlah kolom** (NEW)

---

## **5. Dataset Detail Screen (UPDATE)**

### **Tambah Info:**
```
┌──────────────────────────────────────┐
│  ← Bahasa Inggris 1                  │
├──────────────────────────────────────┤
│                                      │
│  📊 Info Dataset                     │
│  • Total Cards: 50                   │
│  • Jumlah Kolom: 2                   │  ← NEW
│  • Kolom 1: no                       │  ← NEW (header names)
│  • Kolom 2: kata                     │  ← NEW
│                                      │
│  ────────────────────────────────    │
│                                      │
│  Number Range                        │
│  [Start No]      [End No]            │
│                                      │
│  Order Mode                          │
│  ○ Normal  ○ Reverse  ○ Random       │
│                                      │
│  [  START LEARNING  ]                │
│                                      │
└──────────────────────────────────────┘
```

---

## **6. File yang Perlu Dibuat/Dimodifikasi**

### **New Files:**
1. `lib/screens/column_selection_dialog.dart` - Dialog pilih jumlah kolom
2. `lib/screens/validation_preview_dialog.dart` - Preview & validasi data
3. `lib/widgets/dynamic_flashcard.dart` - Widget flashcard dinamis

### **Modified Files:**
1. `lib/models/card.dart` - Tambah field col2-col6, columnCount
2. `lib/models/deck.dart` - Tambah field columnCount, columnHeaders
3. `lib/services/excel_service.dart` - Logic parsing dinamis (2-6 kolom)
4. `lib/providers/app_providers.dart` - Update state management
5. `lib/screens/home_screen.dart` - Tampilkan info jumlah kolom
6. `lib/screens/deck_detail_screen.dart` - Tambah info kolom
7. `lib/screens/flashcard_screen.dart` - Layout dinamis berdasarkan columnCount
8. `lib/screens/result_screen.dart` - No change

---

## **7. Validasi Excel**

### **Logic:**
```dart
// Saat user pilih 4 kolom
if (excel.columns < 4) {
  showError("File hanya memiliki 3 kolom, tapi Anda memilih 4 kolom");
  return false;
}

// Preview 3 baris pertama
showPreview(rows[0..2]);

// User konfirmasi → lanjut input nama dataset
```

---

## **8. Urutan Implementasi**

### **Phase 1: Data Model & Services** (Backend)
1. ✅ Update Card model (col2-col6, columnCount)
2. ✅ Update Deck model (columnCount, columnHeaders)
3. ✅ Update ExcelService (parsing dinamis 2-6 kolom)
4. ✅ Update StorageService (no breaking change)

### **Phase 2: Import Flow** (UI)
5. ✅ Buat ColumnSelectionDialog
6. ✅ Buat ValidationPreviewDialog
7. ✅ Update HomeScreen import flow

### **Phase 3: Display** (UI)
8. ✅ Update HomeScreen (tampilkan jumlah kolom)
9. ✅ Update DeckDetailScreen (tampilkan info kolom)
10. ✅ Buat DynamicFlashcardWidget

### **Phase 4: Flashcard Layout** (UI + Animation)
11. ✅ Update FlashcardScreen (layout dinamis)
12. ✅ Tambah garis pemisah (horizontal + vertical)
13. ✅ Test semua skenario (2,3,4,5,6 kolom)

### **Phase 5: Testing**
14. ✅ Buat sample Excel (2,3,4,5,6 kolom)
15. ✅ Test import & validasi
16. ✅ Test flashcard display
17. ✅ Build & verify

---

## **9. Sample Excel yang Perlu Dibuat**

Saya akan bikin 5 sample files:
- `sample_2columns.xlsx` - no, kata
- `sample_3columns.xlsx` - no, kata, type
- `sample_4columns.xlsx` - no, kata, type, meaning
- `sample_5columns.xlsx` - no, kata, type, meaning, example
- `sample_6columns.xlsx` - no, kata, type, meaning, example, synonym

---

## **10. Breaking Changes**

⚠️ **Data lama (deck yang sudah ada) akan tetap works** karena:
- `columnCount` default ke 2 jika null
- `col2-col6` nullable
- Backward compatible dengan data existing

---

## **11. Estimasi Kompleksitas**

| Task | Kompleksitas |
|------|--------------|
| Update Models | 🟢 Easy |
| Excel Parsing | 🟡 Medium |
| Column Selection Dialog | 🟢 Easy |
| Validation Preview | 🟡 Medium |
| Dynamic Flashcard Layout | 🟠 Complex |
| Testing All Scenarios | 🟡 Medium |

---

## **❓ Pertanyaan Final (Sebelum Mulai):**

1. **Untuk kolom ke-2 sampai ke-6**, apakah nama header di Excel harus spesifik? Atau bebas (user bisa kasih nama apa saja)?
   
   Contoh:
   ```
   no | kata   | type | meaning | example    | synonym
   1  | apple  | noun | buah    | I eat...   | fruit
   ```
   
   Atau harus:
   ```
   no | col1 | col2 | col3 | col4 | col5
   1  | apple | noun | ...  | ...  | ...
   ```

2. **Garis pemisah vertikal** (`|`) antar kolom kecil:
   - Apakah warnanya hitam opacity 50% juga?
   - Atau abu-abu biasa?

3. **Ukuran font** untuk kolom kecil (col2-col6):
   - Apakah semua sama (misal 12pt)?
   - Atau col2 sedikit lebih besar dari col3-col6?

---

**Tolong jawab 3 pertanyaan ini, baru saya mulai coding!** 🚀
