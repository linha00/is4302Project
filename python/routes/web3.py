import json
from web3 import Web3
from fastapi import APIRouter

router = APIRouter()

w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7545'))

@router.get("/web3/health")
def test_connection():
    return w3.is_connected()

