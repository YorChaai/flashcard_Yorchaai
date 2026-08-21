# Laporan Perbaikan Error "VM Snapshot Invalid"

## 🐛 Gejala Error (Symptom)
Aplikasi selalu mengalami *force close* saat dijalankan di perangkat fisik dalam mode Release (baik saat di-install manual via APK maupun via `flutter run --release`). 

Pesan error utama di Logcat:
```text
[ERROR:flutter/runtime/dart_vm_data.cc(20)] VM snapshot invalid and could not be inferred from settings.
[ERROR:flutter/runtime/dart_vm.cc(253)] Could not set up VM data to bootstrap the VM from.
[ERROR:flutter/runtime/dart_vm_lifecycle.cc(85)] Could not create Dart VM instance.
Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR)
```

## 🔍 Analisis Penyebab Utama (Root Cause)
Penyebab utama aplikasi *crash* adalah karena hilangnya file **`libapp.so`** di dalam APK Release yang di-generate oleh Gradle. `libapp.so` adalah file hasil kompilasi AOT (Ahead-Of-Time) dari kode Dart aplikasi. Tanpa file ini, mesin Flutter tidak bisa memuat aplikasi.

File `libapp.so` hilang karena adanya **kesalahan urutan penulisan kode di `android/build.gradle.kts`**:
1. Gradle memanggil `project.evaluationDependsOn(":app")` **sebelum** meng-override *build directory* project.
2. Hal ini membuat modul `:app` menggunakan letak folder build bawaan (`android/app/build`).
3. Namun, Flutter CLI menaruh file `libapp.so` hasil build di letak kustom yang diharapkan (`build/app/...`).
4. Karena terjadi perbedaan (miskomunikasi) letak folder ini, Gradle tidak dapat menemukan `libapp.so` saat melakukan proses pemaketan APK, sehingga APK tercipta *tanpa* kode aplikasi (hanya berukuran ~35MB, bukan ~53MB semestinya).

## 🛠️ Perbaikan yang Dilakukan (Fixes)

Berikut adalah daftar modifikasi file yang telah dilakukan untuk menuntaskan masalah ini:

### 1. `android/build.gradle.kts`
**Perubahan:** Menukar urutan fungsi `evaluationDependsOn` agar dieksekusi **setelah** pengaturan kustom `layout.buildDirectory` diinisiasi.

```diff
- subprojects {
-     project.evaluationDependsOn(":app")
- }
- 
  val newBuildDir: Directory =
      rootProject.layout.buildDirectory
          .dir("../../build")
          .get()
  rootProject.layout.buildDirectory.value(newBuildDir)
  
  subprojects {
      val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
      project.layout.buildDirectory.value(newSubprojectBuildDir)
  }
+ 
+ subprojects {
+     project.evaluationDependsOn(":app")
+ }
```
*(Ini memastikan Gradle akan mencari library dari folder flutter `build/app/` dengan benar saat merakit APK)*

### 2. `android/app/src/main/AndroidManifest.xml`
**Perubahan:** Mengubah nilai `android:extractNativeLibs` menjadi `false`.

```diff
  <application
      android:label="yor_flashcard"
      android:name="${applicationName}"
      android:icon="@mipmap/ic_launcher"
-     android:extractNativeLibs="true">
+     android:extractNativeLibs="false">
```
*(Pada Android API 36 / Android 16, konfigurasi `extractNativeLibs="true"` kerap kali bermasalah dengan batasan "16KB memory page alignment" untuk library bawaan. Dengan mode `"false"`, library C++ dibaca secara zip-aligned langsung dari dalam APK, yang lebih stabil dan aman dari resiko korupsi saat instalasi).*

### 3. Clear Cache & Re-build
- `flutter clean`
- `flutter pub get`
- `flutter build apk --release` (Atau menggunakan `build_all.bat`)

**Hasil Akhir:** 
APK Release kembali berukuran normal (mendekati ~53MB), file `libapp.so` sukses terbawa, dan aplikasi dapat dieksekusi dengan *Impeller rendering backend* tanpa error lagi.
