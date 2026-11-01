# Rencana Implementasi: 1 Aplikasi dengan 2 Mode (Flashcard Language & Flashcard All) dan Database Terisolasi

Dokumen ini adalah acuan arsitektur dan teknis pelaksanaan penggabungan dua mode pembelajaran ke dalam satu aplikasi Flutter (`YorFlashCard`), mengadopsi pola launcher hub dari referensi `D:\Aplikasi\mathall` (`yormath_home.dart`).

---

## 1. Latar Belakang & Kebutuhan Pengguna

1. **Satu Aplikasi Terpadu (Single App / 1 APK)**:
   - Pengguna menginginkan satu aplikasi yang dapat memuat dua varian/ruang flashcard sekaligus, tanpa perlu meng-install dua aplikasi APK berbeda.
2. **Dua Mode Pembelajaran**:
   - **Flashcard Language**: Khusus untuk pembelajaran bahasa (kosakata, pelafalan, arti, dan **Writing Practice / Latihan Menulis** aktif).
   - **Flashcard All**: Flashcard serbaguna/umum (rumus, tanya-jawab ujian, materi bebas, sains, sejarah, dll.) di mana fitur **Writing Practice ditiadakan/disembunyikan** agar fokus pada kartu umum.
3. **Pemisahan Database 100% (Isolated Storage)**:
   - Data deck, kartu, konfigurasi, riwayat, dan data terhapus di mode *Language* dan mode *All* harus **benar-benar terpisah** dan tidak boleh saling bercampur.
4. **Referensi UI/UX**:
   - Mengadopsi pola dari `D:\Aplikasi\mathall\lib\yormath_home.dart`, di mana saat pertama kali membuka aplikasi, pengguna disuguhkan **Hub Launcher Screen** dengan kartu pilihan modul, serta kontrol tema dan bahasa di bagian atas.

---

## 2. Analisis Arsitektur Teknis

### A. Pola Navigasi & Hub Launcher (`MainHubScreen`)
- Aplikasi di `main.dart` akan menjadikan `MainHubScreen` sebagai layar awal (`home:`).
- `MainHubScreen` menampilkan:
  - Header dengan logo aplikasi, judul *YorFlashCard Hub*, dan tombol toggle Bahasa & Tema.
  - Kartu pilihan **Flashcard Language** (Aksen Indigo/Ungu).
  - Kartu pilihan **Flashcard All** (Aksen Teal/Cyan).
- Saat salah satu kartu dipilih:
  1. `DeckProvider` mengubah mode aktif (`setMode(FlashcardAppMode.language)` atau `setMode(FlashcardAppMode.all)`).
  2. Navigasi menuju `HomeScreen` dengan AppBar yang memiliki tombol kembali ke Hub (`Back to Hub`).

### B. Isolasi Database pada `StorageService`
- Saat ini `StorageService` menggunakan prefix key tetap:
  - `_decksKey = 'yorflashcard_decks'`
  - `_refDeckKey = 'yorflashcard_ref_deck_id'`
  - `_lastDeckKey = 'yorflashcard_last_deck_id'`
  - `_deckConfigsPrefix = 'yorflashcard_deck_config_'`
- **Perubahan yang Diterapkan**:
  - `StorageService` menerima parameter `FlashcardAppMode mode`.
  - Prefix storage diubah berdasarkan mode:
    - Mode Language: `yorflashcard_lang_`
    - Mode All: `yorflashcard_all_`
  - **Migrasi Aman (Zero Data Loss)**:
    - Untuk mode `language`, jika data `yorflashcard_lang_decks` belum ada namun ada data lama `yorflashcard_decks`, data lama otomatis dimigrasikan ke mode `language` sehingga kartu pengguna yang sudah ada tidak hilang.
    - Untuk mode `all`, murni menggunakan namespace `yorflashcard_all_*`.

### C. State Management (`DeckProvider`)
- `DeckProvider` menyimpan status `_currentMode` bertipe enum `FlashcardAppMode`.
- Ketika mode berubah via `setMode(FlashcardAppMode newMode)`:
  - Menginisialisasi ulang `StorageService` dengan mode baru.
  - Memanggil `loadDecks()` untuk memuat kumpulan deck dari namespace yang sesuai.
  - Mereset selected deck dan state konfigurasi ke mode yang sedang aktif.

### D. Penyesuaian Fitur (Writing Practice pada `FlashcardScreen`)
- Di `FlashcardScreen`:
  - Tombol aksi pensil `_buildScoreAndPracticeAction` yang memicu `_showWritingPracticeDialog` akan memeriksa `deckProvider.currentMode`.
  - **Jika mode == `FlashcardAppMode.all`**: Tombol Latihan Menulis disembunyikan; hanya menampilkan badge skor kartu.
  - **Jika mode == `FlashcardAppMode.language`**: Tombol Latihan Menulis tetap aktif seperti semula.

---

## 3. Rencana Perubahan Berkas (File Changes)

| No | Berkas | Status | Deskripsi Perubahan |
|---|---|---|---|
| 1 | `lib/models/flashcard_app_mode.dart` | **Baru** | Enum `FlashcardAppMode` (`language`, `all`) beserta metadata (nama, deskripsi, prefix database). |
| 2 | `lib/services/storage_service.dart` | **Ubah** | Dukungan multi-namespace database per mode dan migrasi fallback data lama. |
| 3 | `lib/providers/app_providers.dart` | **Ubah** | Tambahkan `currentMode`, `setMode(FlashcardAppMode)` pada `DeckProvider`, serta inisialisasi deck default per mode. |
| 4 | `lib/screens/main_hub_screen.dart` | **Baru** | Hub Launcher Screen terinspirasi dari `yormath_home.dart` dengan kartu interaktif Language & All. |
| 5 | `lib/screens/home_screen.dart` | **Ubah** | Tombol navigasi kembali ke Hub Screen, penyesuaian header judul berdasarkan mode aktif. |
| 6 | `lib/screens/flashcard_screen.dart` | **Ubah** | Logika kondisional: sembunyikan fitur Writing Practice jika mode aktif adalah `FlashcardAppMode.all`. |
| 7 | `lib/utils/app_strings.dart` | **Ubah** | Tambahkan string lokalisasi bahasa (ID & EN) untuk Hub, mode Language, dan mode All. |
| 8 | `lib/main.dart` | **Ubah** | Arahkan entry point awal (`home`) ke `MainHubScreen`. |
| 9 | `test/flashcard_mode_storage_test.dart` | **Baru** | Unit test untuk memverifikasi isolasi database dan pemisahan storage antar mode. |

---

## 4. Rencana Verifikasi & Uji Kualitas

1. **Uji Isolasi Database**:
   - Menambahkan deck baru di mode *Flashcard Language*.
   - Pindah ke mode *Flashcard All* dan pastikan deck dari mode *Language* tidak muncul.
   - Menambahkan deck baru di mode *Flashcard All*.
   - Pindah kembali ke *Language* dan pastikan hanya deck *Language* yang terlihat.
2. **Uji Writing Practice**:
   - Pada mode *Flashcard Language*, buka kartu belajar -> pastikan tombol Latihan Menulis (pensil) muncul dan dialog menulis dapat dibuka.
   - Pada mode *Flashcard All*, buka kartu belajar -> pastikan tombol Latihan Menulis tidak muncul sama sekali.
3. **Kepatuhan Aturan Proyek**:
   - **Wajib menjalankan `flutter analyze`** dan pastikan *zero errors / warnings*.
   - **Dilarang melakukan `git checkout`** setelah selesai coding.

