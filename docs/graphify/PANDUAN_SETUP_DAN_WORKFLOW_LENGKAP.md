# Panduan Lengkap: Setup dan Workflow Ekosistem 4 Pilar di Berbagai Project

## (Graphify, Ponytail, 9Router, dan Playwright)

> **Tentang Panduan Ini:**  
> Panduan ini disusun sebagai buku petunjuk komprehensif untuk menyiapkan, mengintegrasikan, dan menjalankan alur kerja harian (_daily workflow_) pengembangan perangkat lunak berbasis AI yang super hemat token, terstruktur rapi, dan anti-overengineering. Panduan ini dapat diterapkan pada proyek Flutter, Python, TypeScript/JavaScript, mau pun bahasa pemrograman lainnya.

---

## DAFTAR ISI

1. [Filosofi Ekosistem 4 Pilar](#1-filosofi-ekosistem-4-pilar)
2. [Memahami Status: Global vs Per-Project](#2-memahami-status-global-vs-per-project)
3. [Panduan Langkah Demi Langkah Memasang di Project Baru](#3-panduan-langkah-demi-langkah-memasang-di-project-baru)
4. [Alur Kerja Harian (The 5-Step Golden Workflow)](#4-alur-kerja-harian-the-5-step-golden-workflow)
5. [Bedah Tuntas Mekanisme `graphify update`](#5-bedah-tuntas-mekanisme-graphify-update)
6. [Panduan Praktis Operasional Ponytail](#6-panduan-praktis-operasional-ponytail)
7. [Panduan Praktis Operasional 9Router](#7-panduan-praktis-operasional-9router)
8. [Panduan Praktis Operasional Playwright](#8-panduan-praktis-operasional-playwright)
9. [Tabel Komando Cepat (Cheat Sheet)](#9-tabel-komando-cepat-cheat-sheet)
10. [Troubleshooting & Solusi Masalah Umum](#10-troubleshooting--solusi-masalah-umum)

---

## 1. Filosofi Ekosistem 4 Pilar

Saat menggunakan AI koding (seperti Google Antigravity, Claude Code, Cursor, dll.), masalah terbesar yang sering dihadapi developer adalah:

1. **AI Muter-Muter (Boros Token Input):** AI membaca puluhan file secara acak menggunakan _grep_ atau _file scan_ mentah hanya untuk mencari satu fungsi kecil.
2. **AI Lebay / Overengineering (Boros Token Output):** AI menulis terlalu banyak class, interface, abstraction, dan file baru yang sebenarnya tidak diminta.
3. **Batas Kuota / Rate Limit API:** Kehabisan kuota model AI di tengah proses koding.
4. **Validasi Lambat:** Mengetes perubahan antarmuka atau logika web secara manual yang melelahkan.

Untuk mengatasi keempat masalah tersebut, kita mengombinasikan **4 Pilar Sinergis**:

```
                       ┌─────────────────────────────────────────┐
                       │           PERMINTAAN / TUGAS            │
                       └────────────────────┬────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────┐
                       │     1. GRAPHIFY (Discovery / IN)        │
                       │  • Memetakan AST & arsitektur kode      │
                       │  • Hemat token pencarian hingga 85%     │
                       └────────────────────┬────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────┐
                       │     2. PONYTAIL (Writing / OUT)         │
                       │  • Membatasi kodingan berlebihan        │
                       │  • Menerapkan 7-Rung Ladder & YAGNI     │
                       └────────────────────┬────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────┐
                       │     3. PLAYWRIGHT (Verification)        │
                       │  • Testing otomatis & screenshot UI     │
                       │  • Memastikan hasil kodingan valid      │
                       └────────────────────┬────────────────────┘
                                            │
                                            ▼
                       ┌─────────────────────────────────────────┐
                       │     4. 9ROUTER (Gateway & Fallback)     │
                       │  • Pengalihan provider saat kuota habis │
                       │  • Kompresi teks output terminal (RTK)  │
                       └─────────────────────────────────────────┘
```

- **Graphify**: Menguasai gerbang **INPUT**. AI hanya membaca file yang benar-benar relevan.
- **Ponytail**: Menguasai gerbang **OUTPUT**. AI hanya menulis kode yang esensial, to-the-point, dan bersih.
- **Playwright**: Menguasai gerbang **VALIDASI**. Menguji aplikasi tanpa perlu mengklik browser secara manual.
- **9Router**: Menguasai gerbang **INFRASTRUKTUR**. Menjaga kontinuitas kerja saat model utama terkena limit dan mengompres output terminal melalui RTK.

---

## 2. Memahami Status: Global vs Per-Project

Sebelum Anda memasang di folder proyek lain (misalnya `D:\2. Organize\1. Projects\MiniProjectKPI_EWI_Revisi2`), sangat penting memahami pemisahan ini:

### A. Komponen Global (Cukup Dipasang 1 Kali di Komputer)

Komponen ini **sudah terpasang di komputer Anda** dan langsung tersedia di folder mana pun tanpa perlu diinstal ulang:

1. **9Router CLI**: Terpasang global via npm (`C:\Users\<User>\AppData\Roaming\npm\9router`).
2. **Playwright CLI & Chromium Browser**: Terpasang global via npm dan binary browser di `AppData\Local\ms-playwright\chromium-1234`.
3. **Plugin Ponytail Antigravity**: Tersimpan di `C:\Users\<User>\.gemini\config\plugins\ponytail`. Antigravity membaca plugin ini secara otomatis untuk semua proyek di komputer Anda.
4. **Graphify CLI**: Paket Python/UV terpasang di environment sistem Anda.

### B. Komponen Per-Project (Harus Dijalankan/Dibuat di Setiap Folder Proyek Baru)

Komponen ini bersifat unik untuk masing-masing codebase:

1. **Folder `graphify-out/`**: Berisi basis data graf (`graph.json`), visualisasi interaktif (`graph.html`), dan ringkasan arsitektur (`GRAPH_REPORT.md`) khusus untuk proyek tersebut.
2. **File Aturan Workspace (`.agents/rules/`)**:
   - `graphify.md`: Memberitahu AI agar selalu mengecek graf sebelum mencari file, dan selalu menjalankan `graphify update .` setelah mengubah kode.
   - `ponytail.md`: Mengunci perilaku AI pada mode _Lazy Senior Developer_ khusus pada proyek tersebut.

---

## 3. Panduan Langkah Demi Langkah Memasang di Project Baru

Katakanlah Anda ingin memasang sistem ini pada proyek baru, misalnya:  
`D:\2. Organize\1. Projects\MiniProjectKPI_EWI_Revisi2`

Ikuti 5 langkah mudah berikut:

### Langkah 1: Buka Terminal dan Masuk ke Folder Proyek Baru

Buka terminal PowerShell, lalu navigasikan ke folder proyek Anda:

```powershell
cd "D:\2. Organize\1. Projects\MiniProjectKPI_EWI_Revisi2"
```

---

### Langkah 2: Buat Folder Aturan `.agents/rules/`

Buat folder konfigurasi aturan untuk agen AI:

```powershell
mkdir -p .agents\rules
```

---

### Langkah 3: Buat Berkas Aturan `graphify.md`

Buat berkas `.agents\rules\graphify.md` dengan isi berikut:

```markdown
## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:

- For codebase or architecture questions, when `graphify-out/graph.json` exists, first run `graphify query "<question>"` (CLI) or `query_graph` (MCP). Use `graphify path "<A>" "<B>"` / `shortest_path` for relationships and `graphify explain "<concept>"` / `get_node` for focused concepts. These return a scoped subgraph, usually much smaller than `GRAPH_REPORT.md` or raw grep output.
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
```

---

### Langkah 4: Buat Berkas Aturan `ponytail.md`

Buat berkas `.agents\rules\ponytail.md` dengan isi berikut:

```markdown
# Ponytail: The Lazy Senior Developer

Act like the laziest, most pragmatic senior developer in the room. Your motto: **"The best code is the code you never wrote."**
Avoid overengineering, boilerplate, and unnecessary abstraction. Always prefer the simplest, most direct solution.

---

## The 7-Rung Decision Ladder

Before writing or modifying ANY code, climb this ladder rung by rung:

1. **YAGNI (You Aren't Gonna Need It)**: Does this code strictly need to exist to solve the user's request? If no, skip it.
2. **Reuse**: Does an existing function, helper, or widget already do this? Reuse it. Never reinvent the wheel.
3. **Stdlib**: Can the language standard library solve this directly? Use it instead of custom logic.
4. **Native**: Does the framework provide a built-in mechanism? Use native features.
5. **Existing Dependencies**: Can an already-installed package handle this? Do not add new libraries without explicit permission.
6. **One-Liner**: Can this be expressed cleanly in a single line or short expression? Do that.
7. **Minimum Viable Code**: Write the absolute minimum code required to make it work reliably.

---

## Lazy, Not Negligent

- Never compromise on error handling, security, or boundary validation.
- Preserve existing comments and architecture integrity.
```

---

### Langkah 5: Jalankan Ekstraksi Graf Pertama Kali

Jalankan perintah inisialisasi Graphify pada folder tersebut:

```powershell
graphify .
```

- **Apa yang terjadi:**  
  Graphify akan memindai seluruh file sumber (`.py`, `.dart`, `.ts`, `.js`, dll.) menggunakan parser Tree-Sitter lokal.
- **Hasilnya:**  
  Folder `graphify-out/` akan otomatis terbuat, berisi:
  - `graph.json` (basis data relasi lengkap).
  - `graph.html` (grafik visualisasi interaktif).
  - `GRAPH_REPORT.md` (laporan simpul penting / _God Nodes_).

**Selesai!** Proyek baru Anda sekarang telah memiliki ekosistem lengkap 4 pilar.

---

## 4. Alur Kerja Harian (The 5-Step Golden Workflow)

Saat Anda bekerja sehari-hari pada proyek yang sudah dipasangi sistem ini, gunakan siklus kerja 5 langkah berikut:

```text
[Permintaan Masalah / Fitur]
           │
           ▼
1. TAHAP DISCOVERY (IN)   ───▶ graphify query "<topik>" / graphify explain "<file>"
           │
           ▼
2. TAHAP REASONING        ───▶ AI membaca subgraph yang kecil (<500 token)
           │
           ▼
3. TAHAP CODING (OUT)     ───▶ Ponytail menjaga kodingan minimalis & to-the-point
           │
           ▼
4. TAHAP VERIFIKASI       ───▶ Unit test (flutter test / pytest) atau Playwright
           │
           ▼
5. TAHAP SINKRONISASI     ───▶ graphify update . (AST lokal, 0 token)
```

### Penjelasan Praktis Setiap Langkah:

#### Langkah 1 & 2: Temukan Masalah Tanpa Muter-Muter (IN)

Ketika ada bug atau Anda ingin menambah fitur baru, jangan biarkan AI melakukan pencarian teks (_grep_) acak ke seluruh folder. Gunakan perintah graphify:

- Ingin tahu letak fungsi filter:
  ```powershell
  graphify query "where is filter logic implemented"
  ```
- Ingin tahu siapa saja yang memanggil class tertentu:
  ```powershell
  graphify explain "LearningSessionProvider"
  ```
- Ingin melihat keterhubungan antara dua modul:
  ```powershell
  graphify path "excel_service" "learning_preview_screen"
  ```
  AI hanya akan disuplai potongan graf kecil (_subgraph_) yang langsung menuju sasaran.

#### Langkah 3: Koding Terarah (OUT)

AI mengeksekusi perubahan kode di bawah pengawasan **Ponytail**.  
Jika Anda meminta perbaikan bug, AI hanya akan memperbaiki baris kode yang rusak tanpa membuat class baru atau merombak arsitektur di luar kebutuhan.

#### Langkah 4: Verifikasi Hasil (Testing & Playwright)

Uji apakah perubahan berjalan dengan baik:

- Untuk proyek Flutter/Dart:
  ```powershell
  flutter test
  ```
- Untuk proyek Web / Frontend (menggunakan Playwright):
  ```powershell
  npx playwright test
  ```
- Atau ambil screenshot tampilan web secara otomatis:
  ```powershell
  npx playwright screenshot http://localhost:3000 preview.png
  ```

#### Langkah 5: Sinkronisasi Arsitektur (`graphify update .`)

Setelah kode selesai dimodifikasi dan berhasil diverifikasi, jalankan:

```powershell
graphify update .
```

Langkah ini memperbarui peta graf secara instan agar AI pada giliran berikutnya (_next turn_) membaca struktur kode yang paling mutakhir.

---

## 5. Bedah Tuntas Mekanisme `graphify update`

Banyak pengguna bertanya: _"Apa bedanya `graphify .` dengan `graphify update .`? Kenapa harus di-update dan apakah memakan biaya token?"_

Mari kita bedah secara mendalam:

### A. Perbedaan Mendasar

| Parameter                  | `graphify .` (Inisialisasi Awal)                 | `graphify update .` (Pembaruan Rutin)                        |
| -------------------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| **Kapan Dipakai**          | Saat pertama kali proyek dipasangi Graphify.     | Setiap kali setelah ada kode yang ditambah/diubah.           |
| **Cakupan Pemindaian**     | Memindai seluruh folder dari nol.                | **Inkremental**: hanya mendeteksi file yang berubah.         |
| **Konsumsi Biaya / Token** | 0 Token untuk file kode (AST Tree-Sitter lokal). | **0 Token (100% Gratis & Lokal)**.                           |
| **Waktu Eksekusi**         | 5 – 20 detik (tergantung besarnya proyek).       | **1 – 3 detik** (sangat cepat).                              |
| **Dampak File**            | Membuat folder `graphify-out/` baru.             | Memperbarui `graph.json`, `graph.html`, & `GRAPH_REPORT.md`. |

### B. Cara Kerja di Balik Layar `graphify update .`

1. **Deteksi Timestamp & Hash File**:  
   Graphify memeriksa berkas mana saja yang memiliki waktu modifikasi (_mtime_) lebih baru daripada snapshot graf sebelumnya.
2. **Parsing AST Inkremental (Tree-Sitter)**:  
   Hanya berkas yang berubah yang di-parse ulang sintaksnya. Fungsi yang ditambah atau dihapus akan diperbarui simpulnya (_node_), dan relasi impornya (_edge_) disesuaikan.
3. **Deteksi Komunitas Ulang (Leiden Algorithm)**:  
   Jika ada hubungan baru antar modul, algoritma pengelompokan (_clustering_) memperbarui peta kelompok kode.
4. **Penyimpanan Snapshot**:  
   Graphify membuat backup versi graf lama ke folder bertanggal (misal `graphify-out/2026-09-04/`) dan menuliskan data terbaru ke `graph.json` dan `graph.html`.

### C. Mengapa Wajib Dijalankan Setelah Mengubah Kode?

Jika Anda mengubah nama fungsi, menambah parameter, atau memindahkan class, tetapi **tidak menjalankan `graphify update .`**:

- AI berikutnya akan membaca peta lama yang sudah usang (_stale context_).
- AI bisa mengira fungsi lama masih ada, atau tidak mengetahui bahwa Anda sudah menambahkan file baru.
- Dengan membiasakan `graphify update .`, peta arsitektur selalu sinkron 100% dengan kenyataan kode.

---

## 6. Panduan Praktis Operasional Ponytail

Ponytail telah terpasang secara global sebagai plugin di `~/.gemini/config/plugins/ponytail` dan aktif sebagai rule di proyek Anda.

### A. Kapan Menggunakan Perintah Khusus Ponytail?

| Perintah / Perilaku | Cara Memanggil di Chat                           | Kapan Harus Digunakan?                                                                                                               |
| ------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Ponytail Review** | `Tolong review file ini dengan /ponytail-review` | Saat Anda merasa kodingan yang dibuat AI terlalu panjang atau rumit, dan ingin mencari bagian yang bisa dipangkas.                   |
| **Ponytail Help**   | `/ponytail-help`                                 | Saat ingin melihat cheatsheet tangga keputusan dan semua opsi Ponytail.                                                              |
| **Ponytail Gain**   | `/ponytail-gain`                                 | Saat ingin melihat rangkuman scoreboard penghematan token dan baris kode.                                                            |
| **Ponytail Debt**   | `/ponytail-debt`                                 | Mengumpulkan semua komentar `# ponytail:` atau `// ponytail:` (catatan jalan pintas yang sengaja ditunda agar tidak overengineered). |
| **Audit Repo**      | `/ponytail-audit`                                | Memindai seluruh repository untuk mencari file atau class mubazir yang layak dihapus.                                                |

### B. Tiga Tingkat Kemalasan (_Intensity Modes_)

Anda dapat mengatur seberapa keras Ponytail mengawasi kodingan AI:

1. **Lite Mode** (`Gunakan Ponytail Lite`):  
   AI tetap membuat solusi standar, tetapi di akhir jawaban akan memberikan saran 1 baris alternatif yang lebih ringkas.
2. **Full Mode (Default)** (`Gunakan Ponytail Full`):  
   AI mematuhi 7-Rung Ladder secara ketat. Menolak menambah file baru jika cukup diselesaikan di file yang sudah ada.
3. **Ultra Mode** (`Gunakan Ponytail Ultra`):  
   Mode ekstrem YAGNI. Sebelum menulis 1 baris kode pun, AI akan mendebat kebutuhan Anda: _"Apakah fitur ini benar-benar penting untuk pengguna sekarang? Bisakah kita selesaikan tanpa coding sama sekali?"_

---

## 7. Panduan Praktis Operasional 9Router

9Router berjalan sebagai proxy lokal pada port `20128`.

### A. Menjalankan Server 9Router

Buka terminal dan jalankan:

```powershell
# Menjalankan standar (otomatis membuka dashboard browser)
9router

# Atau menjalankan di latar belakang tanpa membuka browser
9router --no-browser --tray
```

### B. Mengakses Dashboard Web

Buka browser ke alamat:  
👉 **`http://localhost:20128/dashboard`**

Di dashboard ini, Anda dapat:

1. **Mengonfigurasi Provider**: Memasukkan API key untuk OpenAI, Anthropic, Gemini, DeepSeek, OpenRouter, atau mengaktifkan provider gratisan (seperti Qwen, iFlow, Kiro).
2. **Mengatur Prioritas Routing (Fallback)**:
   - Prioritas 1: Provider Langganan / Utama.
   - Prioritas 2: Provider Murah.
   - Prioritas 3: Provider Gratis (saat limit harian tercapai).
3. **Mengaktifkan RTK Token Saver**:
   - Fitur RTK (Run-Time Knowledge) otomatis menyaring dan mengompresi keluaran terminal yang sangat panjang (misal log error ratusan baris atau hasil `git diff` besar) sebelum dikirimkan ke model AI.
   - Penghematan token terminal input mencapai 20% – 40%.

### C. Menghubungkan ke Tool Coding Eksternal (Cursor / Cline / Claude Code)

Jika Anda menggunakan editor lain di luar Antigravity:

- **API Base URL**: `http://localhost:20128/v1`
- **API Key**: Gunakan API key yang digenerate pada dashboard 9Router.
- **Model Name**: Pilih model virtual 9Router atau nama model asli.

---

## 8. Panduan Praktis Operasional Playwright

Playwright adalah platform otomasi browser modern yang cepat, andal, dan mendukung browser Chromium, Firefox, dan WebKit.

### A. Mengapa Playwright Sangat Berguna Bersama AI?

Daripada Anda harus menjalankan aplikasi, membuka browser manual, mengklik 5 tombol, lalu memeriksa apakah tampilannya benar:

- AI dapat menuliskan skrip Playwright sederhana.
- Playwright membuka browser secara otomatis di latar belakang (_headless_), menguji semua alur, dan mengambil screenshot sebagai bukti.

### B. Perintah Utama Playwright

#### 1. CodeGen: Merekam Interaksi Menjadi Kode Otomatis

Buka terminal dan ketik:

```powershell
npx playwright codegen https://example.com
```

- Jendela browser akan muncul beserta panel perekam.
- Setiap kali Anda mengklik tombol, mengisi form, atau berpindah halaman, Playwright akan menuliskan kode pengujian secara otomatis di panel samping. Anda tinggal menyalin kode tersebut.

#### 2. Mengambil Screenshot Web Secara Cepat

```powershell
# Mengambil tangkapan layar full page
npx playwright screenshot --full-page https://flutter.dev flutter_full.png

# Mengambil tangkapan layar tampilan mobile
npx playwright screenshot --device="iPhone 13" https://flutter.dev mobile.png
```

#### 3. Membuka Halaman Web Interaktif untuk Pengujian

```powershell
npx playwright open https://google.com
```

#### 4. Menjalankan Skrip Testing

Jika proyek Anda memiliki folder `tests/` berbasis Playwright:

```powershell
# Menjalankan seluruh pengujian headless
npx playwright test

# Menjalankan pengujian dengan menampilkan jendela browser (UI Mode)
npx playwright test --ui
```

---

## 9. Tabel Komando Cepat (Cheat Sheet)

Simpan tabel ini sebagai contekan kilat operasional harian Anda:

| Kategori       | Perintah Terminal / Prompt               | Fungsi Utama                                       |
| -------------- | ---------------------------------------- | -------------------------------------------------- |
| **Graphify**   | `graphify .`                             | Inisialisasi awal pemetaan graf proyek.            |
| **Graphify**   | `graphify update .`                      | Memperbarui peta graf setelah koding (0 token).    |
| **Graphify**   | `graphify query "<topik>"`               | Mencari tahu letak logika/komponen tertentu.       |
| **Graphify**   | `graphify explain "<simpul>"`            | Menjelaskan relasi modul/class tertentu.           |
| **Graphify**   | `graphify path "<A>" "<B>"`              | Menemukan rantai hubungan dari modul A ke B.       |
| **Ponytail**   | `/ponytail-review`                       | Meninjau kodingan untuk memangkas overengineering. |
| **Ponytail**   | `/ponytail-gain`                         | Menampilkan scoreboard estimasi penghematan token. |
| **Ponytail**   | `/ponytail-help`                         | Menampilkan panduan lengkap tangga keputusan.      |
| **9Router**    | `9router`                                | Menyalakan proxy lokal & membuka dashboard.        |
| **9Router**    | `9router --no-browser --tray`            | Menjalankan di background sistem tray.             |
| **Playwright** | `npx playwright codegen <url>`           | Merekam klik browser menjadi kode testing.         |
| **Playwright** | `npx playwright screenshot <url> <file>` | Mengambil tangkapan layar halaman web otomatis.    |
| **Playwright** | `npx playwright test`                    | Menjalankan seluruh skrip pengujian browser.       |

---

## 10. Troubleshooting & Solusi Masalah Umum

### 1. Perintah `graphify update .` Memunculkan Pesan _Community set changed_

- **Gejala:** Muncul output `[graphify watch] community set changed since labeling... Run graphify label to refresh names with the LLM.`
- **Penjelasan:** Ini **bukan error**. Ini menandakan pembaruan struktur AST berhasil dan cluster kode telah disesuaikan secara lokal. Anda tidak perlu menjalankan `graphify label` kecuali Anda ingin AI melabeli ulang nama komunitas subsistem menggunakan API key.

### 2. Port `20128` 9Router Sudah Digunakan (_EADDRINUSE_)

- **Gejala:** 9Router gagal start karena port 20128 sedang dipakai proses lain.
- **Solusi:**
  1. Tutup proses 9Router yang masih berjalan di latar belakang:
     ```powershell
     Get-Process -Name node | Stop-Process
     ```
  2. Atau jalankan pada port lain:
     ```powershell
     9router -p 20129
     ```

### 3. Playwright Error: _Executable doesn't exist at C:\Users\...\chromium_

- **Gejala:** Playwright tidak menemukan browser Chromium saat dijalankan.
- **Solusi:** Jalankan instalasi ulang binary browser Chromium:
  ```powershell
  npx playwright install chromium
  ```

### 4. AI Masih Menulis Kode yang Terlalu Panjang / Bertele-tele

- **Gejala:** AI mengabaikan prinsip ringkas dan membuat terlalu banyak file baru.
- **Solusi:** Ingatkan AI secara langsung di prompt:
  > _"Gunakan mode Ponytail Full. Ikuti 7-Rung Decision Ladder: jangan buat class atau file baru, selesaikan dengan fungsi bawaan yang paling minimalis."_

---

_Panduan ini disimpan di:_  
`D:\2. Organize\1. Projects\flashcard\docs\graphify\PANDUAN_SETUP_DAN_WORKFLOW_LENGKAP.md`

Berikut adalah panduan praktis dan langkah demi langkah cara menggunakan **Ponytail**, **9Router**, dan **Playwright**:

---

## 1. Cara Menggunakan **Ponytail** (Anti-Overengineering & Hemat Token Koding)

Ponytail bekerja langsung di dalam interaksi Anda dengan AI di IDE ini. Anda tidak perlu membuka aplikasi terpisah.

### A. Otomatis (Sudah Aktif)

Karena sudah dipasang di aturan proyek, setiap kali Anda meminta saya menulis atau memperbaiki kode, Ponytail otomatis aktif:

- Saya akan menolak membuat class/interface/file baru yang tidak penting.
- Saya akan menggunakan fungsi bawaan Dart/Flutter (Stdlib) dan kode yang ada (Reuse).

### B. Perintah Manual yang Bisa Anda Ketik ke AI:

1. **Minta Cek Kodingan Berlebihan:**
   > _"Tolong review file X dengan `/ponytail-review`"_  
   > 👉 AI akan memeriksa apakah ada kodingan yang kepanjangan, duplikat, atau overengineered, lalu memberi tahu bagian mana yang bisa disederhanakan/dihapus.
2. **Lihat Skor Penghematan:**
   > _"Tampilkan `/ponytail-gain`"_  
   > 👉 Menampilkan statistik estimasi penghematan token, baris kode, dan kecepatan.
3. **Melihat Daftar Perintah Lengkap:**
   > _"Tampilkan `/ponytail-help`"_
4. **Mengatur Tingkat Kemalasan (Intensity Level):**
   - _"Pakai Ponytail Lite"_ ➔ AI tetap bikin yang Anda minta, tapi menyarankan versi 1 barisnya.
   - _"Pakai Ponytail Full"_ ➔ (Default) Mengikuti 7 langkah tangga keputusan secara ketat.
   - _"Pakai Ponytail Ultra"_ ➔ AI akan menantang balik kebutuhan Anda: _"Apakah fitur ini benar-benar penting? Kenapa tidak pakai cara X saja?"_

---

## 2. Cara Menggunakan **9Router** (Gateway Multi-Provider & Kompresi RTK)

9Router berjalan sebagai server lokal di komputer Anda untuk mengelola API AI.

### Langkah Penggunaan:

1. **Nyalakan 9Router:**  
   Buka terminal PowerShell baru, lalu ketik:
   ```powershell
   9router
   ```
2. **Buka Dashboard di Browser:**  
   Buka browser (Chrome/Edge) ke alamat:
   👉 **`http://localhost:20128/dashboard`**
3. **Di Dalam Dashboard:**
   - **Tambah Model/Provider:** Hubungkan provider gratisan (seperti Qwen, iFlow, Kiro) atau masukkan API key berbayar Anda.
   - **Aktifkan RTK Token Saver:** Pastikan toggle RTK aktif untuk otomatis mengompres teks panjang dari terminal (`git diff`, `grep`, `log`) sebelum dikirim ke AI.
4. **Menghubungkan ke Tool Koding (seperti Cursor / Cline / Claude Code):**
   - Di pengaturan tool tersebut, ganti **Base URL** menjadi:
     `http://localhost:20128/v1`
   - Masukkan API Key yang tampil di dashboard 9Router Anda.

---

## 3. Cara Menggunakan **Playwright** (Otomasi & Testing Browser)

Playwright digunakan untuk menguji aplikasi web, mengambil tangkapan layar otomatis, atau merekam interaksi browser.

### Perintah Praktis yang Sering Dipakai:

1. **Merekam Aksi Menjadi Kode Testing (CodeGen):**  
   Ini fitur paling populer! Browser akan terbuka, dan setiap klik/ketikan Anda akan otomatis direkam menjadi kode:
   ```powershell
   npx playwright codegen https://google.com
   ```
2. **Mengambil Tangkapan Layar (Screenshot) Halaman Web Secara Otomatis:**
   ```powershell
   npx playwright screenshot https://flutter.dev flutter_web.png
   ```
3. **Membuka Halaman Web Cepat (Headful Browser):**
   ```powershell
   npx playwright open https://google.com
   ```
4. **Menjalankan Script Testing:**
   Jika nanti Anda membuat file skrip pengujian (misal untuk Flutter Web atau website):
   ```powershell
   npx playwright test
   ```

---

### Rangkuman Alur Kerja Sehari-hari:

- **Saat Koding di IDE**: Biarkan **Graphify** mencari file-nya (IN) dan **Ponytail** mengawasi kodingannya agar tetap ringkas (OUT).
- **Saat Kuota AI Habis**: Jalankan `9router` untuk mengalihkan ke provider cadangan.
- **Saat Ingin Menguji Tampilan Web**: Gunakan `npx playwright codegen` atau `npx playwright test`.
