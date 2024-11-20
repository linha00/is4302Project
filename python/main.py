from typing import Union

from fastapi import FastAPI

from routes.organiser import router as organiser_router
from routes.web3 import router as web3_router
from routes.artist import router as artist_router

app = FastAPI()

app.include_router(organiser_router)
app.include_router(web3_router)
app.include_router(artist_router)
