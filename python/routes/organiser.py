import os
from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from ipfs.ipfs import add_file
from web3 import Web3
from datetime import datetime
from pydantic import BaseModel
import json
import dotenv

dotenv.load_dotenv()

w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7545'))
concert_address = os.getenv("CONCERT_CONTRACT_ADDRESS")
concert_abi = os.getenv("CONCERT_ABI")
contract_instance = w3.eth.contract(address=concert_address, abi=concert_abi)
router = APIRouter()

class Concert(BaseModel):
    concert_name: str
    artist_address: str
    venue_address: str
    artist_payout_percentage: int
    organiser_payout_percentage: int
    venue_payout_percentage: int
    total_tickets: int
    pre_sale_quality: int
    pre_sale_ticket_price: int
    general_sale_ticket_price: int
    concert_description: str
    concert_start_datetime_str: str
    pre_sale_start_datetime_str: str
    pre_sale_end_datetime_str: str
    general_sale_start_datetime_str: str
    organiser_address: str
    organiser_private_key: str

@router.post("/concerts")
async def create_concert(concert: Concert):  
    concert_name = concert.concert_name
    artist_address = concert.artist_address
    venue_address = concert.venue_address
    artist_payout_percentage = concert.artist_payout_percentage
    organiser_payout_percentage = concert.organiser_payout_percentage
    venue_payout_percentage = concert.venue_payout_percentage
    total_tickets = concert.total_tickets
    pre_sale_quality = concert.pre_sale_quality
    pre_sale_ticket_price = concert.pre_sale_ticket_price
    general_sale_ticket_price = concert.general_sale_ticket_price
    concert_description = concert.concert_description
    concert_start_datetime_str = concert.concert_start_datetime_str
    pre_sale_start_datetime_str = concert.pre_sale_start_datetime_str
    pre_sale_end_datetime_str = concert.pre_sale_end_datetime_str
    general_sale_start_datetime_str = concert.general_sale_start_datetime_str
	
	# Convert DateTime Str into Date Time
    try:
        concert_start_datetime = datetime.strptime(concert_start_datetime_str, '%Y-%m-%d %H:%M:%S') 
        pre_sale_start_datetime = datetime.strptime(pre_sale_start_datetime_str, '%Y-%m-%d %H:%M:%S') if pre_sale_start_datetime_str else None
        pre_sale_end_datetime = datetime.strptime(pre_sale_end_datetime_str, '%Y-%m-%d %H:%M:%S') if pre_sale_end_datetime_str else None
        general_sale_start_datetime = datetime.strptime(general_sale_start_datetime_str, '%Y-%m-%d %H:%M:%S')
    except ValueError:
        raise HTTPException(status_code=400, detail='Invalid Date Time Format')
    
	# Check Ticket Quantity
    if total_tickets <= 0:
        raise HTTPException(status_code=400, detail='Total tickets must be greater than 0')
    if pre_sale_quality > total_tickets:
        raise HTTPException(status_code=400, detail='Pre-sale quantity must be less than total tickets')
    # Check Ticket Price
    if pre_sale_ticket_price < 0:
        raise HTTPException(status_code=400, detail='Pre-sale ticket price must be greater than 0')
    if general_sale_ticket_price < 0:
        raise HTTPException(status_code=400, detail='General sale ticket price must be greater than 0')
    # Check Date Time
    if pre_sale_start_datetime and pre_sale_end_datetime and pre_sale_start_datetime > pre_sale_end_datetime:
        raise HTTPException(status_code=400, detail='Pre-sale start date must be before pre-sale end date')
    if not general_sale_start_datetime:
        raise HTTPException(status_code=400, detail='General sale start date is required')
    if not concert_start_datetime:
        raise HTTPException(status_code=400, detail='Concert start date is required')
    if pre_sale_end_datetime and general_sale_start_datetime and pre_sale_end_datetime > general_sale_start_datetime:
        raise HTTPException(status_code=400, detail='Pre-sale end date must be before general sale start date')
    if pre_sale_end_datetime and pre_sale_start_datetime < datetime.now():
        raise HTTPException(status_code=400, detail='Pre-sale start date must be in the future')
    if general_sale_start_datetime < datetime.now():
        raise HTTPException(status_code=400, detail='General sale start date must be in the future')
    if concert_start_datetime < datetime.now():
        raise HTTPException(status_code=400, detail='Concert start date must be in the future')

	# Turn Ticket information into a dictionary for Storing in IPFS
    ticket_info = {
        "concert_name": concert_name,
        "concert_description": concert_description,
        "concert_start_datetime": concert_start_datetime_str,
        "pre_sale_start_datetime": pre_sale_start_datetime_str,
        "pre_sale_end_datetime": pre_sale_end_datetime_str,
        "general_sale_start_datetime": general_sale_start_datetime_str,
	}

	# Save Ticket Information to File
    file_path = f"temp/ticket_info_{concert_name}.json"
    with open(file_path, 'w') as f:
        json.dump(ticket_info, f)

    cid = await add_file(file_path)
    # await download_file(cid, 'pdf')
	# Build the transaction
    # artist_address = "0xE366fA5e44d940c68C801D6f7C16D61D8739b05b"
    # venue_address = "0x1A9586ED2A9A43b3abddF04613F29ED9C54D8cFB"
    # artist_payout_percentage = 40
    # organiser_payout_percentage = 40
    # venue_payout_percentage = 10
    # total_tickets = 100
    # pre_sale_quality = 0
    ticket_info_cid = cid
    ticket_info_uri = f"ipfs://{ticket_info_cid}"	
    # pre_sale_ticket_price = 0
    # general_sale_ticket_price = 100
    

    concert_id = contract_instance.functions.getListingID().call()

    transaction = contract_instance.functions.createConcert(
        artist_address,
        venue_address,
        artist_payout_percentage,
        organiser_payout_percentage,
        venue_payout_percentage,
        total_tickets,
        pre_sale_quality,
        ticket_info_uri,
        pre_sale_ticket_price,
        general_sale_ticket_price
        ).build_transaction({
        'from': concert.organiser_address,
        'nonce': w3.eth.get_transaction_count(concert.organiser_address),
        'gas': 2000000,
        'gasPrice': w3.to_wei('10', 'gwei')
    })
    
    
    # # Sign the transaction
    signed_txn = w3.eth.account.sign_transaction(transaction, private_key=concert.organiser_private_key)
    # # Send the transaction
    tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
    # # Wait for the transaction to be mined, and get the transaction receipt
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Transaction receipt mined: {dict(tx_receipt)}")
 
    return {
        "concert_id": concert_id,
		"cid": cid
	}
  