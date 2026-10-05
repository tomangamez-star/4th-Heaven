#!/usr/bin/env python3
from pathlib import Path
import sys

root = Path(sys.argv[1])
for path in root.rglob("*"):
    if not path.is_file() or path.suffix.lower() not in {".html", ".js"}:
        continue
    text = path.read_text(encoding="utf-8")
    if path.name == "index.html":
        text = text.replace("game.html'", "game.html?v=003'")
    path.write_text(text, encoding="utf-8")
