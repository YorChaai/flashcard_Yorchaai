# Panduan Lengkap Graphify (Knowledge Graph untuk Codebase)

## 1. Apa itu Graphify?
**Graphify** adalah tool berbasis analisis AST (*Abstract Syntax Tree*) dan Knowledge Graph yang memetakan seluruh proyek Anda (source code, dokumentasi, arsitektur) menjadi jaringan graf terstruktur yang dapat ditelusuri (*traversable knowledge graph*).

Alih-alih bergantung pada *vector embeddings* (RAG konvensional) yang sering kehilangan konteks relasi hierarkis antar file, Graphify memetakan relasi kode secara **deterministik dan lokal** menggunakan **Tree-Sitter**.

---

## 2. Mengapa Graphify Berbeda dari RAG / Vector Biasa?

| Fitur | Vector Search / RAG Tradisional | Graphify (Knowledge Graph) |
|---|---|---|
| **Metode Parsing** | Chunking teks acak + vector embedding | AST deterministik via Tree-Sitter (memahami syntax kode) |
| **Kebutuhan LLM Token** | Boros token API untuk meng-embed kode | **0 Token / 100% Gratis & Lokal** untuk semua file kode |
| **Privasi Kode** | Tergantung vector DB/API provider | Kode tidak pernah keluar dari komputer Anda |
| **Pencarian Hubungan** | Kemiripan semantik (sering meleset) | Menelusuri jalur pasti (*exact path traversal* antar fungsi/kelas) |
| **Penjelasan Relasi** | Tidak ada label pasti | Setiap relasi berlabel `EXTRACTED` (pasti) atau `INFERRED` |
| **Visualisasi** | Jarang ada visualisasi interaktif | Disediakan `graph.html` interaktif (bisa dibuka langsung di browser) |

---

## 3. Apa yang Dihasilkan Setelah Graphify Dijalankan?
Ketika dijalankan pada project (`graphify .`), Graphify akan membuat folder output `graphify-out/` berisi 3 artefak utama:

1. **`graphify-out/graph.html`**  
   Visualisasi graf interaktif yang bisa langsung dibuka di browser Google Chrome / Edge:
   - Menampilkan node konsep dan kelas dalam codebase.
   - Pewarnaan otomatis berdasarkan komunitas subsistem (*Leiden clustering*).
   - Fitur filter, pencarian, dan penyorotan simpul utama (*God Nodes*).
2. **`graphify-out/GRAPH_REPORT.md`**  
   Laporan ringkasan arsitektur:
   - **God Nodes**: Komponen/kelas yang paling banyak menjadi pusat aliran logika.
   - **Surprising Connections**: Hubungan tak terduga lintas modul.
   - **The "Why"**: Catatan penting (`# NOTE:`, `# WHY:`, `# HACK:`) yang ditangkap otomatis.
   - **Suggested Questions**: Rekomendasi pertanyaan arsitektur yang bisa dijawab oleh graf.
3. **`graphify-out/graph.json`**  
   Struktur basis data graf lengkap yang digunakan AI Assistant atau CLI untuk menjawab pertanyaan tanpa harus membaca ulang semua file dari nol.

---

## 4. Dukungan untuk Proyek Ini (Dart / Flutter)
Proyek **Flashcard** ini dibuat menggunakan **Dart & Flutter**.
Graphify secara bawaan memiliki grammar Tree-Sitter untuk **`.dart`** bersama 36+ bahasa pemrograman lainnya. Hal ini berarti:
- Seluruh widget (`ImportPreviewScreen`, `DeckDetailScreen`, dll.), model data, service, dan provider akan dipetakan relasi impor, pewarisan (*extends/implements*), dan pemanggilannya secara instan tanpa perlu API key berbayar.

---

## 5. Indeks Dokumentasi di Folder Ini
Berikut berkas panduan yang telah disiapkan untuk Anda:

- 📄 [PANDUAN_INSTALASI_WINDOWS.md](file:///d:/2.%20Organize/1.%20Projects/flashcard/docs/graphify/PANDUAN_INSTALASI_WINDOWS.md)  
  Panduan instalasi paket di Windows 11/10 dan integrasi ke Google Antigravity IDE.
- 📄 [PANDUAN_PENGGUNAAN_FLUTTER.md](file:///d:/2.%20Organize/1.%20Projects/flashcard/docs/graphify/PANDUAN_PENGGUNAAN_FLUTTER.md)  
  Tata cara menjalankan ekstraksi graf di proyek Flutter Flashcard, cara query, dan navigasi kode.
- 📄 [CHEAT_SHEET_COMMANDS.md](file:///d:/2.%20Organize/1.%20Projects/flashcard/docs/graphify/CHEAT_SHEET_COMMANDS.md)  
  Daftar perintah cepat CLI (`explain`, `path`, `query`, `watch`, dll.).
- 📄 [CATATAN_BELAJAR_DAN_SOLUSI_ERROR.md](file:///d:/2.%20Organize/1.%20Projects/flashcard/docs/graphify/CATATAN_BELAJAR_DAN_SOLUSI_ERROR.md)  
  Rangkuman nyata proses instalasi kita: masalah/error yang dialami, penyebab teknis, dan solusinya.
- 📄 [KONSEP_IN_DAN_OUT_GRAPHIFY.md](file:///d:/2.%20Organize/1.%20Projects/flashcard/docs/graphify/KONSEP_IN_DAN_OUT_GRAPHIFY.md)  
  Penjelasan sederhana mengapa Graphify bekerja di sisi "IN" (membaca arsitektur) dan output-nya tetap "OUT" (kodingan), serta bagaimana cara menghemat ribuan token.
- 📄 [PANDUAN_SETUP_DAN_WORKFLOW_LENGKAP.md](file:///d:/2.%20Organize/1.%20Projects/flashcard/docs/graphify/PANDUAN_SETUP_DAN_WORKFLOW_LENGKAP.md)  
  **Buku Panduan Master (2.000+ Kata):** Cara pasang di folder/proyek lain, alur kerja harian 5 langkah, cara kerja mendalam `graphify update`, serta operasional praktis Ponytail, 9Router, dan Playwright.
