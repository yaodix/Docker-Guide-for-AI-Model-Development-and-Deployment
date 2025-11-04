# vllm_in_docker

## Overview

**vllm_in_docker** provides a fast and easy way to deploy [vLLM](https://github.com/vllm-project/vllm) models such as `Qwen2.5-1.5B-Instruct` inside a Docker container with a REST API powered by FastAPI. This setup allows you to run local inference with GPU acceleration and interact with the model using HTTP endpoints.

## Features

- Dockerized vLLM + FastAPI inference server
- GPU acceleration via NVIDIA Container Toolkit
- REST API for prompt generation
- Supports model volume mounting for easy model swapping

## Prerequisites

Ensure the following are installed before using this project:

- [Docker](https://docs.docker.com/get-docker/)
- NVIDIA GPU + [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

## Getting Started

### 1. Clone the repository

```sh
git clone https://github.com/wpan36/vllm_in_docker.git
cd vllm_in_docker
```

### 2. Place your model files

Download `Qwen2.5-1.5B-Instruct` or any vLLM-compatible model into a local ./models directory. For example:

```sh
├──server.py
├──models/
   └── Qwen2.5-1.5B-Instruct/
       ├── config.json
       ├── model.safetensors
       └── ...
```

Make sure the model path matches what’s specified in `server.py`

### 3. Build the Docker image

```sh
docker build -t vllm_server .
```

### 4. Run the Docker container

```sh
docker run -it --gpus all \
    -v $(pwd)/models:/app/models \
    -p 8080:8080 \
    --name vllm-api \
    vllm_server
```

## Usage

### API Endpoints

- **GET**Health check endpoint

  ```sh
  curl http://localhost:8080/
  ```

  **Response:**

  ```json
  {
    "message": "model = Qwen/Qwen2.5-1.5B-Instruct"
  }
  ```
- **Post**
  Generate completions from input prompts

  **Request body:**

  ```json
  {
    "prompts": [
      "1 + 1 equals:",
      "The capital of Japan is"
    ]
  }
  ```

  **Response:**

  ```json
  {
    "outputs": [
      {
        "prompt": "1 + 1 equals:",
        "output": "2"
      },
      {
        "prompt": "The capital of Japan is",
        "output": "Tokyo"
      }
    ]
  }
  ```

## Customization

**Change Model:** Replace contents in ./models/Qwen2.5-1.5B-Instruct with another model compatible with [vLLM](https://github.com/vllm-project/vllm).

**Modify Inference Parameters:** Edit `sampling_params` in `server.py` to adjust temperature, top_p, max_tokens, etc.

**Expose More Routes:** Extend `server.py` with more API endpoints as needed.

## Troubleshooting

**Model fails to load:** Make sure your model is correctly downloaded and all necessary files are in the `./models` directory.

**CUDA not found:** Ensure you're running the container with `--gpus all` and that the NVIDIA drivers + Container Toolkit are installed.

## Credits

[vLLM](https://github.com/vllm-project/vllm): An open-source fast LLM inference engine.
