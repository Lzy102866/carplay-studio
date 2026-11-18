import Foundation
import CryptoKit

/// 素材保险柜：包里只存密文（`.enc`），运行时用 ChaCha20-Poly1305 解封。
///
/// 密钥由 `VaultKey.generated.swift` 里的两段碎片异或还原，
/// 换密钥只需 `python tools/pack_assets.py --rotate-key`。
///
/// 需要说清楚的一点：密钥在客户端里，属于"提高提取门槛"，不是密码学意义上的保密。
/// 真正的保密要靠服务端按授权下发（见 hardening/license-service）。
enum ContentVault {
    private static let symmetricKey: SymmetricKey = {
        let a = VaultKeyMaterial.partA
        let b = VaultKeyMaterial.partB
        let count = min(a.count, b.count)
        var raw = [UInt8]()
        raw.reserveCapacity(count)
        for index in 0..<count {
            raw.append(a[index] ^ b[index] ^ 0x5A)
        }
        return SymmetricKey(data: Data(raw))
    }()

    /// 读取并解密一张素材；找不到文件或认证失败都返回 nil。
    static func data(named name: String, ext: String) -> Data? {
        let resource = "\(name).\(ext)"
        guard let url = Bundle.main.url(forResource: resource, withExtension: "enc"),
              let sealed = try? Data(contentsOf: url),
              let box = try? ChaChaPoly.SealedBox(combined: sealed) else {
            return nil
        }
        return try? ChaChaPoly.open(box, using: symmetricKey)
    }

    static func contains(named name: String, ext: String) -> Bool {
        Bundle.main.url(forResource: "\(name).\(ext)", withExtension: "enc") != nil
    }
}
