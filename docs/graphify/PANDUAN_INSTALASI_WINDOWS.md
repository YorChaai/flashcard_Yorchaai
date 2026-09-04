# Panduan Instalasi Graphify di Windows & Google Antigravity

Panduan ini memandu Anda memasang dan mengintegrasikan Graphify pada sistem Windows dan Google Antigravity IDE.

---

## 1. Prasyarat Sistem
- **Sistem Operasi**: Windows 10 / 11.
- **Python**: Versi 3.10 ke atas *(Sistem Anda saat ini sudah terpasang Python 3.11.0)*.
- **Terminal**: PowerShell atau Command Prompt.

---

## 2. Catatan Penting Mengenai Nama Paket
> [!IMPORTANT]
> Nama paket resmi di PyPI adalah **`graphifyy`** (menggunakan dua huruf **y** di akhir).
> Paket lain bernama `graphify` di PyPI bukan paket resmi pembuatnya.  
> Namun, setelah diinstal nama perintah CLI yang digunakan tetap **`graphify`**.

---

## 3. Langkah Instalasi

Pilihlah salah satu dari dua metode di bawah ini:

### Opsi A: Menggunakan `uv` (Sangat Direkomendasikan)
Metode ini direkomendasikan karena mengisolasi *dependency* dan mencegah konflik versi library Python:

1. Buka PowerShell dan instal `uv` melalui Windows Package Manager:
   ```powershell
   winget install astral-sh.uv
   ```
2. Tutup dan buka kembali terminal PowerShell Anda.
3. Instal Graphify CLI ke isolated tool environment:
   ```powershell
   uv tool install graphifyy
   ```
4. Jika perintah `graphify` belum terdeteksi di terminal, perbarui path terminal:
   ```powershell
   uv tool update-shell
   ```

---

### Opsi B: Menggunakan `pip` Langsung
Jika Anda tidak ingin menginstal `uv`, Anda dapat menggunakan `pip` bawaan Python 3.11 yang sudah ada di komputer Anda:

1. Buka PowerShell lalu jalankan:
   ```powershell
   pip install graphifyy
   ```
2. Pastikan folder Scripts Python sudah terdaftar di Environment Variable `PATH` Windows Anda:
   - Lokasi umum: `C:\Users\<Username>\AppData\Local\Programs\Python\Python311\Scripts`
3. Cek apakah instalasi berhasil:
   ```powershell
   graphify --version
   ```

---

## 4. Integrasi ke Google Antigravity

Graphify memiliki integrasi bawaan khusus untuk **Google Antigravity**.  
Jalankan perintah berikut di root folder project (`d:\2. Organize\1. Projects\flashcard`):

```powershell
graphify antigravity install
```

Perintah ini akan secara otomatis:
1. Mendaftarkan aturan (*rules*) dan workflow Graphify ke direktori `.agents/` proyek Anda.
2. Memungkinkan asisten AI Google Antigravity membaca arsitektur dan pengetahuan proyek melalui knowledge graph secara otomatis setiap kali Anda menanyakan relasi logika kode.

Jika Anda ingin menginstal skill ini ke tingkat project secara eksplisit:
```powershell
graphify install --project
```

---

## 5. Catatan Khusus Pengguna PowerShell Windows
> [!WARNING]
> Jangan mengetik `/graphify .` dengan awalan garis miring di PowerShell!  
> PowerShell memperlakukan tanda garis miring `/` sebagai pemisah path direktori sehingga akan muncul error *"path not recognized"*.  
> **Selalu ketik:**
> ```powershell
> graphify .
> ```

---

## 6. Mengabaikan File Output di Git (.gitignore)
Graphify akan menghasilkan folder `graphify-out/`. Tambahkan baris berikut ke file `.gitignore` proyek Anda agar cache tidak memberatkan repository:

```gitignore
# Graphify
graphify-out/cost.json
graphify-out/cache/
```
*(Catatan: File `graphify-out/graph.json` dan `graphify-out/graph.html` boleh di-commit jika ingin dibagikan ke anggota tim lain).*
