#!/bin/bash

# 开发环境容器进入脚本
set -e

DEFAULT_CONTAINER="dev_container"

# 检查是否通过命令行参数提供了容器名称
if [ $# -eq 0 ]; then
    # 如果没有提供参数，提示用户输入容器名称
    echo "请输入容器名称（直接回车使用默认名称 '$DEFAULT_CONTAINER'）:"
    read -r CONTAINER_NAME
    # 如果用户没有输入任何内容，使用默认名称
    if [ -z "$CONTAINER_NAME" ]; then
        CONTAINER_NAME=$DEFAULT_CONTAINER
    fi
else
    # 使用命令行参数提供的容器名称
    CONTAINER_NAME=$1
fi

# 检查容器状态
if ! docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ 错误: 容器 $CONTAINER_NAME 未运行或不存在"
    echo "运行中的容器:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    exit 1
fi

echo "🔍 容器信息:"
docker ps --filter "name=$CONTAINER_NAME"

echo -e "\n🚀 进入开发容器 $CONTAINER_NAME ..."
echo "💡 提示: 使用 'exit' 退出容器，容器将继续运行"

# 尝试不同的shell
if docker exec -it $CONTAINER_NAME bash -c "echo 'bash可用'" > /dev/null 2>&1; then
    echo "📟 使用 bash..."
    docker exec -it \
        --env "HOSTNAME=${CONTAINER_NAME}" \
        ${CONTAINER_NAME} bash
elif docker exec -it $CONTAINER_NAME sh -c "echo 'sh可用'" > /dev/null 2>&1; then
    echo "📟 使用 sh..."
    docker exec -it $CONTAINER_NAME sh
else
    echo "❌ 错误: 容器中未找到可用的shell"
    echo "尝试直接执行命令:"
    docker exec -it $CONTAINER_NAME /bin/sh -c "ls -la /bin/*sh; echo '可用的shell列表:'"
fi