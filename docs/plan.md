Berikut versi yang sudah dirapikan supaya lebih jelas untuk diberikan ke AI/developer, tanpa mengubah maksud utama:

Halo, saya mau menambahkan beberapa fitur di **Library Preview**, yaitu **Sort, Filter, Edit, dan Refresh**. Untuk sekarang fokus dulu ke fitur-fitur ini di Library Preview. Jangan langsung mengerjakan bagian Learning Game.

### 1. Fitur Edit di Library Preview

Di Library Preview terdapat banyak kolom, salah satunya adalah kolom **Aksi**. Saya ingin menambahkan tombol **Edit** di kolom Aksi.

Alur yang saya inginkan:

1. Jalankan aplikasi.
2. Pilih **Active Dataset**.
3. Untuk contoh, saya akan menggunakan dataset dari **Import Database** yang saat ini berisi sekitar **14.000 kata**.
4. Masuk ke **Library Preview**.
5. Di tabel Library Preview terdapat banyak kolom, seperti:
   - No
   - Kata
   - Arti
   - IPA
   - Type
   - Cerf
   - Top
   - Score
   - Aksi

Di kolom **Aksi**, tambahkan tombol **Edit**.

Ketika tombol Edit ditekan, yang diedit harus **satu baris penuh**, bukan hanya satu kolom.

Kemudian tampilkan **popup/form edit** yang berisi seluruh data pada baris tersebut. Semua field yang memang merupakan data dapat diedit, misalnya:

- Kata
- Arti
- IPA
- Type
- Cerf
- Top
- Score
- dan field lain yang memang relevan

Untuk kolom **No**, saya belum yakin apakah sebaiknya bisa diedit atau tidak. Menurut saya, nomor sebaiknya **tidak perlu diedit secara manual** apabila nomor tersebut hanya merupakan identifier/urutan data. Silakan cek struktur kode dan database terlebih dahulu untuk menentukan pendekatan yang paling aman.

Yang penting, jangan hanya mengganti tampilan. Cek bagaimana data tersebut disimpan dan diperbarui agar setelah proses Edit dilakukan, perubahan benar-benar tersimpan ke database/dataset yang sesuai.

---

### 2. Perbedaan Import Database dan Custom Database

Ada dua sumber database yang perlu diperhatikan:

- **Import Database**
- **Custom Database**

Untuk **Import Database**, saat ini tidak perlu ditambahkan fitur Refresh.

Yang perlu diperbaiki terutama adalah **Custom Database**.

Custom Database pada dasarnya mengambil/join data dari database lain. Saat ini setelah data masuk ke Custom Database, data yang ditampilkan bisa dipanggil dan dihapus, dan bagian tersebut sudah berjalan dengan baik.

Namun ada dua fungsi yang saat ini belum ada/hilang:

1. **Edit**
2. **Refresh**

#### Edit

Custom Database juga harus memiliki fungsi Edit seperti yang dijelaskan sebelumnya.

Ketika sebuah data diedit dari Custom Database, pastikan perubahan tersebut mengikuti sumber data yang memang seharusnya menjadi sumbernya. Jangan sampai mekanisme Edit membuat data menjadi tidak sinkron antara database sumber dan Custom Database.

#### Refresh

Fitur **Refresh hanya perlu dibuat untuk Custom Database**, tidak perlu untuk Import Database.

Konsepnya:

- Custom Database mengambil/menggabungkan data dari database sumber.
- Jika data sumber berubah, Custom Database tidak harus selalu melakukan refresh otomatis.
- User dapat menekan tombol **Refresh** pada kolom Aksi di Custom Database.
- Setelah Refresh dijalankan, Custom Database harus mengambil ulang data terbaru dari sumber database dan memperbarui tampilan/data yang digunakan Custom Database.
- Data yang sudah dihapus dari sumber juga harus tercermin setelah Refresh.
- Data baru atau perubahan data dari sumber juga harus ikut diperbarui.

Jadi, sederhananya:

**Database sumber → Custom Database → Refresh → ambil kondisi/data terbaru dari database sumber**

Tolong cek terlebih dahulu implementasi Custom Database yang sekarang sebelum mengubahnya. Jangan merombak mekanisme yang sudah berjalan dengan baik hanya untuk menambahkan Refresh.

---

### 3. Sort dan Filter

Setelah fitur Edit dan Refresh selesai, saya juga ingin menambahkan fitur **Sort dan Filter**.

Fitur ini nantinya berlaku baik untuk:

- Import Database
- Custom Database

Untuk sekarang, **implementasikan terlebih dahulu di Library Preview saja**.

Kolom yang harus bisa digunakan untuk Sort/Filter:

- No
- Kata
- Arti
- Type
- Cerf
- Top
- Score
- Aksi

Untuk **Sort**, user harus bisa mengurutkan data berdasarkan kolom yang relevan.

Untuk **Filter**, user harus bisa menyaring data berdasarkan nilai/kondisi dari kolom tersebut.

Namun jangan hanya membuat tampilan tombol/filter-nya. Pastikan fungsi Sort dan Filter benar-benar bekerja terhadap data yang sedang ditampilkan.

---

### 4. Rencana Pengembangan Berikutnya

Nantinya saya ingin fitur **Sort dan Filter** yang dibuat di Library Preview dan button aktifkan ini di pojok kanan ini juga bisa digunakan ketika masuk ke **Learning Game**.

Tetapi **jangan dikerjakan sekarang**.

Untuk tahap sekarang, fokus hanya:

**Library Preview → Import Database + Custom Database → Edit + Refresh + Sort + Filter**

Setelah bagian tersebut benar-benar stabil dan bekerja dengan benar, baru kita lanjutkan agar Sort/Filter juga berlaku pada Learning Game.

---

### 5. Referensi Implementasi Sort dan Filter

Saya juga memiliki project lain di:

`D:\2. Organize\1. Projects\MiniProjectKPI_EWI_Revisi2`

Di project tersebut sudah ada implementasi **Filter dan Sort**, termasuk pada kolom seperti:

- Laporan Year
- Range
- Sheet
- dan beberapa bagian lainnya.

Silakan cek project tersebut sebagai **referensi implementasi**, terutama bagaimana mekanisme Sort dan Filter dibuat dan bagaimana interaksinya dengan tabel.

Tetapi **jangan langsung menyalin atau mengubah implementasi berdasarkan project tersebut sekarang**.

Untuk tahap ini, fokus utama tetap:

1. Pahami struktur project yang sedang dikerjakan.
2. Pahami struktur Import Database dan Custom Database.
3. Tambahkan Edit.
4. Tambahkan Refresh pada Custom Database.
5. Tambahkan Sort.
6. Tambahkan Filter.
7. Pastikan tidak merusak fungsi yang sudah berjalan.
8. Setelah Library Preview stabil, baru kita bahas penerapan fitur tersebut ke Learning Game.

Sebelum melakukan perubahan kode, cek terlebih dahulu seluruh struktur file dan fungsi yang berkaitan dengan database, Library Preview, Custom Database, dan tabelnya. Jangan hanya mengubah file/fungsi yang terlihat di permukaan tanpa memastikan alur data dan tanggung jawab masing-masing fungsi sudah sesuai.
