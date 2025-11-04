FROM pytorch/pytorch:2.8.0-cuda12.8-cudnn9-runtime
WORKDIR /app
COPY . .
# 仅安装必要的编译工具（不换整个镜像）
RUN apt-get update && apt-get install -y \
    build-essential \     
    gcc \               
    g++ \                 
    make \              
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt
# EXPOSE 8080
# CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]