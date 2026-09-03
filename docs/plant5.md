Saya ingin menambahkan dua fitur baru pada sistem flashcard.

Fitur 1 — Add Custom Card dengan multiple input secara horizontal

Pada menu Custom > Add Custom Card > Tambah Kartu Baru, saat ini form masih menggunakan format vertikal:

Kata
Arti

Saya ingin mengubahnya menjadi format horizontal seperti ini:

Kata | Arti

Di bawah baris tersebut, tambahkan tombol + untuk menambahkan baris kartu baru.

Contoh awal:

Kata | Arti

-

Jika tombol + ditekan, maka menjadi:

Kata | Arti
Kata | Arti

-

Jika ditekan lagi:

Kata | Arti
Kata | Arti
Kata | Arti

-

Jadi pengguna bisa menambahkan banyak kartu sekaligus tanpa harus membuka form satu per satu. dan maksimal bisa sampai nambahin 20 teks ya ini juga mau saya isi kata saja gak isi arti tetap bsia di lanjutin yah keculai kalo saya tulis kolom arti gak tulis kolom kata maka di bilang salah dan gak bisa lnajut gitu suruh benerin di line itu

Setiap baris tetap terdiri dari:

Input Kata

Input Arti

Tombol + selalu berada di bawah baris terakhir.

Saat disimpan, semua baris yang sudah diisi harus diproses sebagai kartu baru.

Pastikan fitur lama tetap berjalan dan jangan sampai perubahan layout ini merusak fungsi penyimpanan Custom Card yang sudah ada.

Fitur 2 — Fitur latihan menulis saat bermain flashcard

Saya juga ingin menambahkan fitur opsional baru saat sedang bermain flashcard.

Tambahkan sebuah tombol dengan ikon pensil pada card/game screen.

Fitur ini digunakan untuk latihan mengetik atau menulis jawaban menggunakan keyboard.

Contoh:

Flashcard menampilkan kata:

car

Pengguna bisa memilih menekan tombol ikon pensil jika ingin mencoba menulis kata tersebut. dan ini terllatk di tmapilan score di ingame ya

Setelah tombol pensil ditekan, tampilkan popup/modal.

Isi popup:

Tombol X / close di bagian atas untuk menutup popup.

Teks/kata yang sedang dilatih.

Input text di bawahnya.

Tombol untuk melakukan pengecekan jawaban.

Input harus mendukung teks bebas dan Unicode, sehingga dapat digunakan untuk berbagai bahasa, misalnya:

English / alfabet Latin

Japanese Hiragana

Japanese Katakana

Kanji

Korean Hangul

German

Bahasa lain

Contoh:

Kata yang harus ditulis:

car

Pengguna mengetik:

car

Jika sama dengan jawaban yang benar, tampilkan status:

Benar

Jika jawabannya salah, tampilkan:

Salah, coba lagi

Pengguna harus tetap bisa mengubah input dan mencoba kembali sampai benar atau menutup popup.

Aturan penting

Fitur latihan menulis ini bersifat opsional dan hanya sebagai latihan tambahan.

Hasil dari fitur ini jangan disimpan ke database.

Jangan mengubah:

skor Known

skor Unknown

statistik Learning Result

nilai +/− kartu

progress kartu

riwayat permainan

Baik jawabannya benar maupun salah, hasil latihan ini tidak boleh memengaruhi data apa pun.

State latihan cukup bersifat sementara selama popup terbuka.

Saat popup ditutup atau pengguna pindah kartu, state tersebut boleh di-reset.

Pengecekan jawaban

Untuk versi awal, jawaban dianggap benar jika teks input sesuai dengan jawaban yang diharapkan.

Namun, sebelum dibandingkan sebaiknya lakukan normalisasi ringan seperti:

trim() untuk menghapus spasi di awal/akhir.

Mendukung karakter Unicode dengan benar.

Jangan otomatis mengubah karakter Jepang, Korea, Kanji, atau alfabet lain.

Tujuan fitur ini adalah agar pengguna bisa menguji apakah mereka benar-benar dapat menulis/mengetik kata yang sedang dipelajari, bukan hanya mengenalinya.

Tolong implementasikan kedua fitur ini pada kode yang sudah ada tanpa merusak fitur flashcard lain yang saat ini sudah berjalan.
