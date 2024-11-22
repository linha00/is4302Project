import json
from web3 import Web3
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from dotenv import load_dotenv
import os
from PIL import Image

from ipfs.ipfs import add_file

load_dotenv()
router = APIRouter()

w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:7545'))
concert_address = os.getenv("CONCERT_CONTRACT_ADDRESS")
concert_abi = os.getenv("CONCERT_ABI")
collectible_address = os.getenv("COLLECTIBLE_CONTRACT_ADDRESS")
collectible_abi = os.getenv("COLLECTIBLE_ABI")
concert_contract_instance = w3.eth.contract(address=concert_address, abi=concert_abi)
collectible_contract_instance = w3.eth.contract(address=collectible_address, abi=collectible_abi)
@router.post("/collectibles")
async def create_collectible(
    artist_address: str = Form(...),
    artist_private_key: str = Form(...),
    nft_name: str = Form(...),
    nft_description: str = Form(...),
    file: UploadFile = File(...)
):
    #Check if Caller is a Artist
    isArtist = concert_contract_instance.functions.checkArtistAddressApproval(artist_address).call()
    if not isArtist:
       raise HTTPException(status_code=400, detail="Caller is not a Artist")
    # Safe Image to File
    file_path = f"temp/{file.filename}"

    # Save the uploaded file
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())

    # Upload Image to IPFS
    image_cid = await add_file(file_path)
    image_uri = f"ipfs://{image_cid}"

    # Create Metadata JSON for NFT
    metadata = {
        "name": nft_name,
        "description": nft_description,
        "image": image_uri
    }

    # Save Metadata to File
    metadata_path = f"temp/{file.filename}.json"
    with open(metadata_path, "w") as buffer:
        json.dump(metadata, buffer)

    # Upload Metadata to IPFS
    metadata_cid = await add_file(metadata_path)
    metadata_uri = f"ipfs://{metadata_cid}"
    is_composable = False

    token_id = collectible_contract_instance.functions.getLatestTokenId().call()

    # Mint NFT
    transaction = collectible_contract_instance.functions.mint(artist_address, metadata_uri, artist_address, is_composable).build_transaction({
        'from': artist_address,
        'nonce': w3.eth.get_transaction_count(artist_address),
        'gas': 2000000,
        'gasPrice': w3.to_wei('10', 'gwei')
    }); 

    # # Sign the transaction
    signed_txn = w3.eth.account.sign_transaction(transaction, private_key=artist_private_key)
    # # Send the transaction
    tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
    # # Wait for the transaction to be mined, and get the transaction receipt
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Transaction receipt mined: {dict(tx_receipt)}")


    # Delete The File
    # os.remove(file_path)
    # os.remove(metadata_path)

    return {
        "message": "Collectible Created",
        "token_id": token_id
    }

@router.post("/collectibles/composable")
async def create_collectible(
    artist_address: str = Form(...),
    artist_private_key: str = Form(...),
    nft_name: str = Form(...),
    nft_description: str = Form(...),
    file: UploadFile = File(...)
):
    #Check if Caller is a Artist
    isArtist = concert_contract_instance.functions.checkArtistAddressApproval(artist_address).call()
    if not isArtist:
       raise HTTPException(status_code=400, detail="Caller is not a Artist")
    # Safe Image to File
    file_path = f"temp/{file.filename}"

    # Save the uploaded file
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())

    # Split Image into 4 Parts
    image = Image.open(file_path)
    width, height = image.size
    half_width = width // 2
    half_height = height // 2

    top_left = image.crop((0, 0, half_width, half_height))
    top_right = image.crop((half_width, 0, width, half_height))
    bottom_left = image.crop((0, half_height, half_width, height))
    bottom_right = image.crop((half_width, half_height, width, height))

    split_image_paths = []
    split_image_paths.append(f"temp/{file.filename}_top_left.png")
    split_image_paths.append(f"temp/{file.filename}_top_right.png")
    split_image_paths.append(f"temp/{file.filename}_bottom_left.png")
    split_image_paths.append(f"temp/{file.filename}_bottom_right.png")

    top_left.save(split_image_paths[0])
    top_right.save(split_image_paths[1])
    bottom_left.save(split_image_paths[2])
    bottom_right.save(split_image_paths[3])

    token_ids = []

    for image_path in split_image_paths:
         # Upload Image to IPFS
        image_cid = await add_file(image_path)
        image_uri = f"ipfs://{image_cid}"

        # Create Metadata JSON for NFT
        metadata = {
            "name": nft_name,
            "description": nft_description,
            "image": image_uri
        }

        # Save Metadata to File
        metadata_path = f"temp/{file.filename}.json"
        with open(metadata_path, "w") as buffer:
            json.dump(metadata, buffer)

        # Upload Metadata to IPFS
        metadata_cid = await add_file(metadata_path)
        metadata_uri = f"ipfs://{metadata_cid}"
        is_composable = True

        token_id = collectible_contract_instance.functions.getLatestTokenId().call()
        token_ids.append(token_id)

        # Mint NFT
        transaction = collectible_contract_instance.functions.mint(artist_address, metadata_uri, artist_address, is_composable).build_transaction({
            'from': artist_address,
            'nonce': w3.eth.get_transaction_count(artist_address),
            'gas': 2000000,
            'gasPrice': w3.to_wei('10', 'gwei')
        }); 

        # # Sign the transaction
        signed_txn = w3.eth.account.sign_transaction(transaction, private_key=artist_private_key)
        # # Send the transaction
        tx_hash = w3.eth.send_raw_transaction(signed_txn.raw_transaction)
        # # Wait for the transaction to be mined, and get the transaction receipt
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print(f"Transaction receipt mined: {dict(tx_receipt)}")


    # Delete The File
    # os.remove(file_path)
    # os.remove(metadata_path)
    # for image_path in split_image_paths:
    #     os.remove(image_path)

    return {
        "message": "Collectible Created",
        "tokenIDs": token_ids
    }
