基于 **go-zero + Vue 3** 的微服务单体仓库（Monorepo）设计，推荐的标准项目目录结构如下：



```
go-mall/                           # 项目根目录
├── apps/                          # 所有后端微服务目录
│   ├── gateway/                   # 【API 网关】对外暴露 HTTP 接口，做鉴权与路由
│   │   ├── etc/
│   │   │   └── gateway.yaml       # 网关配置文件
│   │   ├── internal/
│   │   │   ├── config/            # 配置映射结构体
│   │   │   ├── handler/           # HTTP 路由 handler (goctl 自动生成)
│   │   │   ├── logic/             # 网关业务逻辑 (负责发起 RPC 调用)
│   │   │   ├── middleware/        # JWT 鉴权、跨域等中间件
│   │   │   ├── svc/               # 依赖上下文 (注入各 RPC 客户端)
│   │   │   └── types/             # 请求/响应结构体 (goctl 自动生成)
│   │   ├── gateway.api            # API 协议定义文件
│   │   ├── gateway.go             # 网关服务启动入口
│   │   └── Dockerfile             # 网关构建文件
│   │
│   ├── user/                      # 【用户 RPC 服务】
│   │   ├── etc/
│   │   │   └── user.yaml          # 用户服务配置 (MySQL/Redis 连接)
│   │   ├── internal/
│   │   │   ├── config/
│   │   │   ├── logic/             # 登录/注册等核心业务代码
│   │   │   ├── model/             # 数据库 CRUD 操作 (goctl 从 SQL 生成)
│   │   │   ├── server/            # gRPC 接口实现
│   │   │   └── svc/               # 上下文资源管理
│   │   ├── pb/                    # Protobuf 编译生成的 Go 代码
│   │   ├── user.proto             # gRPC 协议文件
│   │   ├── user.go                # RPC 服务启动入口
│   │   └── Dockerfile
│   │
│   ├── product/                   # 【商品 RPC 服务】(目录结构同 user)
│   ├── stock/                     # 【库存 RPC 服务】(目录结构同 user)
│   └── order/                     # 【订单 RPC 服务】(目录结构同 user)
│
├── common/                        # 后端通用公共组件
│   ├── errorx/                    # 统一错误码与自定义 error
│   ├── tool/                      # 加密/JWT/格式化工具函数
│   └── xcode/                     # 业务状态码定义
│
├── web/                           # 【Vue 3 前端项目】
│   ├── src/
│   │   ├── api/                   # 接口请求模块 (按微服务划分子文件)
│   │   ├── assets/                # 静态资源 (图片、样式)
│   │   ├── components/            # 通用 UI 组件
│   │   ├── router/                # 页面路由
│   │   ├── store/                 # Pinia 状态管理 (Token、用户信息)
│   │   └── views/                 # 页面组件 (Login, Products, OrderList)
│   ├── nginx.conf                 # 前端容器使用的 Nginx 代理配置
│   ├── package.json
│   ├── vite.config.js             # Vite 配置文件 (配置开发阶段 proxy 跨域)
│   └── Dockerfile                 # 前端多阶段镜像构建文件
│
├── deploy/                        # 部署与运维资源
│   ├── docker-compose/            # 本地/测试环境依赖拉起 (MySQL, Redis)
│   │   └── docker-compose.yaml
│   └── sql/                       # 数据库初始化脚本
│       ├── user.sql
│       ├── product.sql
│       ├── stock.sql
│       └── order.sql
│
├── go.mod                         # 全局 Go 模块管理文件
├── go.sum
└── Jenkinsfile                    # CI/CD 自动化构建脚本
```

### 关键目录与文件设计说明：

1. **`apps/` 目录（微服务隔离）**
   - **`gateway`** 是唯一的 HTTP 入口，负责处理跨域、JWT Token 校验，并通过 gRPC 协议将请求转发给内部微服务。
   - **`user` / `product` / `stock` / `order`** 是独立的纯 gRPC 服务，不暴露 HTTP 端口，彼此通过 Protobuf 通信，高内聚低耦合。
2. **`internal/model/`（数据库层）**
   - 不要手动写 SQL，在各服务目录下使用命令 `goctl model mysql ddl -src deploy/sql/user.sql -dir internal/model -c`，由 go-zero 自动生成高性能且带防缓存击穿的 CRUD 操作代码。
3. **`web/`（前端与后端彻底解耦）**
   - Vue 3 代码完全独立，打包后通过根目录下的 `nginx.conf` 运行在独立的容器中。
4. **`Jenkinsfile`（流水线枢纽）**
   - 脚本可以监听 GitLab 提交。当检测到 `apps/user/` 下的代码有变化时，只构建并升级 `user` 容器；当检测到 `web/` 有修改时，只执行前端打包，大幅提升 CI/CD 执行效率。