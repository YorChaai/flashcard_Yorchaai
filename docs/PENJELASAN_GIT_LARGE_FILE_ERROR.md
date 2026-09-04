# Penjelasan Error GitHub Large Files (GH001) & Solusinya

Dokumen ini menjelaskan penyebab error saat melakukan `git push origin main` pada proyek ini, mengapa file ditolak oleh GitHub, serta bagaimana solusi `git reset --soft` dan `.gitignore` berhasil memperbaikinya.

---

## 1. Penyebab Masalah (Root Cause)

Ketika Anda menjalankan:
```powershell
git add .
git commit -m "..."
git push origin main
```

Muncul pesan error dari GitHub:
```text
remote: error: File graphify-out/cache/ast/v0.9.53-s2/...json is 103.77 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: File graphify-out/graph.json is 139.48 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: File tools/jmdict-eng.json is 112.38 MB; this exceeds GitHub's file size limit of 100.00 MB
remote: error: GH001: Large files detected. You may want to try Git Large File Storage - https://git-lfs.github.com.
 ! [remote rejected] main -> main (pre-receive hook declined)
```

### Mengapa Ini Terjadi?
1. **Batas Ukuran File GitHub**:
   GitHub menerapkan aturan ketat: **Setiap file tunggal tidak boleh melebihi 100.00 MB**. Jika ada 1 saja file dalam commit yang melebihi 100 MB, server GitHub akan langsung menolak seluruh pengiriman (*pre-receive hook declined*).
2. **File yang Melebihi Batas**:
   - `graphify-out/graph.json`: Berukuran **139.48 MB** (file graph relasi kode/dokumen lokal).
   - `graphify-out/cache/ast/...json`: Berukuran **103.77 MB** (cache AST parsing graphify).
   - `tools/jmdict-eng.json`: Berukuran **112.38 MB** (kamus offline mentah bahasa Jepang).
3. **Belum Terdaftar di `.gitignore`**:
   Sebelumnya, folder `graphify-out/` dan file `tools/jmdict-eng.json` belum dimasukkan ke `.gitignore`. Akibatnya, perintah `git add .` menganggap kedua file tersebut adalah bagian dari kodingan yang harus diunggah ke GitHub.

---

## 2. Cara Kerja Solusi yang Dilakukan

Untuk mengatasi masalah tersebut tanpa kehilangan kodingan apa pun, dilakukan langkah berikut:

### Langkah 1: Mendaftarkan ke `.gitignore`
Folder dan file raksasa ditambahkan ke `.gitignore`:
```gitignore
# Graphify knowledge graph (local output)
graphify-out/

# Large raw dictionaries
tools/jmdict-eng.json
```
Dengan ini, Git diberi instruksi permanen untuk **mengabaikan** file-file tersebut pada semua `git add` selanjutnya.

### Langkah 2: Membatalkan Commit Lokal dengan `git reset --soft origin/main`
Ketika commit yang berisi file besar sudah terlanjur dibuat di komputer lokal Anda, file tersebut masih tersimpan di dalam riwayat commit lokal.

Perintah:
```powershell
git reset --soft origin/main
```
- **Apa yang dilakukan?**
  Perintah ini memindahkan pointer Git kembali ke commit terakhir yang ada di GitHub (`origin/main`).
- **Apakah kodingan saya aman?**
  **100% AMAN**. Mode `--soft` **TIDAK menghapus** pekerjaan Anda. Semua perubahan kode, fitur baru, dan file yang sudah Anda buat tetap berada di komputer Anda dalam kondisi siap di-commit (*staged*).

### Langkah 3: Mengapa Muncul `fatal: pathspec did not match any files`?
Saat Anda menjalankan:
```powershell
git rm --cached -r graphify-out
git rm --cached tools/jmdict-eng.json
```
Pesan `fatal: pathspec did not match any files` muncul karena setelah `git reset --soft` dan `.gitignore` diterapkan, Git sudah otomatis mengeluarkan file-file tersebut dari daftar pantau (*index/cache*), sehingga file tersebut memang sudah tidak lagi terikat ke Git. Ini adalah hal normal dan tidak berbahaya.

### Langkah 4: Commit dan Push Bersih
Setelah file raksasa diabaikan oleh `.gitignore`:
```powershell
git add .
git commit -m "Update row selection and mobile priority drag in Library Preview"
git push origin main
```
Git hanya mengunggah file source code, dokumen, dan aset yang sah (< 10 MB). Hasilnya:
```text
Writing objects: 100% (210/210), 8.69 MiB | 18.15 MiB/s, done.
To https://github.com/YorChaai/flashcard_Yorchaai.git
   e798ce5..dae82f7  main -> main
```
**Push berhasil sukses 100%**.

---

## 3. Ringkasan Tips untuk Masa Depan

1. **Gunakan `.gitignore` untuk Data Besar**:
   Jika di masa depan Anda mengunduh kamus besar (seperti `.json`, `.csv`, `.sqlite`, `.zip` di atas 50 MB) atau tool yang menghasilkan output cache/grafik lokal yang besar, pastikan memasukkan nama folder/file tersebut ke file `.gitignore` terlebih dahulu.
2. **Jika Terjadi Error 100 MB Lagi**:
   Cukup ulangi langkah cepat ini:
   ```powershell
   git reset --soft origin/main
   # Tambahkan file besar ke .gitignore
   git add .
   git commit -m "Pesan commit"
   git push origin main
   ```
