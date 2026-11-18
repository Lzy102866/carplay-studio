"""RFC 8439 ChaCha20-Poly1305（纯 Python，仅用于打包加密素材）。

为什么自己写：目标环境不保证装了 cryptography/PyNaCl，而这段算法很短，
并且能和 iOS 端 CryptoKit 的 `ChaChaPoly` 完全互通（同样的
nonce(12) || ciphertext || tag(16) 组合格式）。

正确性由 RFC 8439 §2.8.2 的官方测试向量在 `--selftest` 里校验。
"""

from __future__ import annotations

import struct

MASK = 0xFFFFFFFF


def _rotl(v: int, n: int) -> int:
    return ((v << n) | (v >> (32 - n))) & MASK


def _quarter_round(s, a, b, c, d):
    s[a] = (s[a] + s[b]) & MASK
    s[d] = _rotl(s[d] ^ s[a], 16)
    s[c] = (s[c] + s[d]) & MASK
    s[b] = _rotl(s[b] ^ s[c], 12)
    s[a] = (s[a] + s[b]) & MASK
    s[d] = _rotl(s[d] ^ s[a], 8)
    s[c] = (s[c] + s[d]) & MASK
    s[b] = _rotl(s[b] ^ s[c], 7)


def _block(key: bytes, counter: int, nonce: bytes) -> bytes:
    const = b"expand 32-byte k"
    state = list(struct.unpack("<4I", const))
    state += list(struct.unpack("<8I", key))
    state += [counter & MASK]
    state += list(struct.unpack("<3I", nonce))
    work = state[:]
    for _ in range(10):
        _quarter_round(work, 0, 4, 8, 12)
        _quarter_round(work, 1, 5, 9, 13)
        _quarter_round(work, 2, 6, 10, 14)
        _quarter_round(work, 3, 7, 11, 15)
        _quarter_round(work, 0, 5, 10, 15)
        _quarter_round(work, 1, 6, 11, 12)
        _quarter_round(work, 2, 7, 8, 13)
        _quarter_round(work, 3, 4, 9, 14)
    return struct.pack("<16I", *[(work[i] + state[i]) & MASK for i in range(16)])


def _keystream(key: bytes, nonce: bytes, length: int) -> bytes:
    out = bytearray()
    counter = 1
    while len(out) < length:
        out += _block(key, counter, nonce)
        counter += 1
    return bytes(out[:length])


def _poly1305(msg: bytes, key: bytes) -> bytes:
    r = int.from_bytes(key[:16], "little") & 0x0FFFFFFC0FFFFFFC0FFFFFFC0FFFFFFF
    s = int.from_bytes(key[16:32], "little")
    p = (1 << 130) - 5
    acc = 0
    for i in range(0, len(msg), 16):
        chunk = msg[i:i + 16]
        n = int.from_bytes(chunk + b"\x01", "little")
        acc = ((acc + n) * r) % p
    return ((acc + s) & ((1 << 128) - 1)).to_bytes(16, "little")


def _pad16(data: bytes) -> bytes:
    return b"\x00" * ((16 - len(data) % 16) % 16)


def seal(key: bytes, nonce: bytes, plaintext: bytes, aad: bytes = b"") -> bytes:
    """返回 combined 格式：nonce || ciphertext || tag（与 CryptoKit 一致）。"""
    if len(key) != 32:
        raise ValueError("key 必须是 32 字节")
    if len(nonce) != 12:
        raise ValueError("nonce 必须是 12 字节")
    otk = _block(key, 0, nonce)[:32]
    ct = bytes(a ^ b for a, b in zip(plaintext, _keystream(key, nonce, len(plaintext))))
    mac_data = aad + _pad16(aad) + ct + _pad16(ct) + struct.pack("<QQ", len(aad), len(ct))
    tag = _poly1305(mac_data, otk)
    return nonce + ct + tag


def open_(combined: bytes, key: bytes, aad: bytes = b"") -> bytes:
    if len(combined) < 28:
        raise ValueError("密文太短")
    nonce, body = combined[:12], combined[12:]
    ct, tag = body[:-16], body[-16:]
    otk = _block(key, 0, nonce)[:32]
    mac_data = aad + _pad16(aad) + ct + _pad16(ct) + struct.pack("<QQ", len(aad), len(ct))
    if _poly1305(mac_data, otk) != tag:
        raise ValueError("认证失败：密钥不对或密文被改过")
    return bytes(a ^ b for a, b in zip(ct, _keystream(key, nonce, len(ct))))


def selftest() -> None:
    key = bytes.fromhex("808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f")
    nonce = bytes.fromhex("070000004041424344454647")
    aad = bytes.fromhex("50515253c0c1c2c3c4c5c6c7")
    pt = (b"Ladies and Gentlemen of the class of '99: If I could offer you only one tip "
          b"for the future, sunscreen would be it.")
    expect_ct = bytes.fromhex(
        "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d6"
        "3dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b36"
        "92ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3f"
        "f4def08e4b7a9de576d26586cec64b6116"
    )
    expect_tag = bytes.fromhex("1ae10b594f09e26a7e902ecbd0600691")
    out = seal(key, nonce, pt, aad)
    assert out[12:-16] == expect_ct, "密文与 RFC 向量不一致"
    assert out[-16:] == expect_tag, "tag 与 RFC 向量不一致"
    assert open_(out, key, aad) == pt
    # 篡改检测
    bad = bytearray(out)
    bad[-1] ^= 0x01
    try:
        open_(bytes(bad), key, aad)
    except ValueError:
        pass
    else:
        raise AssertionError("被篡改的密文居然解开了")
    print("[ok] RFC 8439 §2.8.2 向量通过，篡改可检出")


if __name__ == "__main__":
    selftest()
