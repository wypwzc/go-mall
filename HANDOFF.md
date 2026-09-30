# Go Mall 项目交接说明

> 本文用于交接当前工作区状态。用户最近明确要求“好了不用你继续写了”，本轮只整理交接信息；不要自动继续实现，等待用户明确安排后再动代码。

## 项目目标

这是毕业设计的 Go 电商项目，采用 go-zero + Vue 3 的 Monorepo。依据 `过程文档/V1版本.md`，V1 核心闭环为：

1. 用户注册、登录。
2. 浏览商品列表和商品详情。
3. 用户购买商品时校验库存、预扣库存并创建订单。
4. 查看当前用户的订单列表。

计划服务为 API Gateway + User、Product、Stock、Order 四个 RPC 服务。`过程文档/技术选型.md` 还提到地址簿、购物车、支付超时消息等扩展；它们不属于 V1 主链路，本轮没有实现，除非用户另行确认，不要擅自扩展到支付或完整购物车。

## 用户约束

- 用户明确说过：“你就写代码就行不要在我电脑下载东西”。后续如用户重新要求编码，只能在现有依赖/工具基础上工作；不要运行 `go get`、`go install`、`npm install`/`npm ci`、Docker 镜像 pull/up 等可能联网下载的命令。先检查现有文件和缓存，所有 Go 验证命令都可用 `GOPROXY=off` 避免意外联网。
- 用户最近要求停止继续编码，只创建一份能让下一个 AI 接手的 Markdown；当前任务到此暂停，先等用户指示。
- 保留用户可能做过的修改。特别是 `go.mod`、`apps/gateway/gateway.go`、`apps/gateway/internal/config/config.go`、`apps/gateway/internal/handler/handler.go` 曾被用户或自动化工具编辑过；下一次编辑前必须重新读取。

## 工具链及下载历史

用户环境（最近确认）：

- Windows；Go `1.26.3 windows/386`（32 位）。建议后续部署/CI 使用 amd64，并在目标架构验证。
- Node.js `22.21.1`，npm `10.9.4`。
- 系统已有 `protoc 3.20.3`、Docker CLI 和 MySQL 客户端 `mysql.exe`。
- 当时 `goctl`、`protoc-gen-go`、`protoc-gen-go-grpc` 不在 PATH；Docker daemon 没有启动；localhost 的 MySQL `3306`、Redis `6379` 均不可连接。

在用户提出禁止下载之前，之前的 AI 已执行过：

- `npm install`：安装前端 71 个 npm 包到 `web/node_modules`，生成 `web/package-lock.json`。`package.json` 中包括 Vue `3.5.43`、Vue Router `5.3.1`、Pinia `4.0.3`、Vite `8.3.1`、`@vitejs/plugin-vue 6.0.9`。
- `go install`：安装 `protoc-gen-go v1.36.11`、`protoc-gen-go-grpc v1.5.1` 到 Go 的 `bin` 目录；并生成了四个服务的 protobuf/gRPC Go 代码。
- `go get`：下载 Go 模块到本机 Go module cache，包括 MySQL 驱动 `github.com/go-sql-driver/mysql v1.9.3`、JWT `github.com/golang-jwt/jwt/v5 v5.3.0`、`golang.org/x/crypto v0.41.0` 和传递依赖。
- 没有安装 MySQL 或 Redis 服务端，没有拉取 Docker 镜像，也没有成功启动数据库容器。

重要依赖状态：当前 `go.mod` 写的是 go-zero `v1.10.0`，不是 README 中仍记录的 `v1.10.3`。之前的 `go get` 输出表明 go-zero 及若干传递依赖被降级。不要静默改回；先确认当前 `go.mod`，再决定并在 README 同步说明。

## 已完成

### 项目基础

- 根 `go.mod` 模块路径为 `github.com/wypwzc/go-mall`，已存在 `go.sum`。
- Gateway 当前有 go-zero HTTP 启动入口、配置读取和 `GET /health`。
- Vue + Vite 基础工程已存在，含 Router、Pinia、开发代理及一个简单首页；不是已完成的商城前端。
- `.gitignore` 忽略 `web/node_modules/`、`web/dist/` 等。

### RPC 契约

已编辑/新增并用 `protoc` 生成 Go 消息及 gRPC 客户端/服务端接口：

- `apps/user/user.proto`：Register、Login、GetUser。
- `apps/product/product.proto`：分页 ListProducts、GetProduct。
- `apps/stock/stock.proto`：GetStock、ReserveStock、ReleaseStock。Reserve/Release 使用 order ID，目标是幂等预留/释放。
- `apps/order/order.proto`：CreateOrder、ListOrders。
- 生成代码位于各服务的 `pb/` 目录。`.proto` 是契约源文件，`*.pb.go`、`*_grpc.pb.go` 是生成文件，不要手动修改生成文件。

