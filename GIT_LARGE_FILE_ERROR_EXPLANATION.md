# 📖 Penjelasan Error Git Push: File Ukuran Besar (>100MB)

## 🔍 Apa yang Terjadi?
Saat melakukan `git push`, GitHub menolak upload dan menampilkan error:
```
remote: error: GH001: Large files detected. You may want to try Git Large File Storage
remote: error: File .../libflutter.so is 341.87 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: File .../app-debug.apk is 161.56 MB; this exceeds GitHub's file size limit of 100.00 MB
! [remote rejected] main -> main (pre-receive hook declined)
```

## ❓ Kenapa Ini Terjadi?

### 1. File Build/Generated Masuk ke Git
Folder `android/app/build/` berisi **file hasil kompilasi**, bukan source code. File ini meliputi:
- `*.apk` (Aplikasi hasil build)
- `*.so` / `*.dll` (Library native hasil kompilasi)
- Cache & intermediates (file sementara untuk mempercepat build ulang)

File-file ini seharusnya **TIDAK** di-commit ke Git karena:
✅ Bisa di-generate ulang kapan saja via `flutter build`  
✅ Ukurannya sangat besar (bisa 300MB - 1GB+)  
✅ Bukan bagian dari logika aplikasi  

### 2. GitHub Punya Batas Keras 100MB
GitHub memblokir push jika **ada 1 saja file** yang ukurannya melebihi **100MB**. Ini aturan server-side yang tidak bisa diakali.

### 3. Git Menyimpan Semua Riwayat (History)
Meskipun file sudah dihapus dari laptop, Git masih "menyimpan" file tersebut di dalam **tree commit**. Selama commit yang mengandung file besar itu masih ada di branch `main`, Git akan terus mencoba mengirimnya setiap kali `push`. Itulah kenapa error terus muncul berulang kali meskipun file sudah dihapus lokal.

## ✅ Mengapa Error Ini Tidak Terjadi di Awal?
Kemungkinan besar `.gitignore` tidak mencakup folder `build/` atau `android/app/build/` dengan benar, sehingga saat `git add .`, file-file hasil build ikut terseret masuk ke commit.

## 🛡️ Cara Mencegah di Masa Depan

### 1. Pastikan `.gitignore` Benar
Pastikan file `.gitignore` di root project Anda berisi:
```gitignore
# Build outputs
build/
*.apk
*.aab
*.app
*.so
*.dylib
*.dll

# Flutter & Dart cache
.dart_tool/
.packages
flutter_*.json

# IDE & OS files
.vscode/
.idea/
*.iml
.DS_Store
Thumbs.db
```

### 2. Workflow Aman Sebelum Commit
Sebelum commit besar, selalu jalankan:
```bash
flutter clean
git status
```
Pastikan tidak ada folder `build/` atau file `*.apk` yang muncul di `git status`.

### 3. Gunakan `git rm --cached` jika Terlanjur
Jika tidak sengaja meng-commit file besar:
```bash
git rm -r --cached android/app/build
git commit --amend -m "Perbaiki: hapus file build dari tracking"
```

## 📌 Ringkasan
| Penyebab | Solusi |
|----------|--------|
| File build masuk ke Git | Tambah `build/` ke `.gitignore` |
| Ukuran file >100MB | Hapus dari history, jangan simpan di repo |
| Error terus berulang | `flutter clean` + `git rm --cached` + `commit --amend` |

> 💡 **Ingat:** Git adalah tempat menyimpan **kode sumber**, bukan **hasil build**. Simpan APK/Installer di GitHub Releases, artifact storage, atau cloud drive.


Berikut status git Anda saat ini:

---

## 📊 Git Status Report

### **Last Pushed Commit:**
| Info | Detail |
|------|--------|
| **Commit Hash** | `4527b06` |
| **Commit Message** | `feat: Initial commit - YorFlashCard v3.0 implementation` |
| **Branch** | `origin/main` (remote) |

---

### **Local Commit (Belum di-push):**
| Info | Detail |
|------|--------|
| **Commit Hash** | `e27f8e0` |
| **Commit Message** | `feat: Initial commit - YorFlashCard v4.0 implementation` |
| **Status** | ⚠️ **Belum di-push ke remote** |

---

### **Working Directory:**
Anda punya **10 file yang sudah dimodifikasi** tapi **belum di-commit**:

| File | Status |
|------|--------|
| `lib/models/deck.dart` | 🟡 Modified |
| `lib/models/flashcard_card.dart` | 🟡 Modified |
| `lib/models/font_size_settings.dart` | 🟡 Modified |
| `lib/providers/app_providers.dart` | 🟡 Modified |
| `lib/screens/deck_detail_screen.dart` | 🟡 Modified |
| `lib/screens/flashcard_screen.dart` | 🟡 Modified |
| `lib/screens/home_screen.dart` | 🟡 Modified |
| `lib/screens/learning_preview_screen.dart` | 🟡 Modified |
| `lib/screens/result_screen.dart` | 🟡 Modified |
| `git_commands.md` | 🟡 Modified |

---

### **Summary:**
```
Remote (origin/main):     4527b06 - v3.0
Local Commit (main):      e27f8e0 - v4.0 ✅ (sudah di-commit)
```

---

## 🤖 Penjelasan Versi Antigravity (Assistant AI-mu)

Biar gampang bayanginnya, **Git itu seperti Mesin Waktu** untuk kode Anda.
1. Saat Anda ngoding Flutter, Flutter secara otomatis "memasak" kodemu menjadi aplikasi utuh (seperti `.apk`) yang tersimpan di dalam folder `build/`. Nah, file masakan ini ukurannya **raksasa** (bahkan mencapai lebih dari 300MB).
2. Sayangnya, Anda **lupa mengatur penjaga pintu kelolosan** (yaitu file bernama `.gitignore`) agar selalu mengacuhkan folder `build/` ini. 
3. Alhasil, saat Anda kemarin mengetik `git add .` dan melakukan **commit**, mesin waktu Git secara tidak sadar ikut menelan file raksasa tadi ke dalam kapsul waktu riwayatnya.
4. Ketika Anda mencoba melempar kapsul waktu ini ke server GitHub lewat `git push`, **GitHub langsung kaget dan menolaknya mentah-mentah!** Kenapa? Karena aturan gerbang utama mereka adalah dilarang keras membawa barang dengan besar lipat di atas 100MB.
5. Anda mungkin merasa, *"Lho, kan foldernya udah aku hapus di laptop?"* Ya, di folder saat ini memang sudah hilang, tapi di dalam *kapsul waktu (history commit) Anda yang lalu*, barang raksasa itu **masih ikut tersangkut**! Git akan terus ngotot mencoba mengirim riwayat tersebut setiap kali Anda mengklik tombol push.

**Solusi yang baru saja kita tuntaskan bersama tadi:**
- 🔧 Memecahkan kapsul waktunya dan mengulangnya kembali dari titik aman sebelum insiden terjadi (`git reset`).
- 🛡️ Memperbaiki penjaga pintunya dengan menambahkan `build/` pada file `.gitignore`, sehingga sampai kapanpun file raksasa itu tidak akan pernah bisa dilirik lagi oleh Git.
- 🚀 Merakit ulang commit baru yang sudah sepenuhnya ringan & bersih, lalu lanjut terkirim aman sentosa ke angkasa GitHub!
