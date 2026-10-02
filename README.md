# resolve-flatpak-action

由本项目**自包含**构建 DaVinci Resolve 的 Flatpak 安装包，并通过 GitHub Actions 自动打包、发布到 **Releases**（不使用 GitHub Releases 之外的其他存储方式）。

> 本项目不依赖任何第三方 flatpak 仓库（如 `pobthebuilder/resolve-flatpak`），所有构建逻辑都在本仓库内完成。

---

## 构建内容

| 项 | 值 |
|---|---|
| 应用 ID | `com.jcleng.Resolve` |
| 构建版本 | DaVinci Resolve **19.0.3**（Linux） |
| 运行时 | `org.kde.Platform` / `io.qt.PySide.BaseApp` 6.11 |
| 产物 | `com.jcleng.Resolve.flatpak`（约 1 GB） |
| 发布方式 | GitHub Release（tag: `flatpakfile`） |

---

## 工作原理

1. **下载**：在构建容器内，通过 Blackmagic Design 注册 API（`/api/register/us/download/<id>`）换取带签名的 CloudFront 临时下载 URL，再下载官方 `DaVinci_Resolve_<ver>_Linux.zip`。
   - 因为官方下载需要注册 / 签名校验，且 `videohelp.com` 等第三方镜像已失效，所以采用 API 换链方式。
   - 签名 URL 有过期时间，**不能硬编码**，必须在构建时动态获取（见 `install-resolve.sh`）。
2. **解包**：`.zip` 内含 `DaVinci_Resolve_<ver>_Linux.run`，该文件是 ELF 运行时 + 内嵌 squashfs。用 `unsquashfs -offset <n>` 提取 squashfs 并复制到 `/app`。
3. **打包**：用 `flatpak-builder` 把所有内容打包成 `com.jcleng.Resolve.flatpak` 并发布到 Release。

---

## 仓库结构

```
resolve-flatpak-action/
├── .github/workflows/build.yml   # GitHub Actions 工作流（手动触发）
├── com.jcleng.Resolve.yaml       # Flatpak manifest（自包含构建定义）
├── install-resolve.sh            # 下载 + 解包 .run 内嵌 squashfs 到 /app
├── resolve.py                    # 运行时启动器（设置 LD_LIBRARY_PATH 后 exec /app/bin/resolve）
├── com.jcleng.Resolve.desktop   # 桌面入口
├── logo.png                     # 512×512 官方 DaVinci Resolve 图标
├── LICENSE
└── README.md
```

---

## 手动构建 / 重新构建

工作流**仅手动触发**（不会因 push 自动运行）：

1. 打开仓库 **Actions → RUN BUILD**
2. 点击 **Run workflow**

构建约需 50–60 分钟（下载 2.9 GB + 解包 + 复制 + `flatpak build-bundle`）。

完成后在仓库 **Releases → `flatpakfile`** 下载 `com.jcleng.Resolve.flatpak`。

---

## 本地安装与使用

```bash
# 安装
flatpak install --user com.jcleng.Resolve.flatpak

# 运行
flatpak run com.jcleng.Resolve
```

首次运行需要主机已配置好 GPU 驱动（开源 Mesa 或 NVIDIA 闭源驱动），并通过 `--device=dri` 访问 GPU。

---

## 依赖说明

manifest 中额外打包了以下运行库，以补齐 Resolve 运行所需：

- **libxcrypt**（`libcrypt.so.1`，runtime 不提供）
- **glu**（`libGLU.so.1`，Resolve 启动依赖）
- **squashfs-tools**（`unsquashfs`，构建期解包使用）
- **python3-requests**（构建期下载 API 调用使用）

---

## 调整版本

要构建其他 DaVinci Resolve 版本，修改 `com.jcleng.Resolve.yaml` 中 `resolve` 模块的 build-options.env：

```yaml
build-options:
  env:
    RESOLVE_VERSION: "19.0.3"                              # 目标版本
    RESOLVE_DLID: "ee1da4f13df74d72b6da783ead2ed875"      # 对应 Blackmagic 下载 ID
```

下载 ID 可通过 Blackmagic 官网支持页对应版本的注册接口获得。
