#!bin/bash

# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Uso: $0 <input_directory> <output_directory> <sample_id>"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
SAMPLE_ID="$3"

# Check if the input directory exists 
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: El directorio de entrada '$INPUT_DIR' no existe."
    exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Define output file
OUTPUT_FILE="$OUTPUT_DIR/${SAMPLE_ID}_merged.fastq.gz"

# Find and merge all FASTQ files matching the sample ID
cat "$INPUT_DIR"/"$SAMPLE_ID"*.fastq.gz > "$OUTPUT_FILE"

echo "Archivos fusionados guardados en: $OUTPUT_FILE"
