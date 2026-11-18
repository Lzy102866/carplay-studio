# 没有 Mac，也能免费打出 IPA（GitHub Actions）

核心思路：把工程传到 GitHub，用 GitHub 提供的 **macOS 云服务器（Actions）** 帮你编译，产物下载下来就是 IPA。**不用 git、不用命令行**，全程网页点几下。

## 0. 先说清楚：什么东西不能传

`app-shell` 文件夹里有一个文件 **`vault.key`**，是素材加密的密钥。**传上去就等于把密钥公开**，谁都能解开你的壁纸素材。

→ 上传前，先把 `vault.key` 从 `app-shell` 里**剪出来放到桌面**（编完再放回去也行）。构建不依赖它（密钥已经烘焙进代码里的碎片文件），所以不传它照样能出包。

## 1. 注册 GitHub（一次）

打开 <https://github.com> → Sign up → 邮箱 + 用户名 + 密码，免费。

## 2. 新建仓库

1. 登录后，点右上角 **"+" → New repository**；
2. Repository name 填 `carplay-studio`（随便）；
3. **Public**（公开仓库，Actions 免费额度最宽裕；不放心就选 Private，每月也有 2000 分钟，够用）；
4. 别的都不动，点 **Create repository**。

## 3. 上传工程

1. 进到刚建的仓库，点 **"Add file" → "Upload files"**；
2. 打开你电脑里的 `app-shell` 文件夹，**全选里面所有东西拖进去**（已经包含 `CarPlayWallpaperStudioShell/`、`project.yml`、`build.sh`、`.github/workflows/build-ipa.yml` 等）；
3. 页面底部点 **Commit changes**（绿色按钮）。

> 说明：`.github/workflows/build-ipa.yml` 这个构建脚本我已经替你放进 `app-shell` 里了，拖上去时一起带过去。如果拖漏了，就"Add file → Create new file"，文件名填 `.github/workflows/build-ipa.yml`，把下面这段粘进去：

```yaml
name: Build IPA (no Mac needed)
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Show Xcode
        run: xcodebuild -version
      - name: Install XcodeGen
        run: brew install xcodegen
      - name: Generate project
        run: xcodegen generate
      - name: Build unsigned IPA
        run: |
          chmod +x build.sh
          ./build.sh
      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: CarPlayWallpaperStudioShell
          path: CarPlayWallpaperStudioShell.ipa
          if-no-files-found: error
```

## 4. 运行构建

1. 仓库顶部点 **Actions** 标签；
2. 左侧列表点 **"Build IPA (no Mac needed)"**；
3. 右边点 **"Run workflow"** → 绿色 **Run workflow** 按钮。

## 5. 下载 IPA

1. 等 3～6 分钟（第一次要装编译工具，慢一点）；
2. 页面刷新后，最上面那一次运行会变**绿色对勾**；
3. 点进去，往下拉到底部 **Artifacts**；
4. 点 **CarPlayWallpaperStudioShell** 下载，解压后就是 `CarPlayWallpaperStudioShell.ipa`。

## 产物是什么

**未签名 IPA**（`needs-signing`）——和你原版那种分发方式一样：
- 发给你朋友，他们用 AltStore / Sideloadly / Esign 用自己的 Apple ID 自签安装；
- 免费 Apple ID 装完有效 7 天，付费开发者 / TrollStore 免续签。

## 常见问题

- **跑到一半变红叉**：点进去看红色的步骤，把 `Run ...` 那几行报错原样复制给我，我帮你改。
- **Artifacts 里没有 IPA**：多半是第 3 步 `vault.key` 之外的文件没传全（`Vault/*.enc`、`VaultKey.generated.swift` 都在才能编）。
- **不想公开壁纸素材**：建仓库选 Private；或者上传前把 `assets-src/`（明文预览图）删掉，不影响编译。
- **连 GitHub 都不想折腾**：闲鱼/淘宝搜"iOS 代编译"，把 `app-shell`（同样去掉 `vault.key`）打包发过去，一句话——"跑 `./build.sh` 出未签名 IPA"。

## 对比一下你现在的三条路

| 路 | 成本 | 结果 |
|---|---|---|
| GitHub Actions（本页） | 免费、无 Mac | 未签名 IPA，朋友自签装 |
| 淘宝/闲鱼代编译 | 几十块 | 同上 |
| 借/租一台 Mac | 看情况 | 同上，还能自己随时改代码重编 |
