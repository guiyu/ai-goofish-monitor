# 闲鱼智能监控机器人

一个基于 Playwright 和AI过滤分析的闲鱼多任务实时监控与智能分析工具，配备了功能完善的 Web 管理界面。

## ✨ 项目亮点

- **可视化Web界面**: 提供完整的Web UI，支持任务的可视化管理、AI标准在线编辑、运行日志实时查看和结果筛选浏览，无需直接操作命令行和配置文件。
- **AI驱动的任务创建**: 只需用自然语言描述你的购买需求，即可一键创建包含复杂筛选逻辑的全新监控任务。
- **多任务并发**: 通过 `config.json` 同时监控多个关键词，各任务独立运行，互不干扰。
- **实时流式处理**: 发现新商品后，立即进入分析流程，告别批处理延迟。
- **深度AI分析**: 集成多模态大语言模型（如 GPT-4o），结合商品图文和卖家画像进行深度分析，精准筛选。
- **高度可定制**: 每个监控任务均可配置独立的关键词、价格范围、筛选条件和AI分析指令 (Prompt)。
- **即时通知**: 通过 [ntfy.sh](https://ntfy.sh/) 将符合AI推荐的商品立即推送到你的手机或桌面。
- **健壮的反爬策略**: 模拟真人操作，包含多种随机延迟和用户行为，提高稳定性。

## 页面截图
后台任务管理
![img.png](img.png)

后台监控截图
![img_1.png](img_1.png)

ntf通知截图
![img_2.png](img_2.png)

## 🚀 快速开始

请遵循以下步骤来配置和启动项目。

### 第 1 步: 环境准备与基础配置 (通用)

无论你选择哪种部署方式，都需要先完成这些基础准备工作。

1.  **克隆项目**:
    ```bash
    git clone https://github.com/dingyufei615/ai-goofish-monitor
    cd ai-goofish-monitor
    ```

2.  **配置环境变量**:
    在项目根目录创建一个 `.env` 文件，并填入你的 OpenAI 和 ntfy 配置。
    ```env
    # OpenAI API 相关配置
    OPENAI_API_KEY="sk-..."
    OPENAI_BASE_URL="https://api.openai.com/v1"  # 如果使用代理，请修改为代理地址
    OPENAI_MODEL_NAME="gpt-4o"

    # ntfy 通知服务配置
    NTFY_TOPIC_URL="https://ntfy.sh/your-topic-name" # 替换为你的 ntfy 主题 URL
    ```

3.  **获取登录状态 (重要!)**:
    由于登录闲鱼需要图形界面进行扫码，这一步**必须在你的本地电脑上完成**。
    - 首先，在本地安装项目依赖：
      ```bash
      pip install -r requirements.txt
      ```
    - 然后，运行登录脚本：
      ```bash
      python login.py
      ```
    - 在弹出的浏览器窗口中，使用**手机闲鱼App扫描二维码**完成登录。成功后，项目根目录会生成一个 `xianyu_state.json` 文件。这个文件是后续所有操作的凭证。

### 第 2 步: 选择你的启动方式

完成以上准备后，你可以选择以下任意一种方式来运行服务。

#### 方式一: 本地直接启动

直接在你的电脑上运行 Web 服务器。

```bash
python web_server.py
```

#### 方式二: 使用 Docker 启动 (推荐)

使用 Docker 可以将服务运行在一个隔离的环境中，更稳定、更可靠。

1.  **构建 Docker 镜像**:
    ```bash
    docker build -t goofish-monitor .
    ```

2.  **启动 Docker 容器**:
    ```bash
    docker run -d -p 8000:8000 --name goofish-app -v $(pwd):/app goofish-monitor
    ```
    > **说明**: `-v $(pwd):/app` 命令会将当前项目目录完整地挂载到容器的 `/app` 目录。这能确保容器读取到你已生成的 `xianyu_state.json` 和 `.env` 文件。同时，所有由程序产生的数据（如 `config.json` 的修改、日志、结果文件、图片）都会被保存在你的本地项目文件夹中，实现了数据的完全持久化和轻松管理。

3.  **管理 Docker 容器**:
    -   查看实时日志: `docker logs -f goofish-app`
    -   停止服务: `docker stop goofish-app`
    -   重启服务: `docker start goofish-app`
    -   进入容器 (用于调试): `docker exec -it goofish-app bash`
    -   删除容器: `docker rm goofish-app`

### 第 3 步: 开始使用

服务启动后，在浏览器中打开 `http://127.0.0.1:8000` 访问管理后台。

1.  在 **“任务管理”** 页面，点击 **“创建新任务”**。
2.  在弹出的窗口中，用自然语言描述你的购买需求（例如：“我想买一台95新以上的索尼A7M4相机，预算1万3以内，快门数低于5000”），并填写任务名称、关键词等信息。
3.  点击创建，AI将自动为你生成一套复杂的分析标准。
4.  回到主界面，点击右上角的 **“🚀 全部启动”**，开始享受自动化监控！

## 📸 Web UI 功能一览

-   **任务管理**:
    -   **AI创建任务**: 使用自然语言描述需求，一键生成监控任务和配套AI分析标准。
    -   **可视化编辑**: 在表格中直接修改任务参数，如关键词、价格范围等。
    -   **启停控制**: 独立控制每个任务的启用/禁用状态，或一键启停所有任务。
-   **结果查看**:
    -   **卡片式浏览**: 以图文卡片形式清晰展示每个符合条件的商品。
    -   **智能筛选**: 可一键筛选出所有被AI标记为“推荐”的商品。
    -   **深度详情**: 查看每个商品的完整抓取数据和AI分析的详细JSON结果。
-   **运行日志**:
    -   **实时日志流**: 在网页上实时查看爬虫运行的详细日志，方便追踪进度和排查问题。
-   **系统设置**:
    -   **状态检查**: 一键检查 `.env` 配置、登录状态等关键依赖是否正常。
    -   **Prompt在线编辑**: 直接在网页上编辑和保存用于AI分析的 `prompt` 文件，实时调整AI的思考逻辑。

## ⚙️ 命令行高级用法

对于喜欢命令行的用户，项目同样保留了脚本独立运行的能力。

### 启动监控

直接运行主爬虫脚本，它会加载 `config.json` 中所有启用的任务。
```bash
python spider_v2.py
```
**调试模式**: 如果只想测试少量商品，可以使用 `--debug-limit` 参数。
```bash
# 每个任务只处理前2个新发现的商品
python spider_v2.py --debug-limit 2
```

### 通过脚本创建新任务

`prompt_generator.py` 脚本可以让你通过命令行快速创建新任务。
```bash
python prompt_generator.py \
  --description "我想买一台95新以上的索尼A7M4相机，预算在10000到13000元之间，快门数要低于5000。必须是国行且配件齐全。优先考虑个人卖家，不接受商家或贩子。" \
  --output prompts/sony_a7m4_criteria.txt \
  --task-name "Sony A7M4" \
  --keyword "a7m4" \
  --min-price "10000" \
  --max-price "13000"
```
执行后，它会自动创建新的 `_criteria.txt` 文件，并在 `config.json` 中添加并启用对应的新任务。

## 🚀 工作流程

```mermaid
graph TD
    A[启动主程序] --> B{读取 config.json};
    B --> C{并发启动多个监控任务};
    C --> D[任务: 搜索商品];
    D --> E{发现新商品?};
    E -- 是 --> F[抓取商品详情 & 卖家信息];
    F --> G[下载商品图片];
    G --> H[调用AI进行分析];
    H --> I{AI是否推荐?};
    I -- 是 --> J[发送 ntfy 通知];
    J --> K[保存记录到 JSONL];
    I -- 否 --> K;
    E -- 否 --> L[翻页/等待];
    L --> D;
    K --> E;
```

## 🛠️ 技术栈

- **核心框架**: Playwright (异步) + asyncio
- **Web服务**: FastAPI
- **AI 模型**: OpenAI API (支持 GPT-4o 等多模态模型)
- **通知服务**: ntfy
- **配置管理**: JSON
- **依赖管理**: pip

## 📂 项目结构

```
.
├── .env                # 环境变量，存放API密钥等敏感信息
├── .gitignore          # Git忽略配置
├── config.json         # 核心配置文件，用于定义所有监控任务
├── login.py            # 首次运行必须执行，用于获取并保存登录Cookie
├── spider_v2.py        # 核心爬虫程序
├── prompt_generator.py # AI分析标准生成脚本
├── web_server.py       # Web服务主程序
├── requirements.txt    # Python依赖库
├── README.md           # 就是你正在看的这个文件
├── prompts/            # 存放不同任务的AI分析指令(Prompt)
│   ├── base_prompt.txt
│   └── ..._criteria.txt
├── static/             # Web前端静态文件
│   ├── css/style.css
│   └── js/main.js
├── templates/          # Web前端模板
│   └── index.html
├── images/             # (自动创建) 存放下载的商品图片
├── logs/               # (自动创建) 存放运行日志
└── *.jsonl             # (自动创建) 存放每个任务的抓取和分析结果
```

## 致谢

本项目在开发过程中参考了以下优秀项目，特此感谢：
- [superboyyy/xianyu_spider](https://github.com/superboyyy/xianyu_spider)

以及感谢LinuxDo相关佬友的脚本贡献
- [@jooooody](https://linux.do/u/jooooody/summary)

以及感谢Aider和Gemini 解放双手，代码写起来飞一般的感觉～

## ⚠️ 注意事项

- 请遵守闲鱼的用户协议和robots.txt规则，不要进行过于频繁的请求，以免对服务器造成负担或导致账号被限制。
- 本项目仅供学习和技术研究使用，请勿用于非法用途。
