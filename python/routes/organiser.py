import os
from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from ipfs.ipfs import add_file, download_file
from web3 import Web3
from datetime import datetime
from pydantic import BaseModel
import json

w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7545'))
address = '0x0a8deB491721a8E3F40E0dD0022E88CbdA1a88A3'
account = "0x2591AD15995184aB954D4374F8e0884b231406fD"
private_key = "0xf3c8755eddfb6d3972abfe4789ef41fbb74302372aba23d1444dab53eaf933d7"
abi= """[
	{
		"constant": true,
		"inputs": [],
		"name": "supporterContract",
		"outputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "_concertID",
				"type": "uint256"
			}
		],
		"name": "getListing",
		"outputs": [
			{
				"components": [
					{
						"name": "artist",
						"type": "address"
					},
					{
						"name": "venue",
						"type": "address"
					},
					{
						"name": "organiser",
						"type": "address"
					},
					{
						"name": "artistPayoutPercentage",
						"type": "uint256"
					},
					{
						"name": "organiserPayoutPercentage",
						"type": "uint256"
					},
					{
						"name": "venuePayoutPercentage",
						"type": "uint256"
					},
					{
						"name": "totalTickets",
						"type": "uint256"
					},
					{
						"name": "ticketInfoURI",
						"type": "string"
					},
					{
						"name": "preSaleQuantity",
						"type": "uint256"
					},
					{
						"name": "preSaleTicketPrice",
						"type": "uint256"
					},
					{
						"name": "generalSaleTicketPrice",
						"type": "uint256"
					},
					{
						"name": "concertState",
						"type": "uint256"
					}
				],
				"name": "",
				"type": "tuple"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_concertID",
				"type": "uint256"
			}
		],
		"name": "artistApproveConcert",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "defaultTicketPlatformFeePercentage",
		"outputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"name": "Listings",
		"outputs": [
			{
				"name": "artist",
				"type": "address"
			},
			{
				"name": "venue",
				"type": "address"
			},
			{
				"name": "organiser",
				"type": "address"
			},
			{
				"name": "artistPayoutPercentage",
				"type": "uint256"
			},
			{
				"name": "organiserPayoutPercentage",
				"type": "uint256"
			},
			{
				"name": "venuePayoutPercentage",
				"type": "uint256"
			},
			{
				"name": "totalTickets",
				"type": "uint256"
			},
			{
				"name": "ticketInfoURI",
				"type": "string"
			},
			{
				"name": "preSaleQuantity",
				"type": "uint256"
			},
			{
				"name": "preSaleTicketPrice",
				"type": "uint256"
			},
			{
				"name": "generalSaleTicketPrice",
				"type": "uint256"
			},
			{
				"name": "concertState",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"name": "organisersApproval",
		"outputs": [
			{
				"name": "",
				"type": "bool"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"name": "venuesApproval",
		"outputs": [
			{
				"name": "",
				"type": "bool"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "venue",
				"type": "address"
			}
		],
		"name": "checkVenueAddressApproval",
		"outputs": [
			{
				"name": "",
				"type": "bool"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "ticketContract",
		"outputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_artist",
				"type": "address"
			}
		],
		"name": "approveArtist",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_artist",
				"type": "address"
			},
			{
				"name": "_venue",
				"type": "address"
			},
			{
				"name": "_artistPayoutPercentage",
				"type": "uint256"
			},
			{
				"name": "_organiserPayoutPercentage",
				"type": "uint256"
			},
			{
				"name": "_venuePayoutPercentage",
				"type": "uint256"
			},
			{
				"name": "_totalTickets",
				"type": "uint256"
			},
			{
				"name": "_preSaleQuality",
				"type": "uint256"
			},
			{
				"name": "_ticketInfoURI",
				"type": "string"
			},
			{
				"name": "_preSaleTicketPrice",
				"type": "uint256"
			},
			{
				"name": "_generalSaleTicketPrice",
				"type": "uint256"
			}
		],
		"name": "createConcert",
		"outputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "artist",
				"type": "address"
			}
		],
		"name": "checkArtistAddressApproval",
		"outputs": [
			{
				"name": "",
				"type": "bool"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_venue",
				"type": "address"
			}
		],
		"name": "approveVenue",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "defaultConcertPlatformPayoutPercentage",
		"outputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "",
				"type": "address"
			}
		],
		"name": "artistsApproval",
		"outputs": [
			{
				"name": "",
				"type": "bool"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_organiser",
				"type": "address"
			}
		],
		"name": "approveOrganiser",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": false,
		"inputs": [
			{
				"name": "_concertID",
				"type": "uint256"
			}
		],
		"name": "venueApproveConcert",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"name": "ticketsSold",
		"outputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "getListings",
		"outputs": [
			{
				"components": [
					{
						"name": "artist",
						"type": "address"
					},
					{
						"name": "venue",
						"type": "address"
					},
					{
						"name": "organiser",
						"type": "address"
					},
					{
						"name": "artistPayoutPercentage",
						"type": "uint256"
					},
					{
						"name": "organiserPayoutPercentage",
						"type": "uint256"
					},
					{
						"name": "venuePayoutPercentage",
						"type": "uint256"
					},
					{
						"name": "totalTickets",
						"type": "uint256"
					},
					{
						"name": "ticketInfoURI",
						"type": "string"
					},
					{
						"name": "preSaleQuantity",
						"type": "uint256"
					},
					{
						"name": "preSaleTicketPrice",
						"type": "uint256"
					},
					{
						"name": "generalSaleTicketPrice",
						"type": "uint256"
					},
					{
						"name": "concertState",
						"type": "uint256"
					}
				],
				"name": "",
				"type": "tuple[]"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "organiser",
				"type": "address"
			}
		],
		"name": "checkOrganiserAddressApproval",
		"outputs": [
			{
				"name": "",
				"type": "bool"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{
				"name": "_ticketAddress",
				"type": "address"
			},
			{
				"name": "_supporterAddress",
				"type": "address"
			}
		],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "concertID",
				"type": "uint256"
			},
			{
				"indexed": true,
				"name": "concertState",
				"type": "uint256"
			}
		],
		"name": "ConcertStatus",
		"type": "event"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": true,
				"name": "concertID",
				"type": "uint256"
			},
			{
				"indexed": true,
				"name": "supporterNFTID",
				"type": "uint256"
			},
			{
				"indexed": true,
				"name": "ticketID",
				"type": "uint256"
			}
		],
		"name": "TicketPurchase",
		"type": "event"
	}
]"""
contract_instance = w3.eth.contract(address=address, abi=abi)
router = APIRouter()
concert_id = 1

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
    # pre_sale_ticket_price = 0
    # general_sale_ticket_price = 100
    
    transaction = contract_instance.functions.createConcert(
        artist_address,
        venue_address,
        artist_payout_percentage,
        organiser_payout_percentage,
        venue_payout_percentage,
        total_tickets,
        pre_sale_quality,
        ticket_info_cid,
        pre_sale_ticket_price,
        general_sale_ticket_price
        ).build_transaction({
        'from': account,
        'nonce': w3.eth.get_transaction_count(account),
        'gas': 2000000,
        'gasPrice': w3.to_wei('10', 'gwei')
    })
    
    
    # # Sign the transaction
    signed_txn = w3.eth.account.sign_transaction(transaction, private_key=private_key)
    # # Send the transaction
    tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
    # # Wait for the transaction to be mined, and get the transaction receipt
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Transaction receipt mined: {dict(tx_receipt)}")
    global concert_id
    concert_id += 1
    return {
        "concert_id": concert_id-1,
		"cid": cid
	}
  