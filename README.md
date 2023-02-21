# resolve-flatpak-action

项目来自[pobthebuilder/resolve-flatpak](https://github.com/pobthebuilder/resolve-flatpak.git)通过官方包生成flatpak的安装包


当前action使用的是`DaVinci_Resolve_18.1.1_Linux.zip`版本


- old-versions下载地址

```shell
# https://www.videohelp.com/software/DaVinci-Resolve/old-versions
# 然后本地浏览器进行下载复制下载地址后取消下载,然后替换本项目的下载地址即可
```

- 文件上传

```shell
# 国内
./transfer wss --no-progress /mnt/d/a/nw/2.img 2>&1 | tee cloudupload.log
# 其他
./transfer gg --no-progress ../LICENSE 2>&1 | tee cloudupload.log
./transfer wet --no-progress ../LICENSE 2>&1 | tee cloudupload.log
```
