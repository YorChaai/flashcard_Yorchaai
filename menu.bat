@echo off
cd /d "%~dp0"
title YorFlashCard - Control Center

:MENU
cls
echo ========================================================
echo               YORFLASHCARD - CONTROL CENTER
echo ========================================================
echo.
echo  [1] Update / Install Langsung ke HP Android (USB)
echo  [2] Jalankan Aplikasi di Laptop (Windows Mode)
echo  [3] Build File APK Android (.apk)
echo  [4] Build File Windows (.exe)
echo  [5] Build SEMUA (Windows .exe + Android .apk)
echo  [6] Perbarui Ikon / Logo Aplikasi (Generate Icons)
echo  [7] Cek Daftar HP / Perangkat Terhubung
echo  [8] Keluar
echo.
echo ========================================================
set /p opt="Pilih menu [1-8]: "

if "%opt%"=="1" goto UPDATE_HP
if "%opt%"=="2" goto RUN_WIN
if "%opt%"=="3" goto BUILD_APK
if "%opt%"=="4" goto BUILD_WIN
if "%opt%"=="5" goto BUILD_ALL
if "%opt%"=="6" goto UPDATE_ICON
if "%opt%"=="7" goto CHECK_DEVICES
if "%opt%"=="8" exit
goto MENU

:UPDATE_HP
cls
echo ========================================================
echo       UPDATE APLIKASI KE HP ANDROID (RELEASE)
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
    echo Pastikan USB Debugging di HP sudah aktif!
    pause
    goto MENU
)

echo HP Terdeteksi: %DEVICE_ID%
echo --------------------------------------------------------
echo.
echo [2/2] Mengirim dan memasang update ke HP (%DEVICE_ID%)...
call flutter run --release -d %DEVICE_ID%
echo.
pause
goto MENU

:RUN_WIN
cls
echo ========================================================
echo       MENJALANKAN DI WINDOWS DESKTOP
echo ========================================================
echo.
call flutter run -d windows
echo.
pause
goto MENU

:BUILD_APK
cls
echo ========================================================
echo       MEMBANGUN FILE APK ANDROID (.apk)
echo ========================================================
echo.
call flutter build apk --release
echo.
echo File APK tersimpan di:
echo build\app\outputs\flutter-apk\app-release.apk
echo.
pause
goto MENU

:BUILD_WIN
cls
echo ========================================================
echo       MEMBANGUN APLIKASI WINDOWS (.exe)
echo ========================================================
echo.
call flutter build windows
echo.
echo File Windows (.exe) tersimpan di:
echo build\windows\x64\runner\Release\
echo.
pause
goto MENU

:BUILD_ALL
cls
echo ========================================================
echo       MEMBANGUN SEMUA (WINDOWS + ANDROID)
echo ========================================================
echo.
call build_all.bat
pause
goto MENU

:UPDATE_ICON
cls
echo ========================================================
echo       MEMPERBARUI IKON DARI LOGO (logoapp.png)
echo ========================================================
echo.
call dart run flutter_launcher_icons
echo.
pause
goto MENU

:CHECK_DEVICES
cls
echo ========================================================
echo       DAFTAR PERANGKAT & HP TERDETEKSI
echo ========================================================
echo.
call flutter devices
echo.
pause
goto MENU
