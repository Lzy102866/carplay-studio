"""把素材打成加密包（ChaCha20-Poly1305），并生成 Swift 端的密钥碎片文件。

用法：
    python tools/pack_assets.py                # 首次：生成密钥 + 加密全部预览图
    python tools/pack_assets.py --rotate-key   # 换密钥并重打（旧包立刻作废）
    python tools/pack_assets.py --keep-plaintext  # 保留明文（调试用，别提交）

产物：
    Resources/Vault/<sha>.<ext>.enc         每张图一个密封盒（nonce||ct||tag）
    Resources/Vault/manifest.json           清单（版本、算法、明文大小与哈希）
    Data/VaultKey.generated.swift           密钥碎片（两段异或，运行时还原）
    assets-src/previews/                    明文挪到这里，不进包
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import secrets
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import chacha20poly1305 as aead  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "CarPlayWallpaperStudioShell", "Resources")
VAULT = os.path.join(RES, "Vault")
SRC = os.path.join(ROOT, "assets-src", "previews")
KEY_FILE = os.path.join(ROOT, "vault.key")
SWIFT_KEY = os.path.join(ROOT, "CarPlayWallpaperStudioShell", "Data", "VaultKey.generated.swift")

MASK = 0x5A


def load_or_create_key(rotate: bool) -> bytes:
    if not rotate and os.path.isfile(KEY_FILE):
        key = bytes.fromhex(open(KEY_FILE).read().strip())
        if len(key) != 32:
            raise SystemExit("vault.key 损坏，删除后重跑")
        return key
    key = secrets.token_bytes(32)
    with open(KEY_FILE, "w", encoding="ascii") as f:
        f.write(key.hex())
    print("[key] 已生成新密钥 → vault.key（务必备份，丢了素材就解不开了）")
    return key


def write_swift_key(key: bytes) -> None:
    a = bytes(secrets.token_bytes(32))
    b = bytes(x ^ key[i] ^ MASK for i, x in enumerate(a))
    assert bytes(a[i] ^ b[i] ^ MASK for i in range(32)) == key

    def fmt(name: str, data: bytes) -> str:
        body = ", ".join(f"0x{v:02X}" for v in data)
        return f"    static let {name}: [UInt8] = [{body}]"

    os.makedirs(os.path.dirname(SWIFT_KEY), exist_ok=True)
    with open(SWIFT_KEY, "w", encoding="utf-8") as f:
        f.write(
            "// 本文件由 tools/pack_assets.py 生成，不要手改。\n"
            "// 换密钥请跑：python tools/pack_assets.py --rotate-key\n"
            "import Foundation\n\n"
            "enum VaultKeyMaterial {\n"
            f"{fmt('partA', a)}\n"
            f"{fmt('partB', b)}\n"
            "}\n"
        )
    print(f"[swift] 密钥碎片 → {os.path.relpath(SWIFT_KEY, ROOT)}")


def pack(key: bytes, keep_plaintext: bool) -> None:
    os.makedirs(VAULT, exist_ok=True)
    os.makedirs(SRC, exist_ok=True)
    sources = sorted(
        f for f in os.listdir(RES)
        if f.lower().endswith((".jpg", ".jpeg", ".png")) and os.path.isfile(os.path.join(RES, f))
    )
    if not sources:
        raise SystemExit("Resources 下没有图片，先把素材放进去")

    manifest = {"version": 1, "algorithm": "chacha20poly1305", "items": {}}
    total = 0
    for name in sources:
        src_path = os.path.join(RES, name)
        plain = open(src_path, "rb").read()
        sealed = aead.seal(key, secrets.token_bytes(12), plain)
        if aead.open_(sealed, key) != plain:
            raise SystemExit(f"自检失败：{name}")
        out_name = name + ".enc"
        with open(os.path.join(VAULT, out_name), "wb") as f:
            f.write(sealed)
        manifest["items"][name] = {
            "file": out_name,
            "size": len(plain),
            "sha256": hashlib.sha256(plain).hexdigest(),
            "sealed_size": len(sealed),
        }
        total += len(plain)
        shutil.move(src_path, os.path.join(SRC, name))

    with open(os.path.join(VAULT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print(f"[pack] {len(sources)} 个素材，明文 {total/1024:.0f} KB → 加密包 "
          f"{sum(v['sealed_size'] for v in manifest['items'].values())/1024:.0f} KB")
    if keep_plaintext:
        for name in sources:
            shutil.copyfile(os.path.join(SRC, name), os.path.join(RES, name))
        print("[warn] 已按 --keep-plaintext 把明文复制回 Resources（发布前务必删掉）")


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--rotate-key", action="store_true")
    ap.add_argument("--keep-plaintext", action="store_true")
    args = ap.parse_args(argv)
    if not os.path.isdir(RES):
        raise SystemExit(f"找不到 {RES}")
    key = load_or_create_key(args.rotate_key)
    pack(key, args.keep_plaintext)
    write_swift_key(key)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
