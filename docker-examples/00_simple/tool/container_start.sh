#!/bin/bash

# 开发环境容器启动脚本，如果没有 set -e，即使前面的命令失败，脚本也会继续执行，可能导致不可预期的结果。
set -e

# 配置默认值（开发环境优化）
CONTAINER_NAME="dev_container"
IMAGE_NAME="simple_demo_py312:latest"
WORKDIR="/workspace"
HOST_PORT=3000
CONTAINER_PORT=3000

# 开发环境特定配置
DEVELOPMENT_FLAGS=(
    "--env" "NODE_ENV=development"
    "--env" "DEBUG=*"
    "--cap-add" "SYS_PTRACE"  # 用于调试
)

# 开发环境卷映射（代码热重载）
VOLUME_MAPPINGS=(
    "$(pwd):${WORKDIR}"
    # "/var/run/docker.sock:/var/run/docker.sock"  # Docker in Docker支持
)

# 使用说明
usage() {
    echo "开发环境容器启动脚本"
    echo "用法: $0 [-n 容器名] [-i 镜像名] [-p 端口] [-d 工作目录]"
    echo "示例:"
    echo "  $0 -n mydev -i node:18 -p 3000:3000"
    exit 1
}

# 解析参数
while getopts "n:i:p:d:h" opt; do
    case $opt in
        n) CONTAINER_NAME=$OPTARG ;;
        i) IMAGE_NAME=$OPTARG ;;
        p) 
            IFS=':' read -ra PORTS <<< "$OPTARG"
            HOST_PORT=${PORTS[0]}
            CONTAINER_PORT=${PORTS[1]}
            ;;
        d) WORKDIR=$OPTARG ;;
        h) usage ;;
        *) usage ;;
    esac
done

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker守护进程未运行"
    exit 1
fi

# 构建启动命令
    # -p $HOST_PORT:$CONTAINER_PORT \
DOCKER_CMD="docker run -itd --rm \
    --name $CONTAINER_NAME \
    -w $WORKDIR \
    ${DEVELOPMENT_FLAGS[@]}"

# 添加开发环境卷映射
for volume in "${VOLUME_MAPPINGS[@]}"; do
    DOCKER_CMD+=" -v $volume"
done

# 开发环境特定配置
DOCKER_CMD+=" --security-opt seccomp=unconfined"  # 调试支持
DOCKER_CMD+=" $IMAGE_NAME"

echo "🚀 启动开发容器..."
echo "命令: $DOCKER_CMD"
eval $DOCKER_CMD

if [ $? -eq 0 ]; then
    echo "✅ 开发容器 $CONTAINER_NAME 启动成功!"
    echo "📊 容器状态:"
    docker ps --filter "name=$CONTAINER_NAME"
    
    echo -e "\n🔧 可用操作:"
    echo "  ./container_into.sh     # 进入容器"
    echo "  docker logs $CONTAINER_NAME  # 查看日志"
    echo "  docker stop $CONTAINER_NAME  # 停止容器"
else
    echo "❌ 容器启动失败!"
    exit 1
fi