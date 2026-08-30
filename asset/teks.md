Coba kamu lihat file Excel berikut:

`D:\2. Organize\1. Projects\flashcard\asset\flashcard_FINAL_WITH_PROMPT_V4.xlsx`

Saya memiliki sekitar 15.000 kata bahasa Inggris di dalam file tersebut. Saya ingin mengubah kata-kata tersebut ke beberapa bahasa lain, yaitu:

- German
- Japanese
- Korean
- Chinese

Di dalam Excel terdapat 5 sheet, tetapi untuk proses ini saya hanya ingin mengubah 4 kolom berikut:

- `main (original)`
- `grammer (original)`
- `Main (wuthuring)`
- `grammer (wuthuring)`

disini di dalam sheet ada banyak kolom dan Yang diubah hanya kolom kata, sedangkan kolom lainnya tetap dipertahankan.

Contohnya, jika terdapat kata:

`home`

maka kata tersebut dicari padanan katanya dalam:

- German → `Haus / Zuhause`
- Japanese → `家（いえ / うち）`
- Korean → `집`
- Chinese → `家（jiā）`

Saya tidak ingin hasilnya berupa terjemahan bebas dari AI. Saya ingin menggunakan **dictionary/lexical dataset** sebagai sumber bsia dari github, sehingga kata bahasa Inggris dicocokkan dengan kata yang memang digunakan dalam bahasa target.

Karena setiap bahasa memiliki sistem penulisan dan pronunciation yang berbeda, saya ingin formatnya disesuaikan dengan karakteristik masing-masing bahasa.

**German**

- Gunakan kata bahasa Jerman yang sesuai.
- Jika memungkinkan, sertakan IPA.

**Japanese**

- Gunakan Kanji jika memang kata tersebut menggunakan Kanji.
- Sertakan Hiragana sebagai cara baca.
- Gunakan Katakana jika kata tersebut memang merupakan kata yang ditulis dengan Katakana.
- Jangan memaksakan Kanji jika kata tersebut secara normal ditulis dengan Hiragana atau Katakana.
- Jika diperlukan, sertakan pronunciation/IPA.

Contoh:

`home → 家（いえ）`

**Korean**

- Gunakan Hangul.
- Jika memungkinkan, sertakan pronunciation/IPA.

Contoh:

`home → 집`

**Chinese**

- Gunakan Hanzi.
- Sertakan Pinyin agar pronunciation-nya jelas.
- Jika diperlukan, sertakan IPA.

Contoh:

`home → 家（jiā）`

Saya juga ingin menggunakan sumber dictionary atau dataset dari GitHub jika tersedia. Tujuannya bukan menerjemahkan kalimat, tetapi mencari **padanan kata/lexical equivalent** dari sekitar 15.000 kata bahasa Inggris yang sudah ada di Excel.

Jadi alurnya:

English word → cari lexical equivalent → German / Japanese / Korean / Chinese → masukkan kembali ke Excel.

Sebelum memproses seluruh 15.000 kata, periksa terlebih dahulu struktur Excel, nama sheet, nama kolom, serta beberapa contoh datanya agar tidak salah memetakan kolom.

Jangan mengubah struktur Excel yang sudah ada. Fokus hanya pada perubahan kata di 4 kolom yang sudah ditentukan.

jadi intinya untuk sekarang ini fokus bahasa korean dulu sampingan bahasa germna jepagn dan german
