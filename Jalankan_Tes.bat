@echo off
setlocal enabledelayedexpansion
title Flashcard Quality & Testing Center (Flutter + Playwright)

:MENU
cls
color 0B
echo ============================================================
echo      FLASHCARD APP - PUSAT PENGUJIAN OTOMATIS (0 TOKEN)
echo ============================================================
echo  Project: %~dp0
echo  Status : Siap Uji (Offline, 0 Token AI, Otomatis)
echo ------------------------------------------------------------
echo  [ FLUTTER NATIVE TESTING ]
echo   1. Tes Cepat Otomatis (flutter test) - 30 Skenario (~3 Detik)
echo   2. Cek Bebas Bug / Analyzer (flutter analyze)
echo   3. Uji Mutu Lengkap Sekaligus (Analyze + Test)
echo   4. Jalankan Aplikasi di Windows Desktop (flutter run -d windows)
echo.
echo  [ PLAYWRIGHT BROWSER TESTING (Robot Web Otomatis) ]
echo   11. Rekam Aksi Browser Otomatis (Playwright CodeGen)
echo   12. Jalankan Tes Playwright di Folder Ini (playwright test)
echo   13. Buka Browser Uji Coba Cepat (Playwright Open)
echo   14. Jalankan Flashcard di Browser Web (flutter run -d chrome)
echo.
echo  [ ARSITEKTUR KODE ]
echo   21. Perbarui Peta Graphify (graphify update .)
echo.
echo   0. Keluar
echo ============================================================
set /p PILIHAN="Pilih menu: "

if "%PILIHAN%"=="1" goto RUN_TEST
if "%PILIHAN%"=="2" goto RUN_ANALYZE
if "%PILIHAN%"=="3" goto RUN_ALL
if "%PILIHAN%"=="4" goto RUN_APP_WIN
if "%PILIHAN%"=="11" goto PW_CODEGEN
if "%PILIHAN%"=="12" goto PW_TEST
if "%PILIHAN%"=="13" goto PW_OPEN
if "%PILIHAN%"=="14" goto RUN_APP_WEB
if "%PILIHAN%"=="21" goto RUN_GRAPHIFY
if "%PILIHAN%"=="0" goto KELUAR

echo.
echo Pilihan tidak valid!
timeout /t 2 >nul
goto MENU

:RUN_TEST
cls
color 0E
echo ============================================================
echo [*] MENJALANKAN PENGUJIAN OTOMATIS (flutter test)...
echo ============================================================
echo Sedang menguji logika Sort, Filter, Refine, Range, dan Excel...
echo.
call flutter test
if %ERRORLEVEL% EQU 0 (
    echo.
    color 0A
    echo ============================================================
    echo  [v] STATUS: SEMUA TES LULUS 100%!
    echo  [v] Logika Sort, Filter, Excel, dan Database AMAN!
    echo ============================================================
) else (
    echo.
    color 0C
    echo ============================================================
    echo  [X] PERHATIAN: ADA TES YANG GAGAL!
    echo ============================================================
)
echo.
pause
goto MENU

:RUN_ANALYZE
cls
color 0E
echo ============================================================
echo [*] MEMERIKSA KODE APLIKASI (flutter analyze)...
echo ============================================================
echo.
call flutter analyze
if %ERRORLEVEL% EQU 0 (
    echo.
    color 0A
    echo ============================================================
    echo  [v] STATUS: KODE BERSIH (0 Error, 0 Warning)!
    echo ============================================================
) else (
    echo.
    color 0C
    echo ============================================================
    echo  [!] DITEMUKAN MASALAH / WARNING PADA KODE!
    echo ============================================================
)
echo.
pause
goto MENU

:RUN_ALL
cls
color 0E
echo ============================================================
echo [*] TAHAP 1/2: Memeriksa kerapian kode (flutter analyze)...
echo ============================================================
call flutter analyze
if %ERRORLEVEL% NEQ 0 (
    color 0C
    echo.
    echo [X] Tahap 1 Gagal: Ada issue pada analyzer.
    pause
    goto MENU
)

echo.
echo ============================================================
echo [*] TAHAP 2/2: Menjalankan semua skenario tes (flutter test)...
echo ============================================================
call flutter test
if %ERRORLEVEL% EQU 0 (
    echo.
    color 0A
    echo ============================================================
    echo  [v] SUKSES TOTAL! SELURUH KODE BERSIH & SEMUA TES LULUS!
    echo ============================================================
) else (
    color 0C
    echo.
    echo [X] Tahap 2 Gagal: Ada tes yang tidak lolos.
)
echo.
pause
goto MENU

:RUN_APP_WIN
cls
color 0A
echo ============================================================
echo [*] MENJALANKAN APLIKASI DI WINDOWS DESKTOP...
echo ============================================================
echo.
call flutter run -d windows
pause
goto MENU

:PW_CODEGEN
cls
color 0D
echo ============================================================
echo [*] PLAYWRIGHT CODEGEN (REKAM AKSI BROWSER OTOMATIS)
echo ============================================================
echo Masukkan alamat URL yang ingin direkam.
echo Contoh: https://google.com atau http://localhost:8080
echo.
set /p TARGET_URL="URL Target [default: http://localhost:8080]: "
if "%TARGET_URL%"=="" set TARGET_URL=http://localhost:8080

echo.
echo [*] Membuka Browser Perekam Playwright untuk: %TARGET_URL%
echo [i] Lakukan klik/ketik di browser, skrip akan tercatat otomatis!
call npx -y playwright codegen %TARGET_URL%
echo.
echo [v] Selesai sesi perekaman Playwright!
pause
goto MENU

:PW_TEST
cls
color 0D
echo ============================================================
echo [*] MENJALANKAN SEMUA TES PLAYWRIGHT (ROBOT GERAK SENDIRI)
echo ============================================================
echo.
call npx -y playwright test --headed
echo.
pause
goto MENU

:PW_OPEN
cls
color 0D
echo ============================================================
echo [*] MEMBUKA BROWSER PLAYWRIGHT (TEST BED)
echo ============================================================
set /p OPEN_URL="URL yang ingin dibuka [default: https://google.com]: "
if "%OPEN_URL%"=="" set OPEN_URL=https://google.com
call npx -y playwright open %OPEN_URL%
echo.
pause
goto MENU

:RUN_APP_WEB
cls
color 0E
echo ============================================================
echo [*] MENJALANKAN FLASHCARD DI GOOGLE CHROME (WEB MODE)...
echo ============================================================
echo Aplikasi akan terbuka di browser port 8080.
echo Setelah terbuka, Anda bisa mengujinya dengan Playwright CodeGen!
echo.
call flutter run -d chrome --web-port 8080
pause
goto MENU

:RUN_GRAPHIFY
cls
color 0E
echo ============================================================
echo [*] MENYINKRONKAN KNOWLEDGE GRAPH (graphify update .)...
echo ============================================================
echo.
call graphify update .
echo.
echo [v] Selesai menyinkronkan graph arsitektur!
pause
goto MENU

:KELUAR
cls
echo Sampai jumpa!
exit /b 0
