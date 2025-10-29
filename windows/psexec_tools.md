# PsExec + Chrome CDP — Setup & Run (Markdown)

## 1) Install PsExec (no Winget)

```bat
:: Create a tools folder
set TOOLS=C:\Tools
mkdir "%TOOLS%" 2>nul

:: Download PsTools
curl.exe -L "https://download.sysinternals.com/files/PSTools.zip" -o "%TEMP%\PSTools.zip"

:: Extract to C:\Tools
tar -xf "%TEMP%\PSTools.zip" -C "%TOOLS%"
```

> PsExec will be in `C:\Tools\PsExec.exe` after extraction.

---

## 2) Add elevated permissions to a headless account

```bat
:: Replace 'sshtemp' with your account name as needed
net localgroup Administrators sshtemp /add
```

---

## 3) Create a clean Chrome CDP profile folder

```bat
mkdir C:\Temp\cdp 2>nul
```

> Using a dedicated `user-data-dir` avoids profile lock/permission issues when multiple Chrome CDP instances run.

---

## 4) Find the interactive user’s Session ID

```bat
query session
```

> Note the **Session ID** of the GUI (head-ful) user.

---

## 5) Launch Chrome via PsExec with CDP enabled

```bat
"C:\Tools\PsExec.exe" -accepteula -nobanner -i <SESSION_ID> -d -s ^
  "C:\Program Files\Google\Chrome\Application\chrome.exe" ^
  --remote-debugging-port=9222 ^
  --remote-debugging-address=127.0.0.1 ^
  --user-data-dir="C:\Temp\cdp" ^
  --no-first-run --disable-first-run-ui --new-window
```

* Replace `<SESSION_ID>` with the value from `query session`.
* Flags:

  * `-i <id>` runs in the specified interactive session
  * `-d` doesn’t wait for the process to end
  * `-s` runs under the local system account
  * `--remote-debugging-*` enables Chrome’s CDP on localhost:9222
  * `--user-data-dir` points Chrome to the clean profile you created

---

### Notes

* If you extracted PsTools elsewhere, update the `PsExec.exe` path accordingly.
* The first PsExec run may prompt for EULA; `-accepteula` suppresses that prompt.
