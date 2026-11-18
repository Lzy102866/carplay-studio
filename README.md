# 壁纸工坊 · 重建工程（无收费、素材加密）

按原版「CarPlay 壁纸工坊」的功能重建的空壳工程。**代码是全新写的**，只复用了属于你的产品资产（壁纸目录 + 预览图 + 图标），不含任何收费、授权、卡密、设备绑定逻辑。

## 一句话现状

- ✅ 已实现：目录浏览（12 主题 / 23 张）、详情页（大图 + 同主题切换 + 规格）、收藏（本地持久化）、配对状态机与错误提示、设置页。
- ✅ 素材加密：包内只有 ChaCha20-Poly1305 密文，运行时解密。
- ⛔ 唯一缺口：「写车机」那一步（开发者模式隧道 + 写 CarPlay 缓存）。这步依赖真机/Mac，无法离线完成，已隔离成 `DeviceBridge` 协议，接入点见下文。

## 目录

```
app-shell/
├── project.yml                        # XcodeGen 描述文件（一条命令生成 .xcodeproj）
├── vault.key                          # 素材密钥（勿提交、勿外泄、务必备份）
├── assets-src/previews/               # 明文预览图（不进包，留着重新打包用）
├── tools/
│   ├── chacha20poly1305.py            # 素材加密算法（RFC 8439，已用官方向量自检通过）
│   └── pack_assets.py                 # 把明文素材打成加密包 + 生成 Swift 密钥碎片
└── CarPlayWallpaperStudioShell/
    ├── App/                           # 入口 + 全局状态
    ├── Models/                        # 目录 / 壁纸 / 路由（与原版 WallpaperCatalog.json 同构）
    ├── Data/                          # 目录、收藏、加密保险柜、远端取图、设备桥、配置
    ├── Design/                        # 配色与背景
    ├── Views/                         # 首页 / 详情 / 收藏 / 配对 / 设置 / 通用组件
    └── Resources/
        ├── WallpaperCatalog.json      # 目录（原版同一份格式）
        ├── Vault/                     # 加密后的预览图 + manifest
        └── Assets.xcassets/           # App 图标 + 强调色
```

## 怎么编译

> 想直接出 IPA（发给朋友自签的那种），看 [`打IPA.md`](打IPA.md)，一条 `./build.sh` 就行。

### 方式 A：XcodeGen（推荐，最快）

1. Mac 上装 XcodeGen：`brew install xcodegen`
2. 在 `app-shell/` 目录跑：

```bash
xcodegen generate
open CarPlayWallpaperStudioShell.xcodeproj
```

3. Xcode 里选你的签名 Team（`Signing & Capabilities`），改 `PRODUCT_BUNDLE_IDENTIFIER`（现在是 `com.example.CarPlayWallpaperStudio`），真机跑。

### 方式 B：手动建工程（没有 XcodeGen）

1. Xcode → New Project → iOS App（SwiftUI，Interface: SwiftUI）；
2. 把 `CarPlayWallpaperStudioShell/` 下的 `App` `Models` `Data` `Design` `Views` 五个文件夹拖进项目（勾选 Copy items）；
3. 把 `Resources/` 拖进项目，勾选 "Create folder references"（保持目录结构，`Vault/*.enc` 才能被找到）；
4. 把 `Resources/Assets.xcassets` 拖进项目（作为资源目录）；
5. Target → Info 里补两个键：`NSLocalNetworkUsageDescription`、`NSBonjourServices = [_stikpairprobe._tcp]`；
6. 把 `Deployment Target` 设成 iOS 17.0，跑。

> 手动方式下 `Info.plist` 由 Xcode 生成，若报缺 `NSLocalNetworkUsageDescription` 就去 Info 里加上。

## 素材加密怎么工作

1. 明文素材放在 `assets-src/previews/`，**永远不会进包**。
2. 打包：`python tools/pack_assets.py`，会：
   - 用 `vault.key` 的密钥把每张图打成 `<sha>.<ext>.enc`（ChaCha20-Poly1305，nonce 随机）；
   - 生成 `Data/VaultKey.generated.swift`（密钥拆成两段异或碎片，运行时还原）；
   - 写 `Resources/Vault/manifest.json`（大小、明文哈希，可做完整性核对）。
3. App 运行时用 CryptoKit 的 `ChaChaPoly` 解密（格式完全互通，见 `ContentVault.swift`）。

换密钥：`python tools/pack_assets.py --rotate-key`，旧包里的密文立刻作废。

> 提醒：密钥在客户端里，属于「提高提取门槛」，不是密码学意义上的保密。要真正的保密，素材别全打进包，改走服务端按授权下发（参考 `hardening/license-service`）。

## 还差哪一步：写车机（需要真机）

`Data/DeviceBridge.swift` 里已经把「写车机」隔离成一个协议 `DeviceBridge`，界面只认协议。接入思路（给接手的开发者）：

1. 复用开源 StikDebug（原版 App 里就带着它，MIT 协议）：负责开发者模式 + personalized DDI + `remotepairing` 隧道 + `NetworkExtension` 的 `packet-tunnel-provider`。
2. 隧道起来后，把壁纸按 v1 的命名写进缓存目录（路径常量已放在 `CarPlayTarget`）：
   - 缓存目录：`/Library/Caches/com.apple.CarPlayApp/wallpaper-images`
   - 文件名：`CARWallpaper<id>-<Dark|Light>-<index>.cpbitmap`
   - 辅助进程：`/Applications/CarPlayWallpaper.app`
3. 把 `StubDeviceBridge` 换成真实现（`pair()` 建隧道、`write(_:)` 写文件），界面代码一行都不用动。
4. 这一步必须在 Mac + 真车/模拟 CarPlay 上调试，Windows 环境做不了，我也不好替你拍胸口保证能跑通。

## 边界与诚实说明

- 这是**重建**，不是「把原包改一改」。原包是别人编译的，我不碰、也不分发它的改动版。
- 界面与数据格式按你原有素材和 `WallpaperCatalog.json` 对齐，交互是我重写的，不保证和原版像素级一致。
- 写车机依赖开发者模式（巨魔/自签生态那一套），App Store 大概率拒收——这点和原版一致。
- 想给朋友用：这个工程天然没有收费项，编译出来自签分发即可；想加回「授权/卡密」，去 `hardening/license-service`，两者是配套的。

## 常用命令

```powershell
# 重新加密素材（改了 assets-src/previews 之后）
python tools\pack_assets.py

# 换密钥
python tools\pack_assets.py --rotate-key

# 自检加密算法
python tools\chacha20poly1305.py
```
