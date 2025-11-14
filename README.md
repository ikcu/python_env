# Python Docker 开发与部署模板

[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/) [![Docker](https://img.shields.io/badge/Docker-Compose-blue)](https://docs.docker.com/compose/)

一个模块化、可复用的 Python Docker 模板，覆盖从开发到生产的完整流程：
- `base`：最小化基础镜像（系统工具 + 基础 Python 依赖）
- `runtime`：开发镜像（安装业务依赖，支持本地 `src` 挂载）
- `app`：生产示例镜像（复制代码并运行）
- 使用 `Makefile` 统一构建、运行、镜像保存与加载

目录
- [特性](#特性)
- [目录结构](#目录结构)
- [快速开始（开发）](#快速开始开发)
- [生产示例](#生产示例)
- [镜像管理](#镜像管理离线分发)
- [依赖与源配置](#依赖与源配置)
- [端口与网络](#端口与网络)
- [Make 命令一览](#make-命令一览)
- [故障排查](#故障排查)
- [自定义与扩展](#自定义与扩展)

特性
- 多阶段镜像，分离基础、开发与生产职责
- 本地代码挂载，开发体验流畅
- 统一的 `make` 命令，降低心智负担
- 支持镜像保存/加载，方便离线分发

参考实现文件：
- 基础镜像：`docker/docker_base/base.Dockerfile`
- 开发镜像：`docker/docker_runtime/runtime.Dockerfile`
- 生产镜像：`docker/docker_app/app.Dockerfile`
- 开发 Compose：`docker-compose_runtime.yaml`
- 生产 Compose：`docker-compose.yaml`
- 统一命令：`Makefile`


## 目录结构
```
python_env/
├── README.md
├── Makefile					# makefile管理文件
├── make.sh						# make管理脚本，提供帮助
├── docker-compose_runtime.yaml	# 开发环境compose文件
├── docker-compose.yaml			# 生产环境compose文件，打包python文件
├── docker/						# docker images
│   ├── docker_base/			# python base
│   │   ├── base.Dockerfile
│   │   └── requirements/
│   │       └── base.txt
│   ├── docker_runtime/			# 开发
│   │   └── runtime.Dockerfile
│   ├── docker_app/				# 生产
│   │   └── app.Dockerfile
│   └── images/
│       └── fel-python-base.tar  # 已打包的python基础镜像包,github单文件大小限制,已删除
└── src/                         # python源文件及requirements
    ├── requirements.txt
    └── app.py
```

说明
- `docker/docker_base/base.Dockerfile`：基础镜像（系统工具、pip 源、基础依赖）
- `docker/docker_runtime/runtime.Dockerfile`：开发镜像（安装 `src/requirements.txt`）
- `docker/docker_app/app.Dockerfile`：生产镜像（复制 `src/`，`CMD python3 app.py`）
- `docker-compose_runtime.yaml`：开发编排（挂载 `./src:/app`，端口 `8000:8000`）
- `docker-compose.yaml`：生产编排（端口 `8000:8000`）
- `Makefile`：统一管理构建/运行/保存/加载


## 快速开始（开发）
- 安装前置：已安装 `Docker`、`Docker Compose`、`make`
- 构建基础与开发镜像：
  - `make build-base`
  - `make build-runtime`
- 以 Compose 启动开发环境：
  - `make up-runtime`
  - 查看日志：`make logs-runtime`
- 挂载代码：`docker-compose_runtime.yaml` 将本地 `./src` 挂载到容器 `/app`
- 启动命令：容器使用 `python3 app.py`。请在 `src/` 下提供 `app.py`。

示例 `src/app.py`（Flask，在 8000 端口运行）：
```python
from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def hello():
    return {"message": "Hello from Modular Docker Python Environment!"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
```


## 生产示例
- 构建生产镜像：`make build-app`（基于 `runtime`，复制 `src/` 并设置 `CMD`，参见 `docker/docker_app/app.Dockerfile`）
- 直接运行容器：`make run`（映射 `8000:8000`，参见 `Makefile`）
- 使用 Compose：`docker compose -f docker-compose_app.yaml up -d`

```yaml
services:
  app:
    image: my-app:latest
    build:
      context: .
      dockerfile: docker/docker_app/app.Dockerfile
    ports:
      - "8000:8000"
```


## 镜像管理（离线/分发）
- 保存基础镜像：`make save-base`（输出 `docker/images/fel-python-base.tar`）
- 加载基础镜像：`make load-base`
- 保存开发镜像：`make save-runtime` / 加载：`make load-runtime`
- 保存生产镜像：`make save-app` / 加载：`make load-app`

示例：将镜像传至另一台机器
- 保存：`make save-runtime && make save-app`
- 传输：`scp docker/images/*.tar user@remote:/path/to/images/`
- 加载：在远端执行 `make load-runtime && make load-app`


## 依赖与源配置
- 基础依赖：`docker/docker_base/requirements/base.txt`
- 业务依赖：`src/requirements.txt`
- PyPI 源：`base` 镜像设置清华镜像（`docker/docker_base/base.Dockerfile:9`）。如需恢复官方源：删除或修改该行。
- 更新依赖：修改 `src/requirements.txt` 后，重新构建 `runtime/app` 镜像以使依赖生效（`make build-runtime` / `make build-app`）。


## 端口与网络
- 开发环境：宿主 `8000` → 容器 `8000`。将应用监听端口设为 8000。
- 生产 Compose：宿主 `8000` → 容器 `8000`。建议在 `app.py` 使用 `port=8000`。
- 自定义网络：`development` 桥接网络。

跨容器通信（开发）：
- 同一网络下服务可通过服务名访问，比如在新增 `redis` 服务后，应用内可用 `redis:6379` 连接。


## Make 命令一览
- 构建镜像：`make base-build` / `make runtime-build` / `make app-build`
- 保存/加载：`make base-load` / `make runtime-save` / `make runtime-load`
- 运行生产示例：`make app-run`
- 开发编排：`make runtime-up` / `make runtime-down` / `make runtime-logs`
- 生产编排：`make app-up` / `make app-down` / `make app-logs` 。

附：常用自定义命令（示例）
- 构建并启动开发：`make base-build runtime-build runtime-up`
- 更新依赖并重启：修改 `src/requirements.txt` 后 `make runtime-build` / `make app-build`  
- 运行生产：`make app-build app-run`
## 故障排查
- 端口不一致：若容器未响应，检查应用监听端口是否为 `8000`，以及 `EXPOSE` 与端口映射是否一致。
- 缺少入口：开发与生产均执行 `python3 app.py`，请确保 `src/app.py` 存在且可运行。
- 国内源设置：如不需要清华 `pip` 源，加以移除或替换（见 `docker/docker_base/base.Dockerfile`）。

## 自定义与扩展
- 增加系统包：在 `docker/docker_base/base.Dockerfile` 的 `apt-get install` 中追加。
- 增加 Python 依赖：编辑 `src/requirements.txt` 并重建 `runtime/app`。
- 环境变量：在 compose 中添加 `environment:` 或在 Dockerfile 中使用 `ENV`。
- 多服务开发：在 `docker-compose_runtime.yaml` 增加服务并加入 `development` 网络。
