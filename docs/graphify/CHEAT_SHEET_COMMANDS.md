# Cheat Sheet Perintah Graphify CLI

Ringkasan cepat perintah terminal Graphify untuk referensi harian.

---

## 1. Membangun & Memperbarui Graf

| Perintah | Deskripsi |
|---|---|
| `graphify .` | Memetakan seluruh codebase folder saat ini |
| `graphify extract . --code-only` | Memetakan hanya kode sumber lokal (AST murni, 100% tanpa API LLM) |
| `graphify update .` | Memperbarui graf hanya untuk file yang baru saja diubah |
| `graphify . --mode deep` | Ekstraksi hubungan semantik yang lebih mendalam |
| `graphify . --no-viz` | Lewati pembuatan `graph.html`, hanya simpan `graph.json` & laporan |
| `graphify . --force` | Paksa pembuatan ulang graf meskipun node hasil ekstraksi berkurang |

---

## 2. Query & Penelusuran Kode

| Perintah | Deskripsi |
|---|---|
| `graphify explain "<NamaKelas/Fungsi>"` | Menampilkan detail koneksi, komunitas, dan fungsi dari suatu node |
| `graphify path "<NodeA>" "<NodeB>"` | Menampilkan rute terpendek (*shortest path*) yang menghubungkan dua komponen |
| `graphify query "<pertanyaan>"` | Mencari subgraf terkait dengan pertanyaan bahasa alami |

---

## 3. Integrasi & Asisten AI

| Perintah | Deskripsi |
|---|---|
| `graphify antigravity install` | Pasang integrasi otomatis untuk Google Antigravity IDE |
| `graphify install --project` | Pasang skill Graphify ke tingkat project (`.agents/skills`) |
| `graphify hook install` | Pasang Git Hook (otomatis rebuild graf saat git commit & switch branch) |
| `graphify hook status` | Memeriksa status Git Hook yang aktif |
| `graphify uninstall` | Menghapus integrasi Graphify dari platform asisten |

---

## 4. Ekspor Graf ke Format Lain

| Perintah | Deskripsi |
|---|---|
| `graphify export callflow-html` | Ekspor diagram arsitektur call-flow Mermaid ke HTML |
| `graphify . --obsidian` | Ekspor graf menjadi catatan vault Obsidian |
| `graphify . --svg` | Ekspor visual graf ke format gambar vektor `.svg` |
| `graphify . --wiki` | Ekspor graf menjadi format wiki Markdown yang mudah dibaca |
