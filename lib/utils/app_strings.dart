/// Helper kelas kamus teks bilingual (English & Indonesia)
/// Menerapkan prinsip: istilah teknis & istilah populer (misal: Flashcard, Dataset, Dark Mode, Import, Export, Hotdog, IPA, CEFR, Excel)
/// tetap dipertahankan dalam bahasa aslinya saat mode Indonesia dipilih.
class AppStrings {
  // ==========================================
  // === 1. HOME SCREEN & STATS ===
  // ==========================================
  static String smartLearningApp(String lang) =>
      lang == 'id' ? 'Aplikasi Belajar Pintar' : 'Smart Learning App';

  static String datasets(String lang) =>
      lang == 'id' ? 'Dataset' : 'Datasets';

  static String totalCards(String lang) =>
      lang == 'id' ? 'Total Kartu' : 'Total Cards';

  static String startLearning(String lang) =>
      lang == 'id' ? 'MULAI BELAJAR' : 'START LEARNING';

  static String importDataset(String lang) =>
      lang == 'id' ? 'IMPORT DATASET' : 'IMPORT DATASET';

  static String settings(String lang) =>
      lang == 'id' ? 'PENGATURAN' : 'SETTINGS';

  // ==========================================
  // === 2. SETTINGS DIALOG ===
  // ==========================================
  static String settingsTitle(String lang) =>
      lang == 'id' ? 'Pengaturan' : 'Settings';

  static String darkMode(String lang) =>
      lang == 'id' ? 'Dark Mode' : 'Dark Mode';

  static String darkModeSubtitle(String lang) =>
      lang == 'id' ? 'Ganti tema gelap/terang' : 'Toggle dark/light theme';

  static String fontSizeSettings(String lang) =>
      lang == 'id' ? 'Pengaturan Ukuran Font' : 'Font Size Settings';

  static String platform(String lang) =>
      lang == 'id' ? 'Platform: ' : 'Platform: ';

  static String col1(String lang) =>
      lang == 'id' ? 'Kolom 1' : 'Column 1';

  static String col2_5(String lang) =>
      lang == 'id' ? 'Kolom 2–5' : 'Columns 2–5';

  static String col6_9(String lang) =>
      lang == 'id' ? 'Kolom 6–9' : 'Columns 6–9';

  static String col10_12(String lang) =>
      lang == 'id' ? 'Kolom 10–12' : 'Columns 10–12';

  // Backward compatibility aliases
  static String col23(String lang) => col2_5(lang);
  static String col45(String lang) => col2_5(lang);
  static String col6(String lang) => col6_9(lang);

  static String manageFiles(String lang) =>
      lang == 'id' ? 'Manage Files / Datasets' : 'Manage Files / Datasets';

  static String manageFilesSubtitle(String lang) =>
      lang == 'id' ? 'Edit nama atau hapus file import' : 'Edit name or delete imported files';

  static String manageFilesButton(String lang) =>
      lang == 'id' ? 'Kelola File' : 'Manage Files';

  // Language settings
  static String language(String lang) =>
      lang == 'id' ? 'Bahasa / Language' : 'Language';

  static String languageSubtitle(String lang) =>
      lang == 'id' ? 'Pilih bahasa tampilan aplikasi' : 'Select display language';

  // Export settings
  static String exportData(String lang) =>
      lang == 'id' ? 'Export Data' : 'Export Data';

  static String noDeckToExport(String lang) =>
      lang == 'id' ? 'Tidak ada deck untuk di-export.' : 'No decks available to export.';

  // ==========================================
  // === 3. DECK DETAIL SCREEN ===
  // ==========================================
  static String noDeckSelected(String lang) =>
      lang == 'id' ? 'Tidak ada deck yang dipilih' : 'No deck selected';

  static String addCustomCard(String lang) =>
      lang == 'id' ? 'Tambah Kartu Custom' : 'Add Custom Card';

