# Panduan Penggunaan Graphify pada Proyek Flutter Flashcard

Dokumen ini menjelaskan alur kerja praktis penggunaan Graphify untuk memetakan arsitektur dan relasi kode pada proyek **Flashcard**.

---

## 1. Menyiapkan File `.graphifyignore` (Sangat Disarankan)

Proyek Flutter memiliki banyak file bawaan build, pustaka eksternal, dan cache (seperti `.dart_tool`, `build/`, `android/`, `ios/`, `windows/`). Agar Knowledge Graph terfokus pada kode inti aplikasi Anda di `lib/`, buat file `.graphifyignore` di root folder proyek:

Isi file `.graphifyignore`:
```gitignore
# Flutter & Dart builds
.dart_tool/
build/
.flutter-plugins
.flutter-plugins-dependencies

# Platform native folders (opsional jika hanya ingin fokus logika Dart)
android/
ios/
web/
windows/
linux/
macos/

# Test cache & temporary assets
test/.test_coverage/
```

Dengan konfigurasi di atas, Graphify hanya akan fokus memetakan seluruh file Dart Anda di folder `lib/` dan `test/`.

---

## 2. Membuat Knowledge Graph Codebase Pertama Kali

Jalankan perintah berikut di PowerShell dari root folder proyek `d:\2. Organize\1. Projects\flashcard`:

```powershell
graphify .
```

Jika Anda ingin memastikan hanya source code (AST Tree-Sitter) saja yang diproses secara offline tanpa memanggil model LLM untuk dokumen:
```powershell
graphify extract . --code-only
```

### Apa yang Terjadi Saat Perintah Berjalan?
1. Tree-Sitter membaca seluruh file Dart (`lib/**/*.dart`).
2. Menemukan semua deklarasi kelas (`Deck`, `Card`, `ImportPreviewScreen`, `AppProviders`, dll.).
3. Menghubungkan relasi method calls, imports, inheritance (`StatefulWidget`, `ChangeNotifier`), dan implementasi interface.
4. Menjalankan algoritma pengelompokan (*Leiden Community Detection*) untuk membagi modul aplikasi menjadi klaster subsistem.
5. Menyimpan hasil ke folder `graphify-out/`.

---

## 3. Melihat Visualisasi Graf di Browser

Buka file berikut di Google Chrome, Edge, atau browser favorit Anda:
```text
d:\2. Organize\1. Projects\flashcard\graphify-out\graph.html
```

Di dalam antarmuka web interaktif ini Anda bisa:
- **Melihat Klaster Fitur**: Komunitas warna menunjukkan modul yang saling berkaitan erat (misal: klaster deck management, klaster Excel import/export, klaster UI screens).
- **Melihat God Nodes**: Node berukuran paling besar adalah komponen inti yang menjadi pusat dependensi proyek (misal: state provider atau database service).
- **Klik Node**: Menampilkan detail koneksi ke file atau method lain, baris kode sumber, dan derajat konektivitas.

---

## 4. Query Kode Melalui Terminal

Setelah graf terbentuk, Anda tidak perlu lagi melakukan grep atau mencari file satu per satu. Anda bisa bertanya langsung:

### A. Menjelaskan Suatu Komponen / Model
Melihat semua hal yang bergantung atau digunakan oleh suatu kelas:
```powershell
graphify explain "ImportPreviewScreen"
```
```powershell
graphify explain "DeckDetailScreen"
```

### B. Menelusuri Jalur Hubungan Antar 2 Komponen (Shortest Path)
Ingin tahu bagaimana sebuah layar UI terhubung ke penyimpanan data?
```powershell
graphify path "ImportPreviewScreen" "ExcelService"
```
Graphify akan menampilkan hop/loncatan relasi, misalnya:
`ImportPreviewScreen` ➔ memanggil `AppProviders` ➔ menggunakan `ExcelService`.

### C. Menanyakan Pertanyaan Semantik
```powershell
graphify query "bagaimana alur import kartu dari file excel ke database?"
```

---

## 5. Memperbarui Graf Ketika Ada Perubahan Kode

Jika Anda baru saja menambah fitur atau merefaktor beberapa file Dart:
```powershell
graphify update .
```
Perintah ini hanya akan membaca ulang file yang berubah secara inkremental tanpa mengulang pemindaian dari awal.

---

## 6. Mengaktifkan Otomasi Git Hook (Opsional)
Jika Anda ingin graf diperbarui secara otomatis setiap kali Anda melakukan `git commit`:
```powershell
graphify hook install
```
Dengan ini, Knowledge Graph proyek Anda akan selalu sinkron dengan versi commit terbaru.
