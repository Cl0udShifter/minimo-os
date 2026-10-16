#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Diego Ledesma (TRN1) — Minimo OS
import sys
import os
import socket
import json

def main():
    if len(sys.argv) < 2:
        sys.exit(1)

    action = sys.argv[1]
    password = sys.argv[2] if len(sys.argv) > 2 else ""

    payload = {
        "action": action,
        "password": password
    }

    sock_path = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}") + "/minimo-polkit.sock"
    if not os.path.exists(sock_path):
        sys.exit(1)

    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(sock_path)
        s.sendall((json.dumps(payload) + "\n").encode("utf-8"))
        s.close()
    except Exception as e:
        print(f"polkit-send error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