  static String columns(String lang) =>
      lang == 'id' ? 'Kolom' : 'Columns';

  static String columnHeaders(String lang) =>
      lang == 'id' ? 'Header Kolom:' : 'Column Headers:';

  static String editColumnSettings(String lang) =>
      lang == 'id' ? 'Edit Pengaturan Kolom' : 'Edit Column Settings';

  static String activeDataset(String lang) =>
      lang == 'id' ? 'Dataset Aktif' : 'Active Dataset';

  static String cardsCount(String lang, int count) =>
      lang == 'id' ? '$count kartu' : '$count cards';

  static String learningRange(String lang) =>
      lang == 'id' ? 'Rentang Belajar' : 'Learning Range';

  static String availableData(String lang, int count) =>
      lang == 'id' ? 'Data tersedia: 1 - $count' : 'Available data: 1 - $count';

  static String libraryPreview(String lang) =>
      lang == 'id' ? 'Library Preview' : 'Library Preview';

  static String from(String lang) =>
      lang == 'id' ? 'Dari' : 'From';

  static String to(String lang) =>
      lang == 'id' ? 'Sampai' : 'To';

  static String orderMode(String lang) =>
      lang == 'id' ? 'Mode Urutan' : 'Order Mode';

  static String orderNormal(String lang) =>
      lang == 'id' ? 'Normal' : 'Normal';

  static String orderNormalDesc(String lang) =>
      lang == 'id' ? 'Urutan asli (sesuai Excel)' : 'Original order (as in Excel)';

  static String orderReverse(String lang) =>
      lang == 'id' ? 'Terbalik' : 'Reverse';

  static String orderReverseDesc(String lang) =>
      lang == 'id' ? 'Urutan terbalik' : 'Reversed order';

  static String orderRandom(String lang) =>
      lang == 'id' ? 'Acak' : 'Random';

  static String orderRandomDesc(String lang) =>
      lang == 'id' ? 'Urutan diacak' : 'Shuffled order';

  static String startLearningButton(String lang) =>
      lang == 'id' ? 'Mulai Belajar' : 'Start Learning';

  static String columnSettings(String lang) =>
      lang == 'id' ? 'Pengaturan Kolom' : 'Column Settings';

  static String columnOrder(String lang) =>
      lang == 'id' ? 'Urutan Kolom' : 'Column Order';

  // ==========================================
  // === 4. LEARNING PREVIEW SCREEN ===
  // ==========================================
  static String libraryPreviewTitle(String lang, String? deckName) {
    if (deckName == null) return 'Library Preview';
    return 'Library Preview - $deckName';
  }

  static String searchAllColumns(String lang) =>
      lang == 'id' ? 'Cari di semua kolom...' : 'Search in all columns...';

  static String refine(String lang) =>
      lang == 'id' ? 'Refine' : 'Refine';

  static String refineTooltip(String lang) =>
      lang == 'id' ? 'Refine (Urutan / Filter / Rentang)' : 'Refine (Sort / Filter / Range)';

  static String sortData(String lang) =>
      lang == 'id' ? 'Sort (Urutan Data)' : 'Sort (Data Order)';

  static String filterData(String lang) =>
      lang == 'id' ? 'Filter (Saring Data)' : 'Filter (Filter Data)';

  static String rangeData(String lang) =>
      lang == 'id' ? 'Range (Rentang Data)' : 'Range (Data Range)';

  static String activeFilter(String lang) =>
      lang == 'id' ? 'Aktif: ' : 'Active: ';

  static String manageActiveFilters(String lang) =>
      lang == 'id' ? 'Lihat & Kelola Filter Aktif' : 'View & Manage Active Filters';

  static String criteriaActive(String lang, int count) =>
      lang == 'id' ? '$count Kriteria Aktif' : '$count Active Criteria';

  static String dataPreview(String lang) =>
      lang == 'id' ? '👀 Data Preview' : '👀 Data Preview';

