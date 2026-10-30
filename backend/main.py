
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="LexIndia-AI API")

# Allow requests from local development origins (Flutter web runs on localhost/127.0.0.1)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from section_routes import router as section_router

app.include_router(section_router)

@app.get("/")
def home():
    return {
        "message": "LexIndia-AI backend is running",
        "status": "success"
    }
