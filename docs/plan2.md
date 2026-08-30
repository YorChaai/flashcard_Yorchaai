Berikut versi yang sudah saya rapikan supaya logikanya jelas untuk developer/AI dan tidak ambigu:

Sekarang lanjut ke bagian **Sort & Filter** di dalam Library Preview.

Untuk beberapa kolom, implementasinya sudah benar dan tidak perlu diubah. Fokus perbaikannya ada di beberapa bagian berikut.

### SORT

#### No

Sudah benar. Tidak perlu diubah.

#### Kata

Sudah benar. Tidak perlu diubah.

#### Arti

Sudah benar. Tidak perlu diubah.

#### IPA

Untuk bagian **Sort IPA**, hapus saja. Tidak perlu ada Sort berdasarkan IPA.

#### Type

Sort untuk **Type** jangan hanya berdasarkan teks mentah satu kolom.

Isi kolom Type bisa memiliki beberapa nilai yang dipisahkan dengan koma.

Contoh:

`lala, mana`

Berarti dari seluruh isi kolom Type, sistem harus membaca dan mengumpulkan nilai unik seperti:

- lala
- mana

Saya ingin urutan Type ini bisa diatur secara manual.

Contohnya awalnya:

`lala`
`mana`

Kemudian user bisa melakukan **swipe/drag/reorder** sehingga menjadi:

`mana`
`lala`

Urutan tersebut kemudian menjadi prioritas Sort.

Jadi kalau `mana` berada di atas `lala`, data dengan Type `mana` harus diprioritaskan tampil lebih atas.

Kalau memungkinkan, saya lebih memilih mekanisme **drag/swipe reorder** daripada hanya Ascending/Descending biasa karena Type adalah kategori, bukan angka.

Pastikan jika satu row memiliki:

`lala, mana`

sistem tetap bisa membaca bahwa row tersebut memiliki kedua Type tersebut.

#### CEFR

Sort CEFR harus mengikuti urutan level CEFR yang sebenarnya:

`A1 → A2 → B1 → B2 → C1 → C2`

Dan harus bisa dibalik:

`C2 → C1 → B2 → B1 → A2 → A1`

Jangan gunakan alphabetical sort biasa jika hasilnya bisa berbeda dari urutan level CEFR tersebut.

#### Top

Sudah benar. Tidak perlu diubah.

#### Score

Sort Score harus benar-benar menggunakan nilai numerik dan mendukung angka negatif, nol, maupun positif.

Contoh:

`-100, -20, -1, 0, 1, 20, 100`

Harus bisa:

**Ascending**
`-100 → ... → -1 → 0 → 1 → ... → 100`

dan

**Descending**
`100 → ... → 1 → 0 → -1 → ... → -100`

Jangan melakukan sort Score sebagai String karena angka seperti `100`, `20`, dan `3` bisa menghasilkan urutan yang salah.

---

# FILTER

Untuk bagian Filter, hapus filter pada:

- Kata
- Arti
- IPA
- Top

Jadi Filter utama cukup difokuskan pada:

- Type
- CEFR
- Score

---

### Filter Type

Filter Type harus membaca seluruh nilai Type yang tersedia dari data.

Jika sebuah row memiliki:

`lana, kiri`

maka sistem harus mengenali dua Type:

- lana
- kiri

Kemudian di Filter Type user bisa memilih Type mana yang ingin ditampilkan atau disembunyikan.

Contoh terdapat Type:

- lana ✅
- kiri ✅

Jika user menonaktifkan `kiri`:

- lana ✅
- kiri ❌

maka data yang hanya memiliki Type `kiri` tidak ditampilkan.

Untuk data yang memiliki beberapa Type sekaligus seperti:

`lana, kiri`

pastikan logika filternya konsisten.

Saya menyarankan menggunakan konsep **include**, bukan sekadar hide.

Artinya checkbox yang aktif adalah Type yang boleh tampil.

Contoh:

- lana ✅
- kiri ❌

Berarti yang diizinkan tampil adalah data yang memiliki Type `lana`.

Dengan konsep ini logikanya akan lebih mudah dipahami dan lebih aman dibanding menggunakan konsep "hapus Type tertentu".

---

### Filter CEFR

CEFR memiliki kategori:

- A1
- A2
- B1
- B2
- C1
- C2

Saya ingin user bisa memilih level mana yang ingin ditampilkan.

Contoh default:

- A1 ✅
- A2 ✅
- B1 ✅
- B2 ✅
- C1 ✅
- C2 ✅

Jika saya tidak ingin menampilkan `B2`, maka:

- A1 ✅
- A2 ✅
- B1 ✅
- B2 ❌
- C1 ✅
- C2 ✅

Hasilnya semua level tetap muncul kecuali B2.

Jangan membuat filter CEFR hanya menggunakan range seperti `A1 sampai C2`, karena saya ingin bisa mengecualikan level tertentu di tengah range.

Gunakan **multi-select / checkbox per level**.

---

### Filter Score

Untuk Score, saya ingin membagi nilai menjadi **3 kategori yang benar-benar terpisah**:

1. **Negative**
   - Score `< 0`

2. **Zero**
   - Score `== 0`

3. **Positive**
   - Score `> 0`

Penting:

**0 jangan dianggap Positive.**

Walaupun secara matematika 0 adalah non-negative, dalam fitur ini saya ingin `0` menjadi kategori sendiri.

Default:

- Negative ✅
- Zero ✅
- Positive ✅

Contoh jika user menonaktifkan Positive:

- Negative ✅
- Zero ✅
- Positive ❌

Maka hanya Score negatif dan 0 yang tampil.

Jika user menonaktifkan Negative:

- Negative ❌
- Zero ✅
- Positive ✅

Maka hanya 0 dan angka positif yang tampil.

Jika user menonaktifkan Negative dan Zero:

- Negative ❌
- Zero ❌
- Positive ✅

Maka hanya angka positif yang tampil.

Jika user hanya memilih Negative:

- Negative ✅
- Zero ❌
- Positive ❌

Maka hanya angka `< 0` yang tampil.

---

### Kesimpulan Struktur

Untuk **Sort**:

- No → tetap
- Kata → tetap
- Arti → tetap
- IPA → hapus
- Type → custom priority menggunakan drag/reorder
- CEFR → urutan A1, A2, B1, B2, C1, C2
- Top → tetap
- Score → numeric ascending/descending termasuk negative, zero, positive

Untuk **Filter**:

- Kata → hapus
- Arti → hapus
- IPA → hapus
- Top → hapus
- Type → multi-select berdasarkan Type unik dari seluruh data
- CEFR → multi-select A1 sampai C2
- Score → 3 checkbox terpisah: Negative / Zero / Positive

Untuk sekarang fokus implementasi ini dulu di **Library Preview**. Jangan lanjut dulu ke Learning Game sebelum behaviour Sort & Filter di Library Preview sudah benar dan stabil.

Satu hal yang saya ubah dari konsep awal: untuk Filter Type dan CEFR, lebih baik pakai konsep **checkbox yang aktif = data yang boleh tampil**, bukan "checkbox untuk menghapus". Secara logic dan UX jauh lebih mudah dipahami dan lebih kecil kemungkinan menghasilkan filter yang membingungkan.
