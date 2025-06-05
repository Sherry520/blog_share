---
html:
    toc: true
    # number_sections: true # 标题开头加上编号
    toc_depth: 6
    toc_float:
        collapsed: false # 控制文档第一次打开时目录是否被折叠
        smooth_scroll: true # 控制页面滚动时，标题是否会随之变化
---

[toc]

---

### 一、问题描述

通常我们使用官方提供的命令形式如下：

```bash
[path/to/ascp] -P33001 -i [path/to/key/file] -QT -l100m -k1 -d aspera01@download.cncb.ac.cn:gsa/CRA000112 /your/local/path
```

通常连接不到服务器可能是忘记添加参数` -P33001`。

但是如果依然存在如下问题，我们需要检查网络连接和端口：

```shell
ascp.exe: Failed to open TCP connection for SSH, exiting.

Session Stop  (Error: Failed to open TCP connection for SSH)
```

### 二、解决步骤

#### 1. 问题诊断：

目标服务器是否可达，运行命令测试网络连通性：

`PowerShell`中运行：

```powershell
Test-NetConnection download.cncb.ac.cn -Port 33001
```

若连接失败：

```powershell
警告: TCP connect to (124.16.164.229 : 33001) failed
警告: Ping to 124.16.164.229 failed with status: TimedOut


ComputerName           : download.cncb.ac.cn
RemoteAddress          : 124.16.164.229
RemotePort             : 33001
InterfaceAlias         : 以太网
SourceAddress          : 192.168.50.69
PingSucceeded          : False
PingReplyDetails (RTT) : 0 ms
TcpTestSucceeded       : False
```

#### 2. 检查本地防火墙（关键步骤）

`powershell` 中运行：

```powershell
# 临时关闭防火墙测试（仅用于诊断）
netsh advfirewall set allprofiles state off
```

`powershell` 中重新运行测试：

```powershell
Test-NetConnection download.cncb.ac.cn -Port 33001
```
若成功：需添加防火墙放行规则。
`powershell（管理员）` 中运行

```powershell
netsh advfirewall firewall add rule name="Aspera" dir=out action=allow protocol=TCP remoteport=33001
netsh advfirewall set allprofiles state on  # 重新开启防火墙
```

这样问题就解决了。
感谢[`Deepseekp`](https://chat.deepseek.com/)的帮助。

如何还有有问题，欢迎在评论区留言。
