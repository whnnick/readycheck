# ReadyCheck 0.7.1

[English](RELEASE_NOTES.md) · [验收记录](QA.zh-CN.md)

- 修复 Muse 网站更新后 macOS 版无法读取周额度和重置时间的问题。ReadyCheck 可复用有效的 Muse 会话，启动时遇到临时读取错误会自动重试一次。
- Windows 继续提供 Codex 监控，本次同步更新安装包版本号。

macOS 应用使用 ReadyCheck 自签名证书，未经过 Apple 公证。macOS 可能会要求重新确认已有 Codex 和 DeepSeek 凭据的钥匙串访问。
