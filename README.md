# Telegram 监控告警系统

一个功能完整的 Telegram 消息监控、关键词匹配、告警和分析系统。支持实时监控多个 Telegram 频道和群组，自动匹配关键词并多渠道告警通知。

## 功能特性

### 核心功能

| 功能 | 描述 |
|------|------|
| **多账号管理** | 支持同时管理多个 Telegram 账号 |
| **实时监控** | WebSocket 实时推送新消息 |
| **关键词匹配** | 支持精确、包含、正则、模糊匹配 |
| **告警系统** | 多级别告警（低、中、高、严重） |
| **多渠道通知** | 邮件、钉钉、企微、Server酱、Webhook、Telegram |
| **数据分析** | 词云、情感分析、趋势图表 |
| **消息导出** | CSV、JSON、Excel 格式 |
| **历史消息** | 支持拉取历史消息（最多7天） |

### 技术亮点

- ✅ **MySQL 数据库** - 支持大规模数据存储
- ✅ **Gunicorn 多进程** - 生产级性能，自动重启崩溃的 worker
- ✅ **心跳检测** - 自动检测并重连断开的连接
- ✅ **会话清理** - 自动清理过期登录会话
- ✅ **日志轮转** - 自动管理日志大小
- ✅ **备份压缩** - 自动备份并压缩数据
- ✅ **死锁优化** - 使用 MySQL 原生 SQL 避免死锁
- ✅ **超时控制** - 消息处理和 WebSocket 广播超时保护

## 技术栈

### 后端
- **框架**: FastAPI 0.115+ + Python 3.12+
- **数据库**: MySQL 8.0+ + SQLAlchemy 2.0+
- **Telegram**: Telethon 1.40+ （异步 Telegram 客户端）
- **Web服务器**: Gunicorn 25.1+ + Uvicorn workers
- **实时通信**: WebSocket
- **日志**: Loguru 0.7+

### 前端
- **框架**: React 19+ + TypeScript 5+
- **路由**: TanStack Router 1+
- **状态管理**: TanStack Query 5+
- **样式**: Tailwind CSS 3+
- **图表**: Recharts 3+

## 快速开始

### 环境要求

| 依赖 | 版本要求 |
|------|----------|
| Python | 3.12+ |
| Node.js | 18+ |
| MySQL | 8.0+ |
| 系统 | Linux（推荐 Ubuntu 22.04+） |

### 1. 克隆项目

```bash
git clone <repository-url>
cd tgjiankong
```

### 2. 安装依赖

```bash
./start.sh install
```

这将自动安装：
- Python 虚拟环境和依赖
- npm 前端依赖
- Gunicorn Web 服务器

### 3. 配置数据库

#### 安装 MySQL

```bash
sudo apt update
sudo apt install mysql-server mysql-client -y
sudo mysql_secure_installation
```

#### 创建数据库和用户

```bash
sudo mysql -u root -p
```

```sql
-- 创建数据库
CREATE DATABASE tg_monitor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建用户
CREATE USER 'tgmonitor'@'localhost' IDENTIFIED BY 'TgMonitor2026Secure';
GRANT ALL PRIVILEGES ON tg_monitor.* TO 'tgmonitor'@'localhost;
FLUSH PRIVILEGES;
```

#### 配置后端

编辑 `backend/.env`：

```env
# 数据库配置
DATABASE_TYPE=mysql
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=tgmonitor
MYSQL_PASSWORD=TgMonitor2026Secure
MYSQL_DATABASE=tg_monitor

# Telegram API（访问 https://my.telegram.org/apps 获取）
TELEGRAM_API_ID=your_api_id
TELEGRAM_API_HASH=your_api_hash

# 其他配置
DEBUG=false
LOG_LEVEL=INFO
```

### 4. 配置 Telegram API

