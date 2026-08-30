Sekarang lanjut ke bagian **Custom Database dan Deleted Data**.

### 1. Refresh di Custom Database

Di Custom Database sebelumnya sudah dibuat tombol **Refresh** secara keseluruhan.

Tidak masalah, biarkan tombol Refresh keseluruhan tersebut tetap ada.

Tetapi sekarang saya ingin menambahkan **Refresh per-line/per-row** juga.

Jadi pada setiap baris di kolom **Aksi** harus ada tombol:

- Refresh
- Edit
- Delete

Refresh per-line hanya memperbarui data pada baris tersebut, bukan seluruh Custom Database.

Jadi user bisa memilih satu row lalu melakukan Refresh hanya pada row tersebut.

---

# 2. Delete Jangan Menghapus Data Secara Permanen

Saya ingin mengubah konsep Delete.

Ketika user menekan **Delete** pada Custom Database, data tersebut **jangan benar-benar dihapus secara permanen**.

Data cukup dipindahkan ke sebuah tempat khusus untuk **Deleted Data / Trash**.

Jadi alurnya:

**Custom Database → Delete → Deleted Data**

Data tetap disimpan sehingga masih bisa dikembalikan.

---

# 3. Tombol Deleted Data

Di sebelah tombol **Refresh Source** pada Custom Database, tambahkan tombol untuk membuka halaman **Deleted Data**.

Contohnya:

`Refresh Source | Deleted Data`

Tombol tersebut membuka halaman yang berisi semua data yang sebelumnya di-delete.

---

# 4. Halaman Deleted Data

Tampilan halaman Deleted Data harus dibuat **semirip mungkin dengan Library Preview – Custom Mode** agar UI dan behaviour-nya konsisten.

Tetapi ada beberapa perbedaan.

### Yang tetap ada:

- Tabel data
- Kolom No
- Kata
- Arti
- Type
- CEFR
- Top
- Score
- Aksi
- Pagination
- Page size / rows per page
- Edit
- Refresh

### Yang dihapus:

Jangan tampilkan fitur **Refine / Sort & Filter** di halaman Deleted Data.

Jadi halaman ini cukup untuk melihat data yang sudah di-delete dan mengembalikannya.

---

# 5. Tombol Aksi di Deleted Data

Di kolom **Aksi**, jangan gunakan tombol silang/X seperti Delete biasa.

Karena data di halaman ini sudah berada di Deleted Data, tombol tersebut harus menjadi:

**Undo / Restore**

Fungsinya adalah mengembalikan data tersebut ke tempat data aslinya.

Contoh:

Data dengan:

`No = 152`

dihapus dari Custom Database.

Data tersebut masuk ke Deleted Data.

Kemudian user membuka Deleted Data dan menekan:

**Undo / Restore**

Maka data tersebut harus kembali ke data aslinya sesuai dengan identitas/No yang dimilikinya.

---

# 6. Masalah Nomor / No

Bagian ini sangat penting.

Jangan mengandalkan **posisi row saat ini** sebagai identitas data.

Misalnya:

Data asli:

| No  | Kata   |
| --- | ------ |
| 1   | apple  |
| 2   | banana |
| 3   | cat    |
| 4   | dog    |

Kemudian No 2 di-delete.

Deleted Data:

| No  | Kata   |
| --- | ------ |
| 2   | banana |

Ketika dilakukan Undo, data harus kembali ke record No 2 yang sesuai dengan sumber data aslinya.

Jangan sampai karena row sudah berpindah posisi setelah sorting/filtering/penghapusan, data `banana` malah masuk ke posisi lain.

Jadi perlu dicek bagaimana struktur database saat ini.

Kalau kolom **No** memang hanya nomor urut yang bisa berubah, gunakan **unique identifier/internal ID** sebagai identitas utama data.

Kolom No boleh tetap ditampilkan kepada user, tetapi mekanisme Delete/Restore sebaiknya menggunakan ID yang stabil.

---

# 7. Sinkronisasi Import Database dan Deleted Data

Bagian Import Database juga perlu diperbaiki agar konsep Delete/Restore ini aman.

Saya ingin ada **sheet/table khusus untuk Deleted Data**.

Jadi secara konsep:

### Data asli

`Import Database`

### Data yang di-delete

`Deleted Data`

Data tidak benar-benar hilang ketika user melakukan Delete.

Contoh:

**Import Database**

| ID   |  No | Kata   |
| ---- | --: | ------ |
| A001 |   1 | apple  |
| A002 |   2 | banana |
| A003 |   3 | cat    |

Jika `banana` di-delete:

**Import Database**

| ID   |  No | Kata  |
| ---- | --: | ----- |
| A001 |   1 | apple |
| A003 |   3 | cat   |

**Deleted Data**

| ID   |  No | Kata   |
| ---- | --: | ------ |
| A002 |   2 | banana |

Kemudian user menekan Undo pada `banana`.

Maka:

**Import Database**

kembali memiliki:

| ID   |  No | Kata   |
| ---- | --: | ------ |
| A001 |   1 | apple  |
| A002 |   2 | banana |
| A003 |   3 | cat    |

dan record tersebut dihapus dari **Deleted Data**.

---

# 8. Jangan Sampai Data Duplikat

Pastikan proses Restore/Undo memiliki proteksi agar tidak menghasilkan duplicate data.

Contohnya:

Jika data dengan ID `A002` sudah kembali ada di data asli, jangan memasukkan `A002` sekali lagi ketika Undo dilakukan.

Sistem harus mengecek terlebih dahulu apakah record tersebut sudah ada.

---

# 9. Source of Truth

Sebelum mengubah kode, cek terlebih dahulu bagaimana struktur database saat ini.

Saya tidak ingin sekadar membuat sheet baru tanpa memahami alur data yang sudah ada.

Pastikan jelas:

**Data asli → Custom Database → Delete → Deleted Data**

dan:

**Deleted Data → Undo/Restore → Data asli**

Custom Database harus tetap mengambil data berdasarkan sumber yang benar.

Jangan membuat Deleted Data menjadi database baru yang berdiri sendiri tanpa hubungan yang jelas dengan data aslinya.

---

# 10. Hal yang Harus Dipastikan

Setelah implementasi, lakukan pengujian minimal:

1. Data di Custom Database bisa di-delete.
2. Data yang di-delete tidak hilang permanen.
3. Data masuk ke Deleted Data.
4. Deleted Data menampilkan record yang benar.
5. Edit tetap bisa dilakukan.
6. Refresh per-row tetap bisa dilakukan.
7. Undo mengembalikan data ke sumber yang benar.
8. Nomor/ID data tetap konsisten.
9. Tidak terjadi duplicate data.
10. Sorting/filtering tidak merusak hubungan ID data.
11. Delete → Restore → Delete lagi tetap aman.
12. Data asli dan Deleted Data selalu konsisten.
13. Refresh Source tetap bekerja seperti sebelumnya.
14. Refresh per-row hanya memengaruhi row yang dipilih.

Sebelum coding, cek dulu seluruh struktur yang berhubungan dengan **Import Database, Custom Database, source data, delete, edit, refresh, dan identifier/No**. Jangan langsung mengubah implementasi hanya berdasarkan tampilan UI.
