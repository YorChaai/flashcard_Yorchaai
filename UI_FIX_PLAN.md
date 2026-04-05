# 📋 PLAN - UI Fix: Stats Card & Button Consistency

## 🎯 **Masalah yang Ditemukan:**

### 1. **Stats Card Terlalu Gelap (Dark Mode)**
- Background card stats (Datasets & Total Cards) warna hitam/abu gelap
- Text jadi kurang kontras dan susah dibaca
- **Solusi**: Beri background putih/terang atau border yang lebih jelas di dark mode

### 2. **Button Tidak Konsisten**
- "START LEARNING" = Filled button (background abu-abu gelap)
- "IMPORT DATASET" & "SETTINGS" = Outlined button (border saja)
- **Solusi**: Samakan style ketiganya (semanya filled atau semua outlined dengan warna sama)

---

## 🔧 **Perubahan yang Akan Dilakukan:**

### **File: `lib/screens/home_screen.dart`**

#### **1. Stats Card - Tambah Border & Background Terang di Dark Mode**
```dart
Card(
  color: Theme.of(context).brightness == Brightness.dark 
      ? Colors.grey[800]  // Abu-abu terang di dark mode
      : null,             // Default di light mode
  child: Padding(
    // ... existing content ...
  ),
)
```

#### **2. Button Konsistensi - Semuanya Filled dengan Warna Sama**
```dart
// START LEARNING (Primary Button)
ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor, // Warna utama aplikasi
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 20),
  ),
  // ...
)

// IMPORT DATASET (Secondary Button - Outlined)
OutlinedButton.icon(
  style: OutlinedButton.styleFrom(
    foregroundColor: Theme.of(context).primaryColor, // Warna teks sama dengan primary
    side: BorderSide(color: Theme.of(context).primaryColor), // Border warna sama
    padding: const EdgeInsets.symmetric(vertical: 16),
  ),
  // ...
)

// SETTINGS (Tertiary Button - Text Only atau Outlined tipis)
TextButton.icon(
  style: TextButton.styleFrom(
    foregroundColor: Colors.grey[600], // Lebih subtle
    padding: const EdgeInsets.symmetric(vertical: 16),
  ),
  // ...
)
```

---

## 📐 **Visual Target:**

### **Stats Card (After Fix):**
```
┌────────────────────────────┐  ← Border jelas / Background abu terang
│  📁          📚            │
│   1          9440          │  ← Text putih/kontras tinggi
│ Datasets    Total Cards    │
└────────────────────────────┘
```

### **Button Hierarchy (After Fix):**
```
┌────────────────────────────┐
│  ▶ START LEARNING          │  ← Filled, warna primary (biru)
├────────────────────────────┤
│  📥 IMPORT DATASET         │  ← Outlined, border primary
├────────────────────────────┤
│  ⚙️ SETTINGS               │  ← Text/Outlined tipis, warna abu
└────────────────────────────┘
```

---

## ✅ **Checklist Implementasi:**

- [ ] Stats Card: Tambah conditional background untuk dark mode
- [ ] Stats Card: Tambah border atau elevation yang lebih tinggi
- [ ] START LEARNING: Pastikan filled button dengan primary color
- [ ] IMPORT DATASET: Outlined button dengan primary color border
- [ ] SETTINGS: Text button atau outlined tipis (warna lebih subtle)
- [ ] Test di Light Mode & Dark Mode
- [ ] Flutter analyze & build verification

---

**Estimasi:** 10-15 menit coding + testing 🚀
