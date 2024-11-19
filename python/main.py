from typing import Union

from fastapi import FastAPI

from routes.concert import router as concert_router

app = FastAPI()

app.include_router(concert_router)