### 数据库及本地依赖骨架

- `deploy/sql/00-create-databases.sql` 创建 user/product/stock/order 四个独立数据库。
- `deploy/sql/01-user.sql`、`02-product.sql`、`03-stock.sql`、`04-order.sql` 创建基础表；商品及库存 SQL 含演示种子数据。
- `deploy/docker-compose/docker-compose.yaml` 仅配置 MySQL 8.4 和 Redis 7.4，不包含应用服务。Compose 配置曾尝试静态校验，但没有记录可靠退出码；Docker daemon 当时不可用。

## 尚未实现（主要工作）

当前还没有完成用户要求的两个大项：四个 RPC 服务及业务逻辑，以及网关/前端主业务流程。

1. **基础 RPC 服务**：实现 User 的 bcrypt 注册/登录和用户读取；Product 分页查询/详情；Stock 的事务性条件扣减、防超卖、reservation 幂等及释放。为每个 RPC 服务补配置、数据模型、logic、server 和启动入口。
2. **Order 编排**：调用 User 校验用户、Product 获取价格、Stock 预扣；生成订单号并写入订单快照。写订单失败时补偿释放库存。V1 暂不含支付、异步超时取消。
3. **Gateway**：定义/补齐 `gateway.api` 和 REST 接口；实现注册、登录、商品列表/详情、库存查询、创建订单、我的订单；登录签发 JWT，保护用户订单接口；网关通过 gRPC 调服务。当前仅 `/health` 可用。
4. **Vue 页面**：登录/注册、商品列表、商品详情/购买、我的订单；补 `src/api` 请求封装、token 持久化/注销、鉴权路由、加载和错误状态。当前 `src/views` 只有简单 HomeView，没有业务流程。
5. **测试**：为密码逻辑、分页、库存并发/超卖与幂等预留、订单失败补偿写服务级测试；增加可选的真实 MySQL/gRPC 集成测试。当前数据库与 Docker daemon 未启动，不能宣称集成测试通过。
6. **文档**：更新 README。当前 README 仍说 RPC/SQL/Compose 待完成，且 go-zero 版本写 `v1.10.3`，与已存在的 Proto、SQL/Compose 文件和当前 `go.mod v1.10.0` 不完全一致。

## 建议设计约束

- 各服务只访问自己的数据库；订单通过 RPC 访问用户、商品、库存，不跨库查询。
- 金额以整数分 (`price_cents`、`total_cents`) 存储和传递，避免浮点金额。
- 库存必须通过 MySQL 原子条件更新（如 `available >= quantity`）并使用事务记录 reservation，不能先读库存再无锁扣减。
- 下单流程不是跨库 ACID 事务：先校验 User/Product，预留 Stock，再写 Order；Order 持久化失败时释放 reservation。说明补偿失败的风险，未来再引入持久化 saga/outbox。
- 只对已登录用户开放创建订单和查询自己的订单；用户 ID 应从已验证 JWT 获取，不采信请求体中的 user ID。
- `common/` 只放确实跨服务复用的无业务组件，避免服务共享数据库模型或领域逻辑。
- Compose 初始化 SQL 只在 MySQL 数据卷首次初始化时运行；后续 schema 变更应考虑版本化迁移。

## 接手建议

1. 先重新检查 `git status`、`go.mod`、上面列出的用户敏感文件及所有现有目录，识别交接文档创建后用户是否又有修改。
2. 遵守“不下载东西”要求；不要为了开始工作再安装 goctl、数据库服务端或镜像。若现有缓存不足以构建，先说明被阻塞的位置，不要自动联网。
3. 先实现 User/Product/Stock 并编译，再实现 Order saga，再做 Gateway 与前端，最后补测试和修订 README。每个小阶段先做窄验证。
4. 数据库/Redis/容器集成测试需要用户主动启动本地基础设施或明确允许拉取镜像；不能把 Compose 文件存在等同于集成环境已运行。

## 当前验证记录

- 四个 `.proto` 曾通过系统 `protoc` 解析并生成 Go 代码。
- 在较早阶段（仅 Gateway `/health` 的代码状态）`go test ./apps/gateway` 曾通过；这不代表当前完整仓库或新增加的 RPC 契约/SQL 已通过全量测试。
- Vue 基础入口曾通过 `npm run build`；尚无商城页面。
- 曾尝试 `go mod verify`，它报告全局 Go module cache 中 `github.com/segmentio/encoding@v0.5.3` 目录被修改。不要通过清空全局 Go cache 来处理。
- Vite 开发服务器后来已退出；目前不要假设 `localhost:5173` 正在运行。
