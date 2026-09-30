基于 **go-zero + Vue 3** 的电商项目 Monorepo。Monorepo 描述代码仓库的组织方式；微服务描述服务的拆分和部署方式，两者不是同一概念。

## 当前仓库结构

目前已具备根 Go module、go-zero 网关 HTTP 启动入口（含 `/health` 探活路由）以及 Vue 3 + Vite 前端入口；用户、商品、库存、订单等业务 RPC 和商城页面仍待实现。空目录不会被 Git 跟踪；下方目录树表示职责规划，不代表每个服务都已完成。

```text
go-mall/
├── apps/
│   ├── gateway/                  # HTTP API 网关目录
│   │   ├── etc/
│   │   │   └── gateway.yaml
│   │   └── internal/
│   │       ├── config/
│   │       ├── handler/
│   │       ├── logic/
│   │       ├── middleware/
│   │       ├── svc/
│   │       └── types/
│   │   ├── gateway.api
│   │   └── gateway.go
│   ├── user/                     # 用户 RPC 服务目录
│   │   ├── etc/
│   │   ├── internal/
│   │   │   ├── config/
│   │   │   ├── logic/
│   │   │   ├── model/
│   │   │   ├── server/
│   │   │   └── svc/
│   │   └── pb/
│   ├── product/                  # 商品 RPC 服务目录
│   ├── stock/                    # 库存 RPC 服务目录
│   └── order/                    # 订单 RPC 服务目录
├── common/                       # 经多个服务确认复用的公共组件
│   ├── errorx/
│   ├── tool/
│   └── xcode/
├── web/                          # Vue 3 前端
│   ├── src/
│       ├── api/
│       ├── assets/
│       ├── components/
│       ├── router/
│       ├── store/
│       └── views/
│   ├── index.html
│   ├── package.json
│   ├── package-lock.json
│   └── vite.config.js
├── deploy/                       # 本地依赖、数据库和部署配置
│   ├── docker-compose/
│   └── sql/
├── go.mod
├── go.sum
└── .gitignore
```

`go test ./apps/gateway` 与 `web/` 下的 `npm run build` 已通过。用户 RPC 的 `user.go`、`user.proto` 及其他业务服务仍是空骨架，尚不能认为 RPC 服务和完整商城已经实现。

## 目录约定

- `apps/gateway` 面向外部提供 HTTP API，负责协议转换、参数校验和调用内部 RPC。鉴权等横切能力可通过中间件实现；不要把商品、订单等领域业务都堆进网关。
- `apps/user`、`apps/product`、`apps/stock`、`apps/order` 按领域拆分为 RPC 服务。每个服务维护自己的 API/Proto、配置、启动入口、`internal/` 实现和数据访问；服务之间通过 RPC 通信，避免直接访问其他服务的数据库。
- `internal/` 用于服务私有实现。`model/` 可放数据库访问代码，`server/` 实现 RPC 接口，`logic/` 放用例逻辑，`svc/` 管理依赖。
- `pb/` 等生成目录应由固定版本的 `protoc`/`goctl` 生成。明确生成文件的来源，不要手动修改生成代码。
- `common/` 只放确实被多个服务复用、且不属于某个业务服务的代码；避免逐渐变成所有业务逻辑的公共大杂烩。
- `web/` 独立管理 Vue 依赖与构建，当前使用 Vue 3、Vue Router、Pinia 和 Vite，入口为 `src/main.js`，开发服务器将 `/api` 代理到 `http://localhost:8888`。常用命令：`npm ci` 安装锁定依赖，`npm run dev` 启动开发服务器，`npm run build` 构建生产文件。Pinia 目录名 `store/` 或 `stores/` 均可，保持一致即可。
- Nginx 配置、Compose 文件和数据库脚本统一由 `deploy/` 管理，避免 README 中同时出现根目录和 `web/` 两种 Nginx 配置位置。数据库结构持续演进后，优先采用有版本号的迁移脚本，而不只依赖首次初始化 SQL。

## 本地启动

在一个终端中从仓库根目录启动网关：

```bash
cd apps/gateway
go run . -f etc/gateway.yaml
```

网关启动后可访问 `http://localhost:8888/health`。另开一个终端启动前端：

```bash
cd web
npm ci
npm run dev
```

Vite 默认地址为 `http://localhost:5173`；开发代理会把 `/api/...` 转发到网关并去掉 `/api` 前缀。

## Go 模块与代码生成

当前使用仓库根目录的单个 `go.mod` 管理服务和共享包，模块路径为 `github.com/wypwzc/go-mall`，Go 版本声明为 `1.26.3`，go-zero 版本为 `v1.10.3`。只有在服务需要独立版本发布或独立依赖管理时，再考虑拆分 Go module。当前验证环境为 `windows/386`（32 位）；网关包在该环境编译通过，建议 CI 和部署优先使用 `amd64`，并在目标架构重新运行测试。

前端验证环境为 Node.js `22.21.1`、npm `10.9.4`。依赖版本记录在 `web/package-lock.json` 中，团队安装依赖时使用 `npm ci` 保持一致。

以用户服务为例，从仓库根目录生成模型代码：

```bash
goctl model mysql ddl -src deploy/sql/user.sql -dir apps/user/internal/model -c
```

生成代码能减少重复 CRUD 实现；缓存及其一致性、击穿保护行为取决于 go-zero 版本、生成选项和实际运行配置，不应仅凭生成命令作保证。请将 `goctl` 与项目使用的 go-zero 版本保持兼容，并检查生成结果。

## 待完成

1. 定义用户、商品、库存、订单服务的 Proto 契约，生成 RPC 代码并实现配置、启动入口和业务逻辑。
2. 按业务需求补齐 Vue 页面和网关 API，再为核心流程增加服务级与集成测试。
3. 编写 Compose 和数据库初始化/迁移文件，并通过环境变量或未提交的本地配置注入凭据，不要把真实密钥提交到仓库。
4. Jenkinsfile 或其他 CI 工作流按实际部署平台选择，不是 Monorepo 必须包含的文件。