1. 访问 [https://my.telegram.org/apps](https://my.telegram.org/apps)
2. 创建应用获取 `api_id` 和 `api_hash`
3. 将配置写入 `backend/.env`

### 5. 启动服务

```bash
# 启动所有服务
./start.sh start

# 查看状态
./start.sh status

# 查看日志
./start.sh logs backend
```

### 6. 访问应用

| 服务 | 地址 |
|------|------|
| **前端** | http://localhost:5173 |
| **后端 API** | http://localhost:8000 |
| **API 文档** | http://localhost:8000/docs |

## 服务管理

### 启动脚本命令

```bash
./start.sh install          # 安装依赖
./start.sh start            # 启动服务
./start.sh stop             # 停止服务
./start.sh restart          # 重启服务
./start.sh status           # 查看状态
./start.sh logs backend     # 查看后端日志
./start.sh logs access      # 查看访问日志
```

### 手动启动（调试模式）

```bash
# 后端（开发模式）
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 前端
cd frontend
npm run dev
```

### 生产模式（推荐）

```bash
# 后端（使用 Gunicorn）
cd backend
./venv/bin/gunicorn app.main:app \
  --bind 0.0.0.0:8000 \
  --workers 2 \
  --worker-class uvicorn.workers.UvicornWorker \
  --timeout 120 \
  --daemon
```

## 功能使用指南

### 1. 添加 Telegram 账号

1. 进入前端"账号管理"页面
2. 点击"添加账号"
3. 输入手机号（国际格式，如 +8613800138000）
4. 点击"发送验证码"
5. 输入收到的验证码
6. 如需两步验证，输入密码

### 2. 添加监控会话

1. 进入"会话监控"页面
2. 点击"获取会话列表"
3. 选择要监控的频道或群组
4. 配置监控参数：
   - 启用实时监控
   - 配置关键词组
   - 启用历史消息拉取

### 3. 配置关键词

**关键词类型：**

| 类型 | 说明 | 示例 |
|------|------|------|
| **精确匹配** | 完全匹配关键词 | `apple` 匹配 "apple" 不匹配 "applepie" |
| **包含匹配** | 包含关键词 | `apple` 匹配 "apple", "applepie" |
| **正则表达式** | 正则匹配 | `\d{11}` 匹配11位数字 |
| **模糊匹配** | 编辑距离匹配 | `apple` 也能匹配 "appl" |

**关键词组：**

可以创建多个关键词组，每个组包含多个关键词和匹配规则。

### 4. 配置告警通知

**支持的通知渠道：**

| 渠道 | 配置方法 |
|------|----------|
| **邮件** | 配置 SMTP 服务器信息 |
| **钉钉** | 配置 Webhook URL |
| **企业微信** | 配置 Webhook URL |
| **Server酱** | 配置 SendKey |
| **Telegram** | 配置 Bot Token 和 Chat ID |
| **自定义 Webhook** | 配置 POST URL |

## 数据库结构

### 主要表结构

| 表名 | 说明 |
|------|------|
| `telegram_accounts` | Telegram 账号信息 |
| `conversations` | 监控的会话（频道/群组） |
| `messages` | 消息记录 |
| `senders` | 发送者信息 |
| `keywords` | 关键词定义 |
| `keyword_groups` | 关键词组 |
| `conversation_keywords` | 会话-关键词关联 |
| `alerts` | 告警记录 |

## 性能优化

### 已实现的优化

1. **MySQL 死锁优化**
   - 使用 `INSERT ... ON DUPLICATE KEY UPDATE` 原子更新
   - 联合更新会话和账号统计
   - 死锁自动重试机制

2. **资源管理**
   - 登录会话超时清理（5分钟）
   - WebSocket 连接超时清理
   - 事件处理器自动清理
   - 后台任务超时控制

3. **日志管理**
   - 单文件最大 10MB 自动轮转
   - 保留 7 天
   - gzip 压缩旧日志

4. **备份策略**
   - 每 7 天自动备份
   - 保留 4 个备份
   - gzip 压缩备份文件

### 性能指标

| 指标 | 值 |
|------|-----|
| 并发连接 | 每进程 1000+ |
| API 响应时间 | < 10ms（本地） |
| 消息处理延迟 | < 100ms |
| 内存占用 | ~200MB（空闲）~500MB（运行中） |

## 故障排查

### 后端无法启动

```bash
# 检查端口占用
lsof -i :8000

# 检查日志
tail -f /tmp/tg-monitor.log
tail -f /tmp/tg-monitor-error.log
```

### Telegram 客户端连接失败

```bash
# 检查会话文件权限
ls -la backend/sessions/

# 清理会话锁文件
rm -f backend/sessions/*-journal
```

### MySQL 连接失败

```bash
# 测试连接
mysql -u tgmonitor -pTgMonitor2026Secure -e "SELECT 1"

# 检查 MySQL 状态
sudo systemctl status mysql
```

### 监控不到消息

```bash
# 检查客户端状态
curl http://localhost:8000/api/v1/accounts

# 查看监控日志
./start.sh logs backend | grep -i "监控\|monitor\|message"

# 检查心跳
./start.sh logs backend | grep -i "心跳\|heartbeat"
```

## 系统架构

```
┌─────────────────────────────────────────────────────────────┐
│                         前端 (React)                        │
│                    http://localhost:5173               │
└────────────────────────┬────────────────────────────────────┘
                         │ WebSocket + HTTP
┌────────────────────────▼────────────────────────────────────┐
│                    反向代理 (可选)                         │
│                        Nginx (80/443)                       │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│              后端 (FastAPI + Gunicorn)                     │
│                   http://localhost:8000                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Gunicorn Master                                    │   │
│  │  ├─ Worker 1 (Uvicorn)                              │   │
│  │  ├─ Worker 2 (Uvicorn)                              │   │
│  │  └─ ...                                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  TelegramClientManager (多账号管理)                │   │
│  │  ├─ Account 1 (+86139...)                          │   │
│  │  └─ Account 2 (+86140...)                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  MessageMonitor (消息监控器)                         │   │
│  │  ├─ 249 监控任务                                      │   │
│  │  └─ 实时消息处理                                      │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│              MySQL 8.0 (tg_monitor 数据库)                  │
│  ├─ telegram_accounts    ├─ messages                     │
│  ├─ conversations        ├─ senders                       │
│  ├─ keywords            ├─ alerts                        │
│  └─ keyword_groups                                     │
└─────────────────────────────────────────────────────────────┘
```

## 安全建议

1. **修改默认密码**
   - MySQL root 密码
   - 数据库用户密码
   - 应用密钥

2. **配置防火墙**
   ```bash
   sudo ufw allow 8000/tcp
   sudo ufw enable
   ```

3. **使用 HTTPS**
   - 配置 Nginx 反向代理
   - 使用 Let's Encrypt 证书

4. **定期备份**
   - 自动备份已配置
   - 备份文件位于 `backend/backups/`

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
