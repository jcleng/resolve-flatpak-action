#!/usr/bin/env python3
"""DaVinci Resolve launcher for the Flatpak runtime.

Sets up library paths and environment, then execs /app/bin/resolve.
"""
import os
import sys

PREFIX = "/app"


def main():
    resolve_bin = os.path.join(PREFIX, "bin", "resolve")
    if not os.path.exists(resolve_bin):
        sys.stderr.write("DaVinci Resolve binary not found at %s\n" % resolve_bin)
        return 1

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
    env["DAVINCI_RESOLVE_CONFIG_DIR"] = os.path.join(PREFIX, "config")
    env["DAVINCI_RESOLVE_LOG_DIR"] = os.path.join(PREFIX, "logs")
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
