#!/usr/bin/env python3
"""DaVinci Resolve launcher for the Flatpak runtime.

Sets up library paths and environment, then execs /app/bin/resolve.
"""
import os
import sys

PREFIX = "/app"


def _mkdir(path):
    """Create a directory (and parents) if it does not exist yet."""
    try:
        os.makedirs(path, exist_ok=True)
    except OSError:
        pass


def main():
    resolve_bin = os.path.join(PREFIX, "bin", "resolve")
    if not os.path.exists(resolve_bin):
        sys.stderr.write("DaVinci Resolve binary not found at %s\n" % resolve_bin)
        return 1

    home = os.path.expanduser("~")
    # Resolve needs several *writable* directories at runtime. /app is read-only
    # in a Flatpak, so these must live in the user's writable data/config home.
    config_dir = os.path.join(home, ".config", "DaVinciResolve")
    log_dir = os.path.join(home, ".local", "share", "DaVinciResolve", "logs")
    support_dir = os.path.join(home, ".local", "share", "DaVinciResolve")
    documents_dir = os.path.join(home, "Documents", "BlackmagicDesign", "DaVinci Resolve")

    for d in (config_dir, log_dir, support_dir, documents_dir):
        _mkdir(d)

    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = (
        os.path.join(PREFIX, "lib")
        + ":"
        + os.path.join(PREFIX, "libs")
        # Mesa rusticl OpenCL (libRusticlOpenCL.so / libgallium) 所在目录，
        # 必须加入 LD_LIBRARY_PATH 否则 OpenCL loader 的 dlopen 找不到它，
        # 导致 Resolve 报 "不支持的GPU处理模式"。
        + ":/usr/lib/x86_64-linux-gnu/GL/default/lib"
        + ":/usr/lib/x86_64-linux-gnu/GL/lib"
        + ":"
        + env.get("LD_LIBRARY_PATH", "")
    )
    env["RESOLVE_INSTALL_LOCATION"] = PREFIX
    # 必须指向可写目录（/app 是只读的，Resolve 启动会因无法创建配置/日志目录而失败）
    env["DAVINCI_RESOLVE_CONFIG_DIR"] = config_dir
    env["DAVINCI_RESOLVE_LOG_DIR"] = log_dir
    # Force X11 (Resolve does not support Wayland yet)
    if "QT_QPA_PLATFORM" not in env:
        env["QT_QPA_PLATFORM"] = "xcb"

    args = [resolve_bin] + sys.argv[1:]
    try:
        os.execvpe(resolve_bin, args, env)
    except Exception as e:  # noqa: BLE001
        sys.stderr.write("Failed to launch DaVinci Resolve: %s\n" % e)
        return 1


if __name__ == "__main__":
    sys.exit(main())
