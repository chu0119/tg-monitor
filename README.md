# TG Monitor - Telegram 群组信息监测预警系统

一个功能完整的 Telegram 消息监控、关键词匹配、告警和分析系统。支持实时监控多个 Telegram 频道和群组，自动匹配关键词并多渠道告警通知。

## ✨ 功能特性

### 核心功能

| 功能 | 描述 |
|------|------|
| **多账号管理** | 支持同时管理多个 Telegram 账号 |
| **实时监控** | WebSocket 实时推送新消息到前端 |
| **关键词匹配** | 支持精确、包含、正则、模糊匹配，支持关键词分组 |
| **告警系统** | 多级别告警（低、中、高、严重），支持批量处理 |
| **多渠道通知** | 邮件、钉钉、企微、Server酱、Webhook、Telegram Bot |
| **数据分析** | 词云、情感分析、趋势图表、大屏展示 |
| **消息导出** | CSV、JSON、Excel 格式，流式导出支持大数据量 |
| **历史消息** | 支持拉取历史消息（最多7天） |
| **自动备份** | 数据库自动定时备份 |

### 界面特性

- 🌙 深色科技风主题，支持浅色/深色切换
- 📱 完整的移动端适配（响应式布局）
- 🔔 右上角实时显示 Telegram 连接状态和网络状态
- 📊 仪表盘：消息趋势、告警统计、关键词热度

## 🛠 技术栈

### 后端
- **框架**: Python 3.13 + FastAPI
- **数据库**: MySQL 8.0
- **ORM**: SQLAlchemy 2.0 + Alembic
- **Telegram 客户端**: Telethon
- **实时通信**: WebSocket
- **异步任务**: asyncio

### 前端
- **框架**: React 18 + TypeScript
- **构建工具**: Vite
- **路由**: React Router
- **UI**: TailwindCSS + 自定义组件库
- **图表**: Recharts
- **状态管理**: React Hooks + Context

## 📦 快速开始

### 环境要求

- Python 3.10+
- Node.js 18+
- MySQL 8.0+
- Telegram API 凭证（从 https://my.telegram.org 获取）
- 代理（国内服务器需要，用于连接 Telegram）

### 1. 克隆项目

```bash
git clone https://github.com/chu0119/tg-monitor.git
cd tg-monitor
```

### 2. 后端配置

```bash
cd backend

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入你的配置
```

**`.env` 配置说明：**

| 变量 | 说明 | 示例 |
|------|------|------|
| `DATABASE_TYPE` | 数据库类型 | `mysql` |
| `MYSQL_HOST` | 数据库地址 | `localhost` |
| `MYSQL_PORT` | 数据库端口 | `3306` |
| `MYSQL_USER` | 数据库用户 | `root` |
| `MYSQL_PASSWORD` | 数据库密码 | `your_password` |
| `MYSQL_DATABASE` | 数据库名 | `tg_monitor` |
| `TELEGRAM_API_ID` | Telegram API ID | `12345678` |
| `TELEGRAM_API_HASH` | Telegram API Hash | `abcdef123456...` |
| `SOCKS5_PROXY` | SOCKS5 代理（可选） | `socks5://127.0.0.1:7897` |

### 3. 前端配置

```bash
cd frontend

# 安装依赖
npm install

# 配置环境变量（可选）
cp .env.example .env
# 默认自动适配，无需修改
```

### 4. 启动服务

```bash
# 后端
cd backend
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000

# 前端（新终端）
cd frontend
npm run dev
```

访问 http://localhost:5173 即可使用。

## 🚀 生产部署（Systemd）

项目内置了 systemd 服务配置，支持开机自启和自动恢复。

### 一键安装

```bash
chmod +x install-services.sh
sudo ./install-services.sh
```

### 服务说明

| 服务 | 说明 | 端口 |
|------|------|------|
| `tgjiankong-backend` | 后端 API 服务 | 8000 |
| `tgjiankong-frontend` | 前端 Vite 服务 | 5173 |
| `tgjiankong-healthcheck.timer` | 健康检查（每5分钟） | - |

### 管理命令

```bash
# 查看状态
sudo systemctl status tgjiankong-backend tgjiankong-frontend

# 重启
sudo systemctl restart tgjiankong-backend

# 查看日志
journalctl -u tgjiankong-backend -f

# 手动健康检查
./auto-restart.sh
```

## 📁 项目结构

```
tg-monitor/
├── backend/
│   ├── app/
│   │   ├── api/           # API 路由
│   │   │   ├── accounts.py     # 账号管理
│   │   │   ├── alerts.py       # 告警管理
│   │   │   ├── analysis.py     # 数据分析
│   │   │   ├── conversations.py # 会话管理
│   │   │   ├── dashboard.py    # 仪表盘
│   │   │   ├── keywords.py     # 关键词管理
│   │   │   ├── messages.py     # 消息查询
│   │   │   └── ...
│   │   ├── core/          # 配置、数据库连接
│   │   ├── models/        # SQLAlchemy 模型
│   │   ├── schemas/       # Pydantic 模型
│   │   ├── services/      # 业务逻辑层
│   │   ├── telegram/      # Telegram 客户端和监控
│   │   └── utils/         # 工具函数
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── pages/         # 页面组件
│   │   ├── components/    # 通用组件
│   │   ├── hooks/         # 自定义 Hooks
│   │   ├── routes/        # 路由配置
│   │   ├── styles/        # 全局样式
│   │   └── i18n/          # 国际化
│   └── .env.example
├── auto-restart.sh        # 健康检查脚本
├── install-services.sh    # 服务安装脚本
└── README.md
```

## 🔧 常见问题

### Q: 首次启动需要做什么？
1. 配置 `.env` 文件（数据库和 Telegram API 凭证）
2. 启动后端，首次会自动创建数据库表
3. 在网页上添加 Telegram 账号，输入手机号和验证码登录
4. 添加要监控的群组/频道，配置关键词

### Q: 连接 Telegram 失败？
- 确保已配置 `SOCKS5_PROXY`（国内服务器必须）
- 确保代理服务正常运行
- 检查 Telegram API ID 和 Hash 是否正确

### Q: 支持多少个群组监控？
理论上无上限，实际受限于服务器性能。2核4G配置建议不超过500个。

## 📄 License

MIT

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
