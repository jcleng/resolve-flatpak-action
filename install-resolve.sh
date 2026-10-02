#!/bin/bash
# 在 build 阶段运行：下载 DaVinci Resolve 安装包，解包内嵌的 squashfs 到 /app
set -e

PKGVER="${RESOLVE_VERSION:-19.0.3}"
DLID="${RESOLVE_DLID:-ee1da4f13df74d72b6da783ead2ed875}"
ARCHIVE="DaVinci_Resolve_${PKGVER}_Linux.zip"
RUNFILE="DaVinci_Resolve_${PKGVER}_Linux.run"

echo "==> 获取 DaVinci Resolve ${PKGVER} 下载地址..."
SIGNED_URL=$(curl -sL --max-time 60 \
  -X POST \
  -H "Host: www.blackmagicdesign.com" \
  -H "Accept: application/json, text/plain, */*" \
  -H "Origin: https://www.blackmagicdesign.com" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.75 Safari/537.36" \
  -H "Content-Type: application/json;charset=UTF-8" \
  -H "Referer: https://www.blackmagicdesign.com/support/download/77ef91f67a9e411bbbe299e595b4cfcc/Linux" \
  -d '{"firstname":"Arch","lastname":"Linux","email":"someone@archlinux.org","phone":"202-555-0194","country":"us","street":"Bowery 146","state":"New York","city":"AUR","product":"DaVinci Resolve"}' \
  "https://www.blackmagicdesign.com/api/register/us/download/${DLID}")

echo "==> 下载 ${ARCHIVE} ..."
curl -sL --max-time 1800 -o "${ARCHIVE}" "${SIGNED_URL}"
echo "==> 下载完成: $(ls -lh "${ARCHIVE}" | awk '{print $5}')"

echo "==> 解压 zip ..."
unzip -q "${ARCHIVE}"

echo "==> 从 .run 中提取 squashfs (offset) ..."
# .run 文件是 ELF 运行时 + 内嵌 squashfs。
# 搜索 'hsqs' 魔数，并验证其后的 block size 字段是否在合法范围 (4K~1M)，
# 以排除普通字符串误匹配（参考 night199uk/resolve-flatpak 的做法）。
RUNFILE_SIZE=$(stat -c %s "${RUNFILE}")
OFFSET=""
POS=0
while [ "${POS}" -lt "${RUNFILE_SIZE}" ]; do
    HIT=$(LC_ALL=C dd if="${RUNFILE}" bs=1 skip="${POS}" count=$((RUNFILE_SIZE - POS)) 2>/dev/null | grep -aob -m1 'hsqs' | sed 's/:.*//')
    [ -z "${HIT}" ] && break
    CAND=$((POS + HIT))
    # block size 位于 offset+12 处的 4 字节小端
    BS=$(LC_ALL=C dd if="${RUNFILE}" bs=1 skip=$((CAND + 12)) count=4 2>/dev/null | od -An -tu4 -t x1 | tr -d ' \n' | head -c 8)
    BS_VAL=$((16#${BS:-0}))
    if [ "${BS_VAL}" -ge 4096 ] && [ "${BS_VAL}" -le 1048576 ]; then
        OFFSET="${CAND}"
        break
    fi
    POS=$((CAND + 4))
done

if [ -z "${OFFSET}" ]; then
    echo "ERROR: 未找到有效的 squashfs superblock" >&2
    exit 1
fi
echo "    squashfs offset = ${OFFSET}"
unsquashfs -quiet -no-progress -no-xattrs -d squashfs-root -offset "${OFFSET}" "${RUNFILE}"

echo "==> 复制应用程序到 /app ..."
cp -a squashfs-root/bin /app/
cp -a squashfs-root/libs /app/
cp -a squashfs-root/share /app/ 2>/dev/null || true
cp -a squashfs-root/graphics /app/ 2>/dev/null || true
cp -a squashfs-root/LUT /app/ 2>/dev/null || true
cp -a squashfs-root/UI_Resource /app/ 2>/dev/null || true
cp -a squashfs-root/Control /app/ 2>/dev/null || true
cp -a squashfs-root/Fusion /app/ 2>/dev/null || true
cp -a squashfs-root/scripts /app/ 2>/dev/null || true
cp -a squashfs-root/docs /app/ 2>/dev/null || true
cp -a squashfs-root/Developer /app/ 2>/dev/null || true
cp -a squashfs-root/plugins /app/ 2>/dev/null || true
cp -a squashfs-root/IOPlugins /app/ 2>/dev/null || true
cp -a squashfs-root/easyDCP /app/ 2>/dev/null || true
cp -a squashfs-root/Fairlight /app/ 2>/dev/null || true
mkdir -p /app/.license /app/Videos/CacheClip /app/Videos/.gallery /app/Documents/BlackmagicDesign

echo "==> 安装完成"
ls -la /app/bin/
