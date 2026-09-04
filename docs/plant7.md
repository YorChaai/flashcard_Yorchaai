Tolong perbaiki 2 bug di sini yang sebenarnya sebelumnya sudah sempat diperbaiki, tetapi sekarang muncul lagi setelah penambahan fitur.

1. **Preview Library – Table View**
   Di Table View, tabel bisa di-scroll ke kanan dan kiri, tetapi sekarang terasa sangat lag/stuttering. Sebelumnya bagian ini sudah sempat diperbaiki dan scrolling sudah lancar, tetapi setelah penambahan fitur baru, scrolling kembali menjadi lag. Tolong optimalkan lagi bagian ini agar scrolling horizontal kembali smooth dan tidak lag. Pastikan Table View tetap menampilkan isi database, termasuk kolom dan line yang sesuai.

2. **Pagination 25 / 50 / 100 / 250**
   Ada masalah pada pagination. Pilihan **25, 50, 100, 250** tersedia, tetapi ketika memilih **250**, tampilannya selalu mentok di **100** dan tidak pernah menampilkan lebih dari 100 line. Sepertinya ada logic atau kode yang saling bertabrakan dengan batas maksimal 100. Tolong cari akar masalahnya dan perbaiki supaya pilihan **250 benar-benar bisa menampilkan hingga 250 line**.

Cuma dua bug ini yang perlu diperbaiki. Jangan mengubah fitur atau bagian lain yang tidak berkaitan.
