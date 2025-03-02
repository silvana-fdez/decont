#!/bin/bash

# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

# Check if the required arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <url_to_download> <output_directory> [uncompress_yes_no] [filter_word]"
    exit 1
fi

# Assign arguments to variables
FILE_URL=$1
OUTPUT_DIR=$2
UNCOMPRESS=$3
FILTER_WORD=$4
# Extract the filename from the URL
FILENAME=$(basename "$FILE_URL")

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Download the file (overwrite if exists)
echo "Downloading $FILENAME"
wget -O "$OUTPUT_DIR"/"$FILENAME" "$FILE_URL"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download the file. Please check the URLs and try again."
    exit 1
fi


# Optionally uncompress the file
if [ "$UNCOMPRESS" = "yes" ]; then
    echo "Uncompressing downloaded files..."
    gunzip -f "$OUTPUT_DIR"/"$FILENAME"
fi

# Optionally filter the sequence
if [ -n "$FILTER_WORD" ]
then
  echo "Filtering the sequence $FILTER_WORD in file ${FILENAME%.gz}"

  # /$FILTER_WORD/ → finds the line with the word small nuclear.
  # { :loop; N; /.*>.*>/!bloop; s/>.*>/>/; }
  #    :loop → Marks a jump point (loop).
  #    N → Adds the next line to the buffer.
  #    /^>[^>]+>/!bloop → Searches for characters different from `>`. If not found, it returns to the loop, adding another line and keeps looking rec>
  #    s/>.*>/>/ → Once we have the entire block, we replace the content between the two > symbols with a single >.
  sed -r "/$FILTER_WORD/ { :loop; N; /^>[^>]+>/!bloop; s/>.*>/>/; }" "$OUTPUT_DIR"/"${FILENAME%.gz}" > "$OUTPUT_DIR"/"Filtered_${FILENAME%.gz}"
fi

