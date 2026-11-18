# 怎么把这个工程打成 IPA

> **没有 Mac？** 看 [`用GitHub免费打IPA.md`](用GitHub免费打IPA.md)，用 GitHub Actions 的云 Mac 免费编译，全程网页操作、不用命令行。

先说结论：**iOS App 只能在 macOS + Xcode 上编译**。Windows 上装什么工具都编不出 iOS 的 IPA（没有 SDK、没有签名工具）。所以这一步需要一台 Mac——你自己的、朋友的、租的云 Mac、或者淘宝找代编译，都行。

## 你需要准备什么

| 需要 | 说明 |
|---|---|
| 一台 Mac | macOS 13+，装 **Xcode 16+**（App Store 免费） |
| XcodeGen（可选，推荐） | `brew install xcodegen`，用来把 `project.yml` 转成 `.xcodeproj` |
| Apple ID | 生成"给朋友自签"的包**不需要**付费开发者账号 |

## 三种产物的区别（先选你要哪种）

| 产物 | 做法 | 谁装得了 | 备注 |
|---|---|---|---|
| **未签名 IPA**（推荐） | `./build.sh` | 朋友用 AltStore/Sideloadly/Esign 自签后装 | 就是原版那种 `needs-signing` 分发，零成本 |
| 免费 Apple ID 签名 | `./build.sh 你的TEAMID` | 只能装 7 天 | **给不了 NetworkExtension / app-group 权限**，UI 版能跑，写车机那步用不了 |
| 付费开发者（$99/年） | 同上 | 稳定，可带全部权限 | 要上真机调隧道时用这个 |

> 重要：这个 App 的「写车机」功能需要 `NetworkExtension`（packet-tunnel-provider）+ `app-group` 权限。
> **免费 Apple ID 自签给不了这些权限**。要么付费开发者，要么走 TrollStore（仅限可被巨魔利用的系统版本）。
> 如果现在只是先要个 UI 空壳版给朋友看，未签名 IPA 就够。

## 打 IPA：三条命令

```bash
cd app-shell
chmod +x build.sh
./build.sh                 # 未签名 IPA，出现在 app-shell/CarPlayWallpaperStudioShell.ipa
```

要签名版（有 Team ID）：

```bash
./build.sh ABCD1234XY      # 用你的开发者团队签名，导出到 build/CarPlayWallpaperStudioShell.ipa
```

第一次编译如果报 `product bundle identifier` 之类，把 `project.yml` 里的
`PRODUCT_BUNDLE_IDENTIFIER`（现在是 `com.example.CarPlayWallpaperStudio`）改成你自己的。

## 朋友怎么装

1. 拿到你发的 `.ipa`；
2. iPhone 上装 [AltStore](https://altstore.io) 或 Sideloadly / Esign；
3. 用自己的 Apple ID 签名安装；
4. 免费账号 7 天续签一次；付费账号/TrollStore 免续签。

## 给我一个「代编译」的人看，就说这三句

> 1. `cd app-shell && ./build.sh` 出未签名 IPA；
> 2. 要签名版就传 Team ID：`./build.sh TEAMID`；
> 3. 需要改的地方：`project.yml` 的 bundle id、`Data/AppConfig.swift` 的大图源站。

## 我这边还能做的

- 你在 Mac 上跑 `./build.sh` 报错，把报错贴给我，我帮你改到能过；
- 要我出一个「免费 Apple ID 也能签的纯 UI 版」配置（去掉需要特权的那段，只留壁纸浏览/收藏）——说一声我就改。
