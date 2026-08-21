@echo off
echo ==========================================
echo PERUBAHAN YANG DIBUAT (GIT STATUS/DIFF):
echo ==========================================
git status
git diff
echo.
echo ==========================================
set /p proceed="Apakah Anda ingin melakukan PUSH perubahan di atas? (Y/N): "
if /i not "%proceed%"=="y" goto end

git add .
set /p commit_msg="Masukkan pesan perubahan (Commit Message): "
if "%commit_msg%"=="" set commit_msg="first commit"
git commit -m "%commit_msg%"
git push -u origin main
echo PUSH Berhasil!

:end
pause