  static String tableAction(String lang) =>
      lang == 'id' ? 'Aksi' : 'Action';

  static String refreshSource(String lang) =>
      lang == 'id' ? 'Muat Ulang Sumber' : 'Refresh Source';

  // ==========================================
  // === 5. FLASHCARD SCREEN ===
  // ==========================================
  static String know(String lang) =>
      lang == 'id' ? 'Tahu' : 'Know';

  static String dontKnow(String lang) =>
      lang == 'id' ? 'Tidak Tahu' : "Don't Know";

  static String previous(String lang) =>
      lang == 'id' ? 'Sebelumnya' : 'Previous';

  static String next(String lang) =>
      lang == 'id' ? 'Selanjutnya' : 'Next';

  static String copyPrompt(String lang) =>
      lang == 'id' ? 'Salin Prompt' : 'Copy Prompt';

  static String promptCopied(String lang) =>
      lang == 'id' ? 'Prompt berhasil disalin ke clipboard!' : 'Prompt copied to clipboard!';

  static String noCardsAvailable(String lang) =>
      lang == 'id' ? 'Tidak ada kartu tersedia' : 'No cards available';

  static String noWordForPrompt(String lang) =>
      lang == 'id' ? 'Tidak ada kata untuk dibuatkan prompt.' : 'No word available to generate prompt.';

  // ==========================================
  // === 6. RESULT SCREEN ===
  // ==========================================
  static String learningResults(String lang) =>
      lang == 'id' ? 'Hasil Belajar' : 'Learning Results';

  static String sessionComplete(String lang) =>
      lang == 'id' ? 'Sesi Selesai!' : 'Session Complete!';

  static String totalStat(String lang) =>
      lang == 'id' ? 'Total' : 'Total';

  static String knownStat(String lang) =>
      lang == 'id' ? 'Tahu' : 'Known';

  static String unknownStat(String lang) =>
      lang == 'id' ? 'Belum Tahu' : 'Unknown';

  static String skipStat(String lang) =>
      lang == 'id' ? 'Lewati' : 'Skip';

  static String learnAgain(String lang) =>
      lang == 'id' ? 'Belajar Lagi' : 'Learn Again';

  static String reviewAgain(String lang) =>
      lang == 'id' ? 'Ulangi Belajar' : 'Review Again';

  static String home(String lang) =>
      lang == 'id' ? 'Beranda' : 'Home';

  static String deckDetails(String lang) =>
      lang == 'id' ? 'Detail Deck' : 'Deck Details';

  // ==========================================
  // === 7. DELETED DATA SCREEN ===
  // ==========================================
  static String deletedData(String lang) =>
      lang == 'id' ? 'Data Terhapus' : 'Deleted Data';

  static String restoreCard(String lang) =>
      lang == 'id' ? 'Kembalikan Kartu' : 'Restore Card';

  static String cardRestoredSuccess(String lang, String word) =>
      lang == 'id'
          ? 'Kartu "$word" berhasil dikembalikan ke posisi aslinya'
          : 'Card "$word" restored to original position successfully';

  static String cardRestoreFailed(String lang) =>
      lang == 'id' ? 'Gagal mengembalikan kartu' : 'Failed to restore card';

  static String formatColumnHeader(String header, String lang) {
    final lower = header.trim().toLowerCase();
    if (lower == 'aksi' || lower == 'action' || lower == 'actions') {
      return lang == 'id' ? 'Aksi' : 'Action';
    }
    // Preservasi header Excel asli: jangan terjemahkan kata/word, arti/meaning, dsb.
    return header;
  }

  static String selectColToFilter(String lang) =>
      lang == 'id' ? 'Pilih Kolom untuk Difilter:' : 'Select Column to Filter:';

  static String filterValuesFor(String lang, String colName) =>
      lang == 'id' ? 'Centang nilai yang ingin ditampilkan untuk "$colName":' : 'Check values to display for "$colName":';

