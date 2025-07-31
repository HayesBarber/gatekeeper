from fastapi import FastAPI
from app.controllers import api_router

app = FastAPI(title="Gate Keeper")
app.include_router(api_router)
