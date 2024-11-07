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
from io import StringIO 

# -------------------
# Third party imports
# -------------------

import uvicorn
from fastapi import FastAPI, File, UploadFile
from lica.cli import configure_logging, arg_parser


from . import __version__

# get the module logger
log = logging.getLogger(__name__.split('.')[-1])

app = FastAPI()


@app.get("/")
async def index() -> dict:
    log.info("Requesting the index endpoint")
    return {"message": "Hello World!"}

# The argiument name 'readings' must be coincident with the 
# imput form field name used in curl
@app.post("/upload")
async def get_tas_file(readings: UploadFile = File(...)) -> dict:
    log.info("Parsing the TAS file")
    contents = await readings.read()
    with StringIO(contents.decode(encoding="ascii")) as csvfile:
        # Reads the tabbed CSV file and skip the firs line
        lines = [line for line in csv.reader(csvfile, delimiter="\t")][1:]
    return {"result": "Ok", "readings": len(lines), "first": lines[0], "last": lines[-1]}



def main() -> None:
    parser = arg_parser(name="mapatas", version=__version__, description="TAS Maps Web Service")
    args = parser.parse_args(sys.argv[1:])
    configure_logging(args)
    log.info("Starting the UVICORN Server")
    uvicorn.run(app, host="0.0.0.0", port=8000)
