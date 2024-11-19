import os
from fastapi import APIRouter, File, UploadFile, Form, HTTPException
from ipfs.ipfs import add_file, download_file

router = APIRouter()

@router.post("/concerts")
async def create_concert(
    concert_name: str = Form(...),
    file: UploadFile = File(...)
    ):
    temp = f"temp/{file.filename}"
    # try:
    contents = await file.read()
    with open(temp, "wb") as f:
        f.write(contents)

    cid = await add_file(temp)
    await download_file(cid, 'pdf')
    try:
        await file.close()
    except Exception:
        raise HTTPException(status_code=500, detail='Error on closing the file')   
    finally:
        #temp.close()  # the `with` statement above takes care of closing the file
        os.remove(temp)  # Delete temp file
    
    return concert_name