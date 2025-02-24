powershell -Command "& {Invoke-WebRequest -Uri https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe -OutFile Miniconda3.exe}"
.\Miniconda3.exe /InstallationType=JustMe /RegisterPython=0 /AddToPath=1 /S /D=%USERPROFILE%\miniconda3
