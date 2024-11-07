# ----------------------------------------------------------------------
# Copyright (c) 2024 Rafael Gonzalez.
#
# See the LICENSE file for details
# ----------------------------------------------------------------------

# --------------------
# System wide imports
# -------------------

import sys
import csv
import logging
import asyncio
import time
from typing import Annotated
from io import StringIO 

# -------------------
# Third party imports
# -------------------

import uvicorn
from fastapi import FastAPI, Body, Request
from lica.cli import configure_logging, arg_parser


from . import __version__

# get the module logger
log = logging.getLogger(__name__.split('.')[-1])

app = FastAPI()





@app.get("/")
async def index() -> dict:
    log.info("Requesiting the index endpoint")
    return {"message": "Hello Wortld!"}

@app.post("/upload")
async def get_tas_file(tas_data: Annotated[str, Body()]) -> dict:
    log.info("Parsing the TAS file")
    log.info(tas_data)
    with StringIO(tas_data) as csvfile:
        reader = csv.reader(csvfile, delimiter="\t")
        for i, line in enumerate(reader):
            #log.info("%d %s", i, line)
            pass
    return {"result": "Ok", "readings": 0}



def main() -> None:
    parser = arg_parser(name="mapatas", version=__version__, description="TAS Maps Web Service")
    args = parser.parse_args(sys.argv[1:])
    configure_logging(args)
    log.info("Starting the UVICORN Server")
    uvicorn.run(app, host="0.0.0.0", port=8000)
