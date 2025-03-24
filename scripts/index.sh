# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).
# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

# Assign arguments to variables
FASTA=$1
INDEX_DIR=$2

# Check if the genome file exists
if [ ! -f "$FASTA" ]; then
	echo "Error: El fichero del genoma $FASTA no existe."
	exit 1
fi

# Check if the output directory exists, and create it if it doesn't
if [ ! -d "$INDEX_DIR" ]; then
        echo "Creando directorio: $INDEX_DIR."
        mkdir -p "$INDEX_DIR"
fi

# Run STAR to index the genome
echo "Indexing genome file: $FASTA"
STAR --runThreadN 4 \
	--runMode genomeGenerate \
	--genomeDir "$INDEX_DIR" \
	--genomeFastaFiles "$FASTA" \
	--genomeSAindexNbases 9

# Check if the indexing was successful
if [ $? -eq 0 ]; then
	echo "Indexado completado. Indexado guardado en: $INDEX_DIR"
else
	echo "Error: indexado del genoma ha fallado."
	exit 1
fi
