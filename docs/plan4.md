Sekarang lanjut ke behaviour **Sort & Filter ketika berpindah-pindah dataset/file**.

Di aplikasi terdapat beberapa **Import Database** dan satu **Custom Database**. Saya ingin konfigurasi Sort & Filter pada masing-masing database/file **tetap tersimpan seperti terakhir kali user menggunakannya**.

### 1. Sort & Filter harus persistent per file

Contoh:

Saya membuka:

**File A**

Kemudian saya mengatur:

- Sort No → Descending
- Type → urutan tertentu
- CEFR → A1, B1, C1, dst.
- Score → Ascending
- Filter tertentu → aktif/nonaktif

Kemudian saya pindah ke:

**File B**

File B harus menggunakan konfigurasi Sort & Filter milik File B sendiri.

Jika sebelumnya File B belum pernah diatur, barulah gunakan default.

Kemudian saya kembali lagi ke:

**File A**

Maka semua pengaturan Sort & Filter harus kembali seperti terakhir kali saya meninggalkan File A.

Jadi jangan setiap kali berpindah file konfigurasi kembali ke default.

Konsepnya:

**File A → simpan state A**

**File B → simpan state B**

**Custom Database → simpan state Custom Database**

Setiap dataset memiliki state Sort & Filter masing-masing.

---

# 2. Order Mode harus mengikuti Sort yang sudah dibuat

Saya juga ingin memperbaiki hubungan antara **Sort** dan **Order Mode**.

Contoh di Library Preview:

Saya sudah melakukan Sort berdasarkan **No** dari terbesar ke terkecil:

`405 → 404 → 403 → ... → 2 → 1`

Kemudian saya memilih:

**Order Mode → Reverse**

Maka hasil akhirnya harus menjadi:

`1 → 2 → 3 → ... → 404 → 405`

Artinya Order Mode **Reverse tidak membuat urutan baru dari default database**.

Reverse harus membalik **hasil urutan yang sudah dihasilkan oleh Sort & Filter Library Preview**.

Jadi konsepnya:

**Data → Filter → Sort → Order Mode**

Contoh:

`Sort No Descending`

menghasilkan:

`405 → 404 → 403 → ... → 1`

Kemudian:

`Order Mode = Reverse`

menghasilkan:

`1 → 2 → 3 → ... → 405`

Dengan begitu saya tidak perlu menyusun ulang urutan dari awal.

---

# 3. Tambahkan Range pada Sort

Saya ingin menambahkan satu opsi lagi di dalam menu **Sort**, yaitu:

### Range

User bisa menentukan range data yang ingin digunakan.

Contohnya:

`1 – 9999`

atau:

`1 – 405`

atau:

`100 – 500`

Range ini menentukan data mana yang akan digunakan.

Jadi user tidak harus selalu pergi ke menu **Learning Range** hanya untuk mengatur batas data.

---

# 4. Range dari Sort harus terhubung dengan Learning Range

Range yang dipilih melalui **Sort & Filter di Library Preview** harus ikut digunakan oleh **Learning Range**.

Contoh:

Di Library Preview saya memilih:

**Range: 100 – 500**

Maka Learning Game harus menggunakan range:

`100 → 500`

Jika saya mengubahnya menjadi:

**Range: 1 – 405**

maka Learning Game juga harus mengikuti:

`1 → 405`

Jadi jangan sampai Library Preview menampilkan range `1–405`, tetapi Learning Game masih menggunakan range lama.

---

# 5. Jangan membuat dua state Range yang saling bertentangan

Saat mengimplementasikan ini, cek bagaimana **Learning Range** saat ini bekerja.

Saya tidak ingin ada dua setting yang bisa saling bertentangan seperti:

**Sort Range: 1–405**

tetapi:

**Learning Range: 1–999**

Hal seperti ini harus memiliki satu sumber state yang jelas.

Idealnya:

**Library Preview Sort & Filter**
→ menentukan/filter range yang aktif

→ **Learning Range menggunakan range tersebut**
dan sebaliknya jika di ubah dari 1-999 di sort saya mau ubdha id learning range jadi 400-500 maka di sort libary proevew itu ke ubah juga jadi 400-500 di mana awlany tadi 1-999 gitu

Kalau memang arsitektur saat ini membutuhkan pemisahan state, pastikan ada mekanisme sinkronisasi yang jelas sehingga tidak terjadi konflik.

---

# 6. State yang harus dipertahankan

Untuk setiap dataset/file, simpan seluruh konfigurasi yang relevan, termasuk:

- Sort column
- Sort direction
- Custom Type order
- CEFR order/direction
- Score order/direction
- Filter Type
- Filter CEFR
- Filter Score
- Range
- Order Mode

Ketika user berpindah dataset, load konfigurasi dataset tersebut.

Ketika user kembali ke dataset sebelumnya, restore konfigurasi terakhir.1

---

# 7. Urutan proses data

Pastikan alur pemrosesan data konsisten:

**Raw Data**
↓
**Filter**
↓
**Sort**
↓
**Range**
↓
**Order Mode**
↓
**Library Preview / Learning Game**

Namun sebelum menentukan implementasi final, cek arsitektur yang sekarang karena mungkin Range secara teknis lebih tepat diterapkan sebelum Sort. Yang penting secara behaviour hasil akhirnya harus konsisten dengan yang saya jelaskan.

---

### Contoh behaviour yang saya inginkan

File A terakhir kali digunakan dengan:

- Sort No → Descending
- Range → 1–405
- Order Mode → Reverse

Maka ketika saya kembali ke File A:

hasilnya harus tetap:

`1 → 2 → 3 → ... → 405`

Tanpa saya harus mengatur ulang Sort, Range, atau Order Mode.

Kemudian saya pindah ke File B.

File B harus menggunakan setting terakhir File B, bukan setting File A.

Jika File B belum pernah memiliki setting, gunakan default.

Untuk sekarang fokus implementasi behaviour ini di **Library Preview dan hubungannya dengan Learning Range**. Jangan mengubah bagian Learning Game lebih jauh dari kebutuhan sinkronisasi Range dan Order Mode tersebut.