  static String emptyValue(String lang) =>
      lang == 'id' ? '(Kosong)' : '(Empty)';

  static String noValuesToFilter(String lang) =>
      lang == 'id' ? 'Tidak ada nilai untuk difilter pada kolom ini.' : 'No values to filter in this column.';

  static String allColumns(String lang) =>
      lang == 'id' ? 'Semua Kolom' : 'All Columns';

  // ==========================================
  // === 8. GENERAL ACTIONS & NOTIFICATIONS ===
  // ==========================================
  static String cancel(String lang) =>
      lang == 'id' ? 'Batal' : 'Cancel';

  static String save(String lang) =>
      lang == 'id' ? 'Simpan' : 'Save';

  static String close(String lang) =>
      lang == 'id' ? 'Tutup' : 'Close';

  static String back(String lang) =>
      lang == 'id' ? 'Kembali' : 'Back';

  static String delete(String lang) =>
      lang == 'id' ? 'Hapus' : 'Delete';

  static String confirm(String lang) =>
      lang == 'id' ? 'Konfirmasi' : 'Confirm';

  static String success(String lang) =>
      lang == 'id' ? 'Berhasil' : 'Success';

  static String error(String lang) =>
      lang == 'id' ? 'Terjadi kesalahan' : 'An error occurred';

  static String fontSizeError(String lang) =>
      lang == 'id' ? 'Ukuran font harus lebih dari 0' : 'Font size must be greater than 0';

  static String fontSizeSaved(String lang) =>
      lang == 'id' ? 'Pengaturan ukuran font berhasil disimpan' : 'Font size settings saved successfully';

  // ==========================================
  // === 9. DIALOGS & SPECIALIZED UI ===
  // ==========================================
  static String sortDataTitle(String lang) =>
      lang == 'id' ? 'Urutkan Data (Sort)' : 'Sort Data';

  static String selectColToSort(String lang) =>
      lang == 'id' ? '1. Pilih Kolom untuk Diurutkan:' : '1. Select Column to Sort:';

  static String typePriorityTitle(String lang) =>
      lang == 'id' ? '2. Atur Prioritas Tipe (Tarik / Drag untuk ubah urutan):' : '2. Set Type Priority (Drag to reorder):';

  static String typePriorityDesc(String lang) =>
      lang == 'id' ? 'Tipe paling atas memiliki prioritas tertinggi saat diurutkan.' : 'Top type has the highest priority when sorted.';

  static String priorityDirection(String lang) =>
      lang == 'id' ? '3. Arah Prioritas:' : '3. Priority Direction:';

  static String selectSortDirection(String lang) =>
      lang == 'id' ? '2. Pilih Arah Urutan:' : '2. Select Sort Direction:';

  static String applySort(String lang) =>
      lang == 'id' ? 'Terapkan Urutan' : 'Apply Sort';

  static String filterDataTitle(String lang) =>
      lang == 'id' ? 'Filter Data' : 'Filter Data';

  static String applyFilter(String lang) =>
      lang == 'id' ? 'Terapkan Filter' : 'Apply Filter';

  static String resetFilter(String lang) =>
      lang == 'id' ? 'Reset Filter' : 'Reset Filter';

  static String resetAllFilters(String lang) =>
      lang == 'id' ? 'Reset Semua Filter' : 'Reset All Filters';

  static String rangeDialogTitle(String lang) =>
      lang == 'id' ? 'Rentang Belajar (Range)' : 'Learning Range';

  static String fromRow(String lang) =>
      lang == 'id' ? 'Dari Baris' : 'From Row';

  static String toRow(String lang) =>
      lang == 'id' ? 'Sampai Baris' : 'To Row';

  static String applyRange(String lang) =>
      lang == 'id' ? 'Terapkan Rentang' : 'Apply Range';

  static String editRowTitle(String lang, int row) =>
      lang == 'id' ? 'Edit Baris #$row' : 'Edit Row #$row';

