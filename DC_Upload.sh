#!/bin/bash

# 1. Configuration & Argument Parsing
#    Usage: ./upload.sh <filename> [server] [path]
DEFAULT_PASS="password"
DEFAULT_USER="admin"
DEFAULT_SERVER="gnss.local."

#DEFAULT_PASS="Tr.imble1!"
#DEFAULT_USER="support"
#DEFAULT_SERVER="gradecontrol.net"


FILE_PATH="$1"
SERVER="${2:-$DEFAULT_SERVER}"
PASS="${3:-$DEFAULT_PASS}"
USER="${4:-$DEFAULT_USER}"

if [ $SERVER == "gradecontrol.net" ]
then
    URI="/gnss/cgi-bin/dc_fileUpload.html"
    URI_APPLY="/gnss/cgi-bin/dcFileConfig.xml"
else
    URI="/cgi-bin/dc_fileUpload.html"
    URI_APPLY="/cgi-bin/dcFileConfig.xml"
fi

# 2. Validation
#    Check if a file was actually provided.
if [ -z "$FILE_PATH" ]; then
    echo "Error: No file specified."
    echo "Usage: $0 <filename> [server_address] [password] [user]"
    echo ""
    echo "The default user is $DEFAULT_USER with a password of $DEFAULT_PASS"
    echo "The default server is $DEFAULT_SERVER"
    exit 1
fi


if command -v sed >/dev/null 2>&1 && command -v grep >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
#    echo "Sed, grep and curl are installed."
    :
else
    echo "Required tools are missing. curl, send and grep are required"
    exit 1
fi

#    Check if the file exists on the local disk.
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File '$FILE_PATH' not found."
    exit 1
fi

# 3. Construct the URL
#    Defaulting to HTTP. Change to HTTPS if the server supports SSL.
FULL_URL="http://${SERVER}${URI}"
APPLY_URL="http://${SERVER}${URI_APPLY}"

echo "Uploading '$FILE_PATH' to ${SERVER}..."

# 4. Execute Curl
#    -F "file=@..." tells curl to POST a file as 'multipart/form-data'.
#    NOTE: 'file' is the form field name. If the HTML form expects a
#    different name (e.g., 'upload', 'data'), change "file=@$FILE_PATH"
#    to "your_field_name=@$FILE_PATH".
RESPONSE=$(curl -s -u "$USER:$PASS" -F "file=@$FILE_PATH" "$FULL_URL")

# 2. Parse the XML Response
# We look for the pattern <OK>VALUE</OK> and extract the VALUE.
# grep -o: Output only the matched part
# sed: Strip the tags to isolate the value
STATUS=$(echo "$RESPONSE" | grep -o "<OK>.*</OK>" | sed -e 's/<OK>//' -e 's/<\/OK>//')
# 3. Evaluate the Result

if [[ "$STATUS" == "1" ]]; then
    echo "Information: DC File Uploaded"
else
    echo "Failure: Receiver returned unexpected status."
    echo "Full Response: $RESPONSE"
    exit 1
fi


APPLY_RESPONSE=$(curl -s -u "$USER:$PASS" "$APPLY_URL")

APPLY_STATUS=$(echo "$APPLY_RESPONSE" | grep -o "<OK>.*</OK>" | sed -e 's/<OK>//' -e 's/<\/OK>//')
#4. Evaluate the Result

if [[ "$APPLY_STATUS" == "1" ]]; then
    echo "Success: Receiver Applied DC File"
else
    echo "Failure: Receiver failed to apply DC file. Returned unexpected status."
    echo "Full Response: $APPLY_RESPONSE"
    exit 1
fi

exit 0
