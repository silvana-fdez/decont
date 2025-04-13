#!/bin/bash

# Verifica si los archivos de salida existen
check_and_run() {
    output_file=$1
    shift
    command="$@"

    if [ -e "$output_file" ]; then
        echo "El archivo $output_file ya existe. Omitiendo el comando."
    else
        echo "Ejecutando: $command"
        eval "$command"
    fi
}

# Verifica si el script download.sh existe
if [ -e scripts/download.sh ]; then
    echo "El script download.sh existe, descargando el archivo de contaminantes."
else
    echo "Error: El script download.sh no existe. Asegúrate de que el archivo esté presente."
    exit 1
fi

# Descarga todos los archivos especificados en data/filenames
# for url in $(cat ./data/urls)
# do
#     bash scripts/download.sh $url data
# done


wget -q -P data -i ./data/urls &
PID=$!

echo -n "Descargando"
while kill -0 $PID 2>/dev/null; do
    echo -n "."
    sleep 1
done

echo -e "\nDescarga completa. \nComprobamos los códigos md5"

# Comprueba los códigos md5
for url in $(cat ./data/urls) 
do
  FILENAME=$(basename "$url")
  # Check if the downloaded file is correct comparing its md5 with the correct value
  if [ "$(md5sum data/"$FILENAME" | cut -d ' ' -f 1)" != "$(wget -qO- "$url".md5 | cut -d ' ' -f 1)" ]; then
	echo "Fichero "$FILENAME" es incorrecto. Comprueba la URL y trata de descargarlo de nuevo"
	exit 1
  else
	echo "El fichero "$FILENAME" se ha descragado correctamente"
  fi
done

# Descarga el archivo fasta de contaminantes, descomprímelo y filtra para remover todos los pequeños RNAs nucleares
check_and_run "res/contaminants.fasta.gz" bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes "small nuclear"

# Verifica si el script index.sh existe
if [ -e scripts/index.sh ]; then
    echo "El script index.sh existe, indexando el archivo de contaminantes."
else
    echo "Error: El script index.sh no existe. Asegúrate de que el archivo esté presente."
    exit 1
fi

# Indexa el archivo de contaminantes
echo "Indexando archivo de contaminantes..."
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx

check_and_run "res/contaminants_idx"

# Verifica si el script merge_fastqs.sh existe
if [ -e scripts/merge_fastqs.sh ]; then
    echo "El script merge_fastqs.sh existe, continuando con la fusión de archivos."
else
    echo "Error: El script merge_fastqs.sh no existe. Asegúrate de que el archivo esté presente."
    exit 1
fi

# Fusiona las muestras en un solo archivo
echo "Fusionando archivos FASTQ..."
ids="C57BL_6NJ SPRET_EiJ"
for sid in $ids
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# Ejecuta cutadapt para todos los archivos fusionados
echo "Eliminando adaptadores con cutadapt..."
mkdir -p out/trimmed log/cutadapt/

for file in out/merged/*_merged.fastq.gz; do
    sample=$(basename "$file" "_merged.fastq.gz")
    cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
        -o out/trimmed/${sample}_trimmed.fastq.gz "$file" > log/${sample}_cutadapt.log
done

check_and_run "out/trimmed/SPRET_EiJ_trimmed.fastq.gz"
check_and_run "out/trimmed/C57BL_6NJ_trimmed.fastq.gz"

# Ejecuta STAR para todos los archivos recortados
echo "Alineando lecturas a la base de datos de contaminantes..."
for fname in out/trimmed/*.fastq.gz
do
    # Obtiene el ID de la muestra del nombre del archivo
    sid=$(basename "$fname" "_trimmed.fastq.gz")
    # Crea un directorio para la salida de STAR
    mkdir -p out/star/$sid
    # Ejecuta STAR
    STAR --runThreadN 4 \
        --genomeDir res/contaminants_idx \
        --outReadsUnmapped Fastx \
        --readFilesIn "$fname" \
        --readFilesCommand gunzip -c \
        --outFileNamePrefix out/star/$sid/ \
        --outStd Log > Log.out 2>&1
    if [ $? -eq 0 ]; then
        echo "Alineación para $sid completada con éxito."
    else
        echo "Error durante la alineación para $sid."
    fi
done

check_and_run "out/star/SPRET_EiJ/"
check_and_run "out/star/C57BL_6NJ/"

# Crea un archivo de log que contenga información de los logs de cutadapt y STAR
echo "Creando el archivo de log final..."
LOGFILE="log/pipeline.log"
touch "$LOGFILE"  # Crea el archivo de log si no existe

# Añade un separador y una marca de tiempo al archivo de log
echo "=== Ejecución de Pipeline: $(date) ===" >> "$LOGFILE"

# Procesa los logs de cutadapt
echo "Procesando registros de cutadapt..."
for cutadapt_log in log/cutadapt/*_cutadapt.log; do
    sample=$(basename "$cutadapt_log" "_cutadapt.log")
    
    # Extrae información relevante de los logs de cutadapt
    echo "Muestra: $sample" >> "$LOGFILE"
    grep "Reads with adapters" "$cutadapt_log" >> "$LOGFILE"
    grep "Total basepairs" "$cutadapt_log" >> "$LOGFILE"
    echo "" >> "$LOGFILE"  # Añade una línea en blanco para legibilidad
done

# Procesa los logs de STAR
echo "Procesando registros de STAR..."
for star_log in out/star/*/Log.final.out; do
    sample=$(basename "$(dirname "$star_log")")

    # Extrae información relevante de los logs de STAR
    echo "Muestra: $sample" >> "$LOGFILE"
    grep "Uniquely mapped reads %" "$star_log" >> "$LOGFILE"
    grep "% of reads mapped to multiple loci" "$star_log" >> "$LOGFILE"
    grep "% of reads mapped to too many loci" "$star_log" >> "$LOGFILE"
    echo "" >> "$LOGFILE"  # Añade una línea en blanco para legibilidad
done

echo "Pipeline completada con éxito! Registro final guardado en: $LOGFILE"