  static String saveChanges(String lang) =>
      lang == 'id' ? 'Simpan Perubahan' : 'Save Changes';

  static String deleteCardTitle(String lang) =>
      lang == 'id' ? 'Hapus Kartu?' : 'Delete Card?';

  static String deleteCardConfirm(String lang, String word) =>
      lang == 'id'
          ? 'Apakah Anda yakin ingin menghapus kartu "$word" dan memindahkannya ke Deleted Data?'
          : 'Are you sure you want to delete card "$word" and move it to Deleted Data?';

  static String editCard(String lang) =>
      lang == 'id' ? 'Edit Kartu' : 'Edit Card';

  static String deleteCard(String lang) =>
      lang == 'id' ? 'Hapus Kartu' : 'Delete Card';

  static String tapToReveal(String lang) =>
      lang == 'id' ? 'Ketuk untuk melihat' : 'Tap to reveal';

  static String finish(String lang) =>
      lang == 'id' ? 'Selesai' : 'Finish';

  static String searchDeletedData(String lang) =>
      lang == 'id' ? 'Cari di deleted data (kata, arti, type, dll)...' : 'Search in deleted data (word, meaning, type, etc)...';

  static String deletedDataRecords(String lang) =>
      lang == 'id' ? '🗑️ Catatan Data Terhapus' : '🗑️ Deleted Data Records';

  static String backToCustomDb(String lang) =>
      lang == 'id' ? 'Kembali ke Custom Database' : 'Back to Custom Database';

  static String editDeletedRowTitle(String lang, int row) =>
      lang == 'id' ? 'Edit Deleted Baris #$row' : 'Edit Deleted Row #$row';

  static String editingTrashWarning(String lang) =>
      lang == 'id'
          ? 'Anda sedang mengedit data yang berada di Deleted Data (Trash).'
          : 'You are editing data currently in Deleted Data (Trash).';

  static String changesSavedSuccess(String lang) =>
      lang == 'id' ? 'Perubahan data berhasil disimpan' : 'Changes saved successfully';

  static String rowsDeletedCount(String lang, int count) =>
      lang == 'id' ? '$count baris terhapus' : '$count rows deleted';

  static String rowsPerPage(String lang) =>
      lang == 'id' ? 'Baris/hal: ' : 'Rows/page: ';

  static String noDeletedData(String lang) =>
      lang == 'id' ? 'Tidak ada data yang dihapus (Deleted Data kosong).' : 'No deleted data (Trash is empty).';

  static String refreshRowTooltip(String lang) =>
      lang == 'id' ? 'Refresh baris ini dari dataset sumber' : 'Refresh this row from source dataset';

  static String showingEntries(String lang, int start, int end, int total) =>
      lang == 'id' ? 'Menampilkan $start - $end dari $total data' : 'Showing $start - $end of $total entries';

  static String pageOfTotal(String lang, int page, int total) =>
      lang == 'id' ? 'Hal $page dari $total' : 'Page $page of $total';

  static String jumpToPage(String lang) =>
      lang == 'id' ? 'Lompat ke Halaman' : 'Jump to Page';

  static String enterPageNumber(String lang, int totalPages) =>
      lang == 'id' ? 'Masukkan nomor halaman (1 s/d $totalPages):' : 'Enter page number (1 to $totalPages):';

  static String typePageNumber(String lang) =>
      lang == 'id' ? 'Ketik nomor halaman...' : 'Type page number...';

  static String go(String lang) =>
      lang == 'id' ? 'Lanjut' : 'Go';

  static String addNewWords(String lang) =>
      lang == 'id' ? 'Tambah Kata Baru' : 'Add New Words';

  static String addRow(String lang) =>
      lang == 'id' ? 'Tambah baris' : 'Add row';

  static String deleteRow(String lang) =>
      lang == 'id' ? 'Hapus baris' : 'Delete row';

