#!/bin/bash

# 开发环境容器启动脚本，如果没有 set -e，即使前面的命令失败，脚本也会继续执行，可能导致不可预期的结果。
set -e

# 配置默认值（开发环境优化）
CONTAINER_NAME=""
IMAGE_NAME=""
WORKDIR="/workspace"
HOST_PORT=""
CONTAINER_PORT=""
ENABLE_GPU=false

# 开发环境特定配置
DEVELOPMENT_FLAGS=(
    "--env" "NODE_ENV=development"
    "--env" "DEBUG=*"
    "--cap-add" "SYS_PTRACE"  # 用于调试
)

# 开发环境卷映射（代码热重载）
VOLUME_MAPPINGS=(
    "$(pwd):${WORKDIR}"
    "/media/disk/yao/workspace/models:${WORKDIR}/models"
    # "/var/run/docker.sock:/var/run/docker.sock"  # Docker in Docker支持
)

# 使用说明
usage() {
    echo "开发环境容器启动脚本"
    echo "用法: $0 [-n 容器名] [-i 镜像名] [-p 端口] [-d 工作目录] [-g]"
    echo "选项:"
    echo "  -n NAME    容器名称 (必需)"
    echo "  -i IMAGE   镜像名称 (必需)"
    echo "  -p PORT    端口映射 (格式: 主机端口:容器端口) (必需)"
    echo "  -d DIR     工作目录 (可选，默认: /workspace)"
    echo "  -g         启用GPU支持 (可选)"
    echo "示例:"
    echo "  $0 -n mydev -i node:18 -p 3000:3000"
    echo "  $0 -n mygpu -i pytorch/pytorch:latest -p 8080:8080 -g"
    exit 1
}


# 检查参数是否为空，如果为空则显示帮助信息
check_required_args() {
    if [[ -z "$CONTAINER_NAME" || -z "$IMAGE_NAME" || -z "$HOST_PORT" || -z "$CONTAINER_PORT" ]]; then
        echo "❌ 错误: 必须提供所有必需参数"
        echo ""
        usage
    fi
}

# 解析参数
while getopts "n:i:p:d:gh" opt; do
    case $opt in
        n) CONTAINER_NAME=$OPTARG ;;
        i) IMAGE_NAME=$OPTARG ;;
        p) 
            IFS=':' read -ra PORTS <<< "$OPTARG"
            HOST_PORT=${PORTS[0]}
            CONTAINER_PORT=${PORTS[1]}
            ;;
        d) WORKDIR=$OPTARG ;;
        g) ENABLE_GPU=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# 检查必需参数
check_required_args

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker守护进程未运行"
    exit 1
fi

# 构建启动命令
DOCKER_CMD="docker run -itd --rm \
    --name $CONTAINER_NAME \
    -w $WORKDIR \
    -p $HOST_PORT:$CONTAINER_PORT \
    ${DEVELOPMENT_FLAGS[@]}"

# 添加开发环境卷映射
for volume in "${VOLUME_MAPPINGS[@]}"; do
    DOCKER_CMD+=" -v $volume"
done

# 检查是否启用GPU支持
if [ "$ENABLE_GPU" = true ]; then
    # 检查NVIDIA Docker支持
    if docker info | grep -q "nvidia"; then
        DOCKER_CMD+=" --gpus all"
        echo "✅ 启用GPU支持 (NVIDIA Docker)"
    elif command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        # 检查是否有nvidia-docker2或nvidia-container-toolkit
        if docker info | grep -q "Runtimes.*nvidia"; then
            DOCKER_CMD+=" --runtime=nvidia"
            echo "✅ 启用GPU支持 (NVIDIA Runtime)"
        else
            echo "⚠️  检测到NVIDIA驱动但未配置Docker NVIDIA运行时"
            echo "💡 请安装 nvidia-docker2 或配置 nvidia-container-toolkit"
        fi
    else
        echo "⚠️  未检测到NVIDIA GPU或驱动，跳过GPU支持"
    fi
fi

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
    
    # 如果启用了GPU，显示GPU信息
    if [ "$ENABLE_GPU" = true ]; then
        echo -e "\n🖥️  GPU信息:"
        if command -v nvidia-smi &> /dev/null; then
            nvidia-smi
        else
            echo "⚠️  未安装 nvidia-smi，无法显示GPU信息"
        fi
    fi
else
    echo "❌ 容器启动失败!"
    exit 1
fi