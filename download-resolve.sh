#!/bin/bash
# 通过 Blackmagic 注册 API 获取带签名的真实下载 URL 并下载 DaVinci Resolve
set -e

PKGVER="${RESOLVE_VERSION:-19.0.3}"
DLID="${RESOLVE_DLID:-ee1da4f13df74d72b6da783ead2ed875}"
ARCHIVE="DaVinci_Resolve_${PKGVER}_Linux.zip"

echo "==> 获取 DaVinci Resolve ${PKGVER} 下载地址..."

# 真实下载 ID 通过注册 API 换取带签名的 CloudFront URL
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
