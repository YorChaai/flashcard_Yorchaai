@echo off
cd /d "%~dp0"
title Update YorFlashCard ke HP Android

echo ========================================================
echo       UPDATE / INSTALL YORFLASHCARD KE HP ANDROID
echo ========================================================
echo.
echo [1/2] Mendeteksi HP yang terhubung...
echo --------------------------------------------------------

set DEVICE_ID=
for /f "tokens=1" %%i in ('adb devices ^| findstr /r /c:"[a-zA-Z0-9].*device$"') do (
    set DEVICE_ID=%%i
)

if "%DEVICE_ID%"=="" (
    echo Tidak ada HP yang terdeteksi via ADB. Mencoba deteksi Flutter...
    call flutter devices
    echo.
    echo ========================================================
    echo  [PANDUAN JIKA HP BELUM TERDETEKSI]
    echo  1. Pastikan kabel USB terpasang rapat ke Laptop dan HP.
    echo  2. Di HP, ubah mode USB menjadi "Transfer File (MTP)".
    echo  3. Pastikan "USB Debugging" di Opsi Pengembang HP aktif.
    echo  4. Jika muncul popup "Izinkan USB Debugging?", pilih "Izinkan/OK".
    echo ========================================================
    pause
    exit /b
)

echo HP Terdeteksi dengan ID: %DEVICE_ID%
echo --------------------------------------------------------
echo.
echo [2/2] Mengirim dan memasang update ke HP (%DEVICE_ID%)...
echo (Catatan: Data deck, skor, dan riwayat di HP tetap AMAN)
echo.
call flutter run --release -d %DEVICE_ID%

echo.
echo ========================================================
pause
