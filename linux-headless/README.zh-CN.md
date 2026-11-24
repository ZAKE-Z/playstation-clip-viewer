# PS5 媒体图库 · Linux 版

简体中文 · [English](README.md)

在无桌面的 Debian 上浏览和备份自己的 PlayStation 视频与截图。管理页提供中英文切换，支持预览、按游戏归档、批量任务重启后续跑、逐文件失败重试，以及校验 WebDAV 副本后清理本地视频。服务器不需要安装桌面或浏览器。

这是 [PlayStation Clip Viewer](https://github.com/CallMeTak/playstation-clip-viewer) 的非官方扩展；上游 Flutter 应用保留不变。Sony 接口可能变化；仓库不提供 Sony OAuth 凭据。

## 安装与登录

1. 在 Debian 13 上进入 `linux-headless/`，执行 `sudo sh install.sh`。需要 Python 3.11 或更新版本，以及 systemd。
2. 用 root 权限编辑 `/etc/psclips/psclips.env`，配置你有权使用、且兼容 PSN 图库流程的 `PSCLIPS_OAUTH_CLIENT_ID`、`PSCLIPS_OAUTH_CLIENT_SECRET`、`PSCLIPS_OAUTH_REDIRECT_URI`。回调地址必须与 OAuth 客户端注册信息一致。可选配置 `PSCLIPS_OAUTH_SCOPES` 和 `PSCLIPS_PROXY`。保存后执行 `sudo systemctl restart psclips`。未配置有效的 OAuth 客户端时，管理页仍可打开，但不能导入 Sony 会话。
3. 将可信的 SSH 用户加入管理页访问组：`sudo usermod -aG psclips YOUR_LINUX_USERNAME`，然后重新登录 SSH。此组可经本地套接字完整管理应用，只授予可信账号。
4. 在自己的电脑上打开 SSH 隧道并保持运行：

   ```sh
   ssh -N -o ExitOnForwardFailure=yes \
     -L 127.0.0.1:18765:/run/psclips/admin.sock YOUR_LINUX_USERNAME@YOUR_SERVER
   ```

   浏览器打开 <http://127.0.0.1:18765/>。右上角 **EN / 中文** 可切换语言，当前浏览器会记住选择。
5. 在 **系统设置 → Sony 账号登录**中用同一个浏览器完成 Sony 登录，然后打开会话接口，粘贴返回的 `npsso` 值。不要把它写入命令、日志或 GitHub。再到 **系统设置 → WebDAV 存储**填写有写入权限的目录和登录信息，优先用 HTTPS。

## 日常使用

- 点击缩略图预览。可按视频、截图和归档状态筛选，再勾选下载。普通下载跳过已经校验保存的条目；**强制重新下载**可以补回缺失备份，但不会覆盖同名且内容不同的文件。
- 文件按游戏分目录，保留 Sony 素材标题，扩展名以实际下载格式为准。本地库在 `/var/lib/psclips/captures/`。
- **任务与失败记录**显示失败原因和重试按钮。服务重启后从未完成的文件继续；完整落盘的文件直接续做上传，未下完的文件从头重下。清除失败记录不会删除素材，可重试的条目会保留。
- 开启**自动下载视频**后，每五分钟检查启用之后上传的视频。只能下载 Sony 云端仍可用的素材。
- **删除本地视频**会先回读 WebDAV 副本并验证 SHA-256，只清理校验通过的本地视频，不删除截图、Sony 云端文件或 WebDAV 文件。

## 可选：局域网直接访问

默认通过 SSH 隧道访问，不向局域网开放明文 HTTP。若要直连 HTTPS，请按[英文指南的局域网部署步骤](README.md#optional-direct-lan-access)配置你自己的 TLS 证书和独立管理密码。服务只接受容器或主机当前私有 IPv4 直连网段的访问，不要做公网端口转发。

排查服务可用 `systemctl status psclips` 和 `journalctl -u psclips -n 50`。不要将配置、证书、数据库、日志或下载的素材提交到仓库。
