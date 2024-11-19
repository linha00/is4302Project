import aioipfs
import os

async def add_file(file_path):
    client = aioipfs.AsyncIPFS(maddr='/ip4/127.0.0.1/tcp/5001')
    async for added_file in client.add(file_path):
        print('Imported file {0}, CID: {1}'.format(
            added_file['Name'], added_file['Hash']))
    await client.close()
    return added_file['Hash']

async def download_file(cid, filetype):
    client = aioipfs.AsyncIPFS(maddr='/ip4/127.0.0.1/tcp/5001')
    await client.get(cid, dstdir='downloads/')
    os.rename(f'downloads/{cid}', f'downloads/{cid}.{filetype}')
    # Rename File
    await client.close()

