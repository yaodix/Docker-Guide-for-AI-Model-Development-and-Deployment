from vllm import LLM, SamplingParams
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

llm = None
sampling_params = SamplingParams(temperature=0.0, top_p=0.95, max_tokens=100, n =1)

@app.on_event("startup")
async def startup_event():
    print("Initializing LLM model...")
    global llm
    llm = LLM(
        model="./models/Qwen2.5-1.5B-Instruct",
        download_dir="./models/Qwen2.5-1.5B-Instruct",
        swap_space=2.0,
        gpu_memory_utilization=0.70,
        max_model_len=2048,
        max_num_seqs=8
    )
    print("LLM model initialized successfully.")

class PromptRequest(BaseModel):
    prompts: list[str]

@app.get("/")
async def root():
    return {"message": "model = Qwen/Qwen2.5-1.5B-Instruct"}

@app.post("/generate")
async def generateResponse(request: PromptRequest):
    outputs = llm.generate(request.prompts, sampling_params)
    response = []
    for output in outputs:
        prompt = output.prompt
        generated_text = output.outputs[0].text
        response.append({
            "prompt": prompt,
            "output": generated_text
        })
    return {"outputs": response}