# Task Breakdown — 1 Aplikasi dengan 2 Mode & Database Terpisah

Daftar tugas implementasi untuk memisahkan **Flashcard Language** dan **Flashcard All** ke dalam satu aplikasi berbasis Hub Launcher (`MainHubScreen`).

---

## Daftar Tugas (Checklist)

### Tahap 1: Model & Enums
- [x] Buat berkas `lib/models/flashcard_app_mode.dart`:
  - [x] Definisikan enum `FlashcardAppMode { language, all }`.
  - [x] Tambahkan properti helper (title, subtitle, storagePrefix, icons, color theme, enableWritingPractice).

### Tahap 2: Database Layer (Storage Isolation)
- [x] Perbarui `lib/services/storage_service.dart`:
  - [x] Tambahkan parameter `mode` pada constructor `StorageService({this.mode = FlashcardAppMode.language})`.
  - [x] Gunakan namespace terisolasi: `yorflashcard_lang_*` untuk Language dan `yorflashcard_all_*` untuk All.
  - [x] Tambahkan logika fallback/migrasi data lama (`yorflashcard_decks` -> `yorflashcard_lang_decks`) agar data pengguna sebelumnya tidak hilang.
  - [x] Pisahkan konfigurasi deck (`deckConfig`), reference deck ID, dan last selected deck ID per mode.
  - [x] Sediakan hooks testing untuk mock SharedPreferences.

### Tahap 3: State Management (`DeckProvider`)
- [x] Perbarui `lib/providers/app_providers.dart`:
  - [x] Tambahkan variabel `_currentMode` bertipe `FlashcardAppMode`.
  - [x] Buat getter `currentMode`.
  - [x] Buat method `setMode(FlashcardAppMode mode)` yang memperbarui `_storageService` dan memanggil `loadDecks()`.
  - [x] Sesuaikan pembuatan default 'Custom Mode' untuk masing-masing mode (`custom_mode_deck_default`).
  - [x] Tambahkan helper `getLastSelectedDeckId()` dan `setLastSelectedDeckId()`.

### Tahap 4: String Lokalisasi (i18n)
- [x] Perbarui `lib/utils/app_strings.dart`:
  - [x] Tambahkan teks lokalisasi ID & EN untuk Hub (`hubTitle`, `hubSubtitle`, `backToHub`).
  - [x] Tambahkan teks untuk kartu `modeLanguageTitle`, `modeLanguageDesc`.
  - [x] Tambahkan teks untuk kartu `modeAllTitle`, `modeAllDesc`.

### Tahap 5: Antarmuka Pengguna (UI Layer)
- [x] Buat berkas `lib/screens/main_hub_screen.dart` (terinspirasi dari `yormath_home.dart`):
  - [x] Header dengan Logo aplikasi, Judul Hub, tombol Toggle Bahasa dan Toggle Tema.
  - [x] Kartu interaktif untuk **Flashcard Language** (aksen warna Indigo).
  - [x] Kartu interaktif untuk **Flashcard All** (aksen warna Teal/Emerald).
  - [x] Penanganan klik kartu: set mode pada `DeckProvider`, lalu navigasi ke `HomeScreen`.
- [x] Perbarui `lib/screens/home_screen.dart`:
  - [x] Tambahkan tombol kembali ke Hub (`Back to Hub` / Icon Panah) dan Badge Mode aktif di bagian atas.
  - [x] Tampilkan nama mode aktif di header halaman utama.
- [x] Perbarui `lib/screens/flashcard_screen.dart`:
  - [x] Modifikasi `_buildScoreAndPracticeAction`:
    - Jika `currentMode == FlashcardAppMode.all`, jangan tampilkan tombol Latihan Menulis (pensil); tampilkan hanya badge skor.
    - Jika `currentMode == FlashcardAppMode.language`, tampilkan tombol Latihan Menulis seperti biasa.
- [x] Perbarui `lib/screens/deck_detail_screen.dart`:
  - [x] Simpan last selected deck ID menggunakan instance mode provider aktif.
  - [x] Buat header dialog tambah kartu manual dinamis (`Kata/Arti` di Language, `Pertanyaan/Jawaban` di All).

### Tahap 6: Entry Point Aplikasi
- [x] Perbarui `lib/main.dart`:
  - [x] Ubah default `home` MaterialApp menjadi `const MainHubScreen()`.

### Tahap 7: Pengujian & Validasi Kualitas
- [x] Buat unit test di `test/flashcard_mode_storage_test.dart` untuk menguji:
  - [x] Isolasi penyimpanan antara mode `language` dan `all`.
  - [x] Tidak terjadi kebocoran data deck antar mode.
  - [x] Migrasi aman data legacy ke mode language.
- [x] Perbarui `test/widget_test.dart` untuk menguji rendering `MainHubScreen`.
- [x] Jalankan unit test: `flutter test` (Semua 52 test lulus / passed!).
- [x] **Jalankan `flutter analyze`** dan pastikan *zero errors / warnings* (`No issues found!`).
- [x] Pastikan **TIDAK menjalankan `git checkout`**.

### Tahap 8: Tombol Toggle Mode Tampilan `{1}` / `{All}` (Fitur Baru)
- [x] Tambahkan tombol kotak transparan `{1}` / `{All}` di AppBar sebelah kiri (samping tombol Back).
- [x] Default awal selalu mode `{1}`.
- [x] Pada mode `{1}`:
  - [x] Saat berpindah kartu (Tahu, Tidak Tahu, Next, Previous), jika kartu sedang terbuka di sisi belakang (semua kolom), kartu berikutnya/sebelumnya otomatis di-reset kembali ke 1 kolom (sisi depan).
  - [x] Jika sudah di kolom 1, tetap di kolom 1.
- [x] Pada mode `{All}`:
  - [x] Saat berpindah kartu (Tahu, Tidak Tahu, Next, Previous), jika kartu sedang terbuka di sisi belakang (semua kolom), kartu berikutnya/sebelumnya tetap mempertahankan tampilan semua kolom.
  - [x] Jika sedang di kolom 1, tetap di kolom 1.
- [x] Tambahkan widget test untuk memverifikasi toggle `{1}` / `{All}` dan transisi 4 tombol navigasi di `test/flashcard_screen_test.dart`.
