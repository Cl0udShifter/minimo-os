#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import json
import re
import subprocess
import sys

def is_code(text):
    if not text:
        return False
    patterns = [
        r'[{}();=><+\-*\/]{2,}',
        r'^\s*(function|const|let|var|import|export|class|def|return|if|else|for|while|struct|fn|pub|impl)\b',
        r'=>|->|::|!=|===|!==|&&|\|\|',
        r';\s*$',
        r'#include\b|import\s+[a-zA-Z0-9_.]+|from\s+[a-zA-Z0-9_.]+\s+import',
        r'<\/[a-zA-Z0-9_\-]+>',
        r'```[\s\S]*```',
        r'\b(curl|chmod|chown|git|sudo|pacman|systemctl)\s+[a-z0-9\-]+'
    ]
    for p in patterns:
        if re.search(p, text, re.MULTILINE):
            return True
    return False

def list_items(limit=75):
    try:
        p = subprocess.run(["cliphist", "list"], capture_output=True, text=True, check=True)
    except Exception:
        print("[]")
        return

    items = []
    lines = [l for l in p.stdout.splitlines() if l.strip()]
    for line in lines[:limit]:
        parts = line.split("\t", 1)
        if len(parts) == 2:
            cid, preview = parts[0], parts[1]
            code_flag = is_code(preview)
            items.append({
                "id": cid,
                "preview": preview,
                "isCode": code_flag,
                "length": len(preview)
            })
    print(json.dumps(items))

def copy_item(cid):
    try:
        dec = subprocess.Popen(["cliphist", "decode", str(cid)], stdout=subprocess.PIPE)
        subprocess.run(["wl-copy"], stdin=dec.stdout, check=True)
        dec.wait()
    except Exception as e:
        sys.stderr.write(f"Error copying {cid}: {e}\n")
        sys.exit(1)

def delete_item(cid):
    try:
        p = subprocess.run(["cliphist", "list"], capture_output=True, text=True, check=True)
        for line in p.stdout.splitlines():
            if line.startswith(f"{cid}\t"):
                subprocess.run(["cliphist", "delete"], input=line, text=True, check=True)
                break
    except Exception as e:
        sys.stderr.write(f"Error deleting {cid}: {e}\n")
        sys.exit(1)

def clear_all():
    subprocess.run(["cliphist", "wipe"], check=False)

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] == "list":
        limit = int(sys.argv[2]) if len(sys.argv) >= 3 and sys.argv[2].isdigit() else 75
        list_items(limit)
    elif sys.argv[1] == "copy" and len(sys.argv) >= 3:
        copy_item(sys.argv[2])
    elif sys.argv[1] == "delete" and len(sys.argv) >= 3:
        delete_item(sys.argv[2])
    elif sys.argv[1] == "clear":
        clear_all()
