# 📋 PLAN - Fix Column Structure Chip Colors

## 🎯 **Masalah yang Ditemukan:**

### 1. **Light Mode**
- Chip Kolom 1 (`[1] kata`) punya background **biru** (primary color opacity).
- Chip Kolom 2-4 (`[2] arti`, dll) background **putih/abu**.
- **Solusi**: Semua chip harusnya **Putih** dengan teks **Hitam** agar seragam.

### 2. **Dark Mode**
- Chip Kolom 1 sudah benar (Hitam).
- Chip Kolom 2-4 background **Putih/Abu terang** (tidak jelas/nyilauin di dark mode).
- **Solusi**: Semua chip harusnya **Hitam/Gelap** dengan teks **Putih** agar seragam.

---

## 🔧 **Perubahan yang Akan Dilakukan:**

### **File: `lib/screens/import_preview_screen.dart`**

#### **Metode: `_buildColumnStructureCard`**
Cari bagian `Wrap` yang me-render `Chip`. Hapus logika `index == 0` yang memberikan warna berbeda ke kolom pertama.

**Before (Salah):**
```dart
backgroundColor: index == 0
    ? Theme.of(context).primaryColor.withValues(alpha: 0.2) // Biru di light mode
    : Colors.grey[200], // Abu di light mode, tapi putih di dark mode?
```

**After (Benar):**
```dart
// Variabel di awal build method:
final isDark = Theme.of(context).brightness == Brightness.dark;

// Di dalam Chip:
Chip(
  backgroundColor: isDark ? Colors.grey[900] : Colors.white, // Konsisten
  label: Text(
    '[${entry.key + 1}] ${entry.value}',
    style: TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white : Colors.black, // Teks kontras
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

---

## 📐 **Visual Target (After Fix):**

### **Light Mode:**
```
┌──────────────────────────────────────┐
│ 📊 Column Structure                  │
│ ┌──────┐ ┌────── ┌──────┐ ──────┐ │
│ │[1]kta│ │[2]art│ │[3] ip│ │[4]typ│ │  ← Semua Putih, Teks Hitam
│ └──────┘ └──────┘ └──────┘ └──────┘ │
└──────────────────────────────────────┘
```

### **Dark Mode:**
```
┌──────────────────────────────────────┐
│  Column Structure                  │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │[1]kta│ │[2]art│ │[3] ip│ │[4]typ│ │  ← Semua Hitam/Abu Gelap, Teks Putih
│ └────── └──────┘ ──────┘ └──────┘ │
└──────────────────────────────────────┘
```

---

## ✅ **Checklist Implementasi:**

- [ ] Buka `lib/screens/import_preview_screen.dart`.
- [ ] Temukan fungsi `_buildColumnStructureCard`.
- [ ] Hapus kondisi `index == 0` pada properti `backgroundColor`.
- [ ] Set `backgroundColor` statis:
    - Light Mode: `Colors.white`
    - Dark Mode: `Colors.grey[800]` atau `Colors.black`
- [ ] Set `labelStyle` (warna teks):
    - Light Mode: `Colors.black`
    - Dark Mode: `Colors.white`
- [ ] Test di Light Mode & Dark Mode.
- [ ] Flutter analyze & build verification.

---

**Estimasi:** 5 menit coding + testing 🚀
