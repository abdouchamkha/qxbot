#!/usr/bin/env bash
# Rebuild the Windows app from WSL: code -> dist\QXBot, GUI wheels -> embedded Python, QXBot.exe, clean zip.
# Needs the build folder made earlier (embedded Python 3.12 with pyquotex + patchright in dist\QXBot\python).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${BUILD:-/mnt/c/Users/dz/qxbot-build}"
D="$BUILD/dist/QXBot"
SP="$D/python/Lib/site-packages"
PIP="$REPO/.venv/bin/pip"

# 1. code
cp "$REPO/bot.py" "$REPO/signals.py" "$D/"
rm -rf "$D/desktop" && cp -r "$REPO/desktop" "$D/desktop"
find "$D/desktop" -name __pycache__ -prune -exec rm -rf {} +
rm -f "$D/desktop/build_windows.sh" "$D/desktop/README-windows.txt"

# 2. native window: pywebview (+ pythonnet for Edge WebView2), Windows wheels into the embedded Python
if [ ! -d "$SP/webview" ]; then
  W="$BUILD/wheels-gui"; mkdir -p "$W"
  "$PIP" download --platform win_amd64 --python-version 3.12 --only-binary=:all: --no-deps --dest "$W" pywebview pythonnet clr_loader bottle
  "$PIP" download --no-deps --no-binary=:all: --dest "$W" proxy_tools  # sdist only, a pure-Python module
  T="$(mktemp -d)"
  "$PIP" install --no-deps --no-index --no-compile --target "$T/sp" "$W"/*.whl
  tar -xzf "$W"/proxy_tools-*.tar.gz -C "$T" && cp -r "$T"/proxy_tools-*/proxy_tools "$T/sp/"
  rm -rf "$T/sp/bin" && cp -r "$T/sp/." "$SP/" && rm -rf "$T"
fi

# 3. QXBot.exe launcher, compiled by the C# compiler every Windows has
cp "$REPO/desktop/launcher/QXBot.cs" "$REPO/desktop/launcher/qxbot.ico" "$BUILD/"
(cd "$BUILD" && /mnt/c/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe /nologo /target:winexe \
  /win32icon:qxbot.ico /out:dist\\QXBot\\QXBot.exe QXBot.cs)
rm -f "$BUILD/QXBot.cs" "$BUILD/qxbot.ico"

# 4. terminal mode stays available
rm -f "$D/start.bat"
printf '@echo off\r\ncd /d "%%~dp0"\r\ntitle QXBot\r\npython\\python.exe bot.py\r\necho.\r\npause\r\n' > "$D/QXBot-terminal.bat"
cp "$REPO/desktop/README-windows.txt" "$D/README.txt"

# 5. zip without private data
"$REPO/.venv/bin/python" - "$D" "$BUILD/QXBot-windows.zip" <<'PY'
import sys, zipfile
from pathlib import Path
src, out = Path(sys.argv[1]), Path(sys.argv[2])
PRIVATE_DIRS = {"login_profile", "browser_profile", "__pycache__"}
skip = lambda p: (p.name in ("config.json", "session.json") or p.suffix == ".log" or
                  (p.name.startswith("trades") and p.suffix == ".csv") or PRIVATE_DIRS & set(p.relative_to(src).parts))
tmp = out.with_suffix(".tmp")
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for p in sorted(src.rglob("*")):
        if p.is_file() and not skip(p):
            z.write(p, Path("QXBot") / p.relative_to(src))
tmp.replace(out)
names = zipfile.ZipFile(out).namelist()
bad = [n for n in names if any(k in n for k in ("config.json", "session.json", "login_profile", "browser_profile", "trades")) or n.endswith(".log")]
assert not bad, bad
print(f"{out}: {out.stat().st_size / 1e6:.1f} MB, {len(names)} files, no private files")
PY
