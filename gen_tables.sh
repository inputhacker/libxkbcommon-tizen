#!/bin/sh

BASE_HEADER_FILE="./xkbcommon/xkbcommon-keysyms.h"

LC_CTYPE=C python ./makekeys.py ${BASE_HEADER_FILE} > ./src/ks_tables.h