  static String wordRequired(String lang) =>
      lang == 'id' ? 'Kata wajib diisi' : 'Word is required';

  static String maxRowsReached(String lang, int max) =>
      lang == 'id' ? 'Maksimal $max baris tercapai' : 'Maximum $max rows reached';

  static String showCount(String lang) =>
      lang == 'id' ? 'Tampilkan: ' : 'Show: ';

  static String exportSettingsTitle(String lang) =>
      lang == 'id' ? 'Pengaturan Kolom Export Excel' : 'Excel Export Column Settings';

  static String exportFileName(String lang) =>
      lang == 'id' ? 'Nama File Hasil Export:' : 'Export File Name:';

  static String exportDragHint(String lang) =>
      lang == 'id'
          ? 'Tarik (drag) untuk mengubah urutan kolom. Centang kolom yang ingin diekspor.'
          : 'Drag to reorder columns. Check columns you want to export.';

  static String selectAll(String lang) =>
      lang == 'id' ? 'Pilih Semua' : 'Select All';

  static String deselectAll(String lang) =>
      lang == 'id' ? 'Hapus Semua' : 'Deselect All';

  static String resetOrder(String lang) =>
      lang == 'id' ? 'Reset Urutan' : 'Reset Order';

  static String exportFooterInfo(String lang, int enabled, int total) =>
      lang == 'id'
          ? '$enabled dari $total kolom akan diekspor ke file Excel.'
          : '$enabled of $total columns will be exported to Excel.';

  static String selectAtLeastOneColumn(String lang) =>
      lang == 'id' ? 'Pilih setidaknya 1 kolom untuk diekspor.' : 'Select at least 1 column to export.';

  static String enterFileNamePrompt(String lang) =>
      lang == 'id' ? 'Masukkan nama file terlebih dahulu.' : 'Please enter a file name first.';

  static String importMappingTitle(String lang) =>
      lang == 'id' ? 'Pemetaan Kolom Import' : 'Map Import Columns';

  static String empty(String lang) =>
      lang == 'id' ? '(Kosong)' : '(Empty)';

  static String duplicateExcelColumn(String lang, String col) =>
      lang == 'id'
          ? 'Kolom Excel "$col" dipilih lebih dari satu kali!'
          : 'Excel column "$col" is selected more than once!';

  static String selectAtLeastOneImport(String lang) =>
      lang == 'id' ? 'Pilih minimal satu kolom Excel untuk diimpor.' : 'Select at least one Excel column to import.';

  static String writingPractice(String lang) =>
      lang == 'id' ? 'Latihan Menulis' : 'Writing Practice';

  static String scoreLabel(String lang, int score) =>
      lang == 'id' ? 'Skor: $score' : 'Score: $score';

  static String wordToWritePrompt(String lang) =>
      lang == 'id' ? 'Kata yang harus ditulis:' : 'Word to write:';

  static String typeWordHere(String lang) =>
      lang == 'id' ? 'Ketik kata di sini...' : 'Type word here...';

  static String writeAnswerHere(String lang) =>
      lang == 'id' ? 'Tuliskan jawaban...' : 'Write answer...';

  static String correct(String lang) =>
      lang == 'id' ? 'Benar' : 'Correct';

  static String incorrectTryAgain(String lang) =>
      lang == 'id' ? 'Salah, coba lagi' : 'Incorrect, try again';

  static String checkAnswer(String lang) =>
      lang == 'id' ? 'Cek Jawaban' : 'Check Answer';

  static String fontSizeSettingsTitle(String lang) =>
      lang == 'id' ? 'Pengaturan Ukuran Font' : 'Font Size Settings';

  static String noDatasets(String lang) =>
      lang == 'id' ? 'Belum ada dataset' : 'No datasets yet';

  static String importExcelPrompt(String lang) =>
      lang == 'id' ? 'Impor file Excel untuk memulai' : 'Import an Excel file to get started';
}


