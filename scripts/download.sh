#!/bin/bash

# Este script debe descargar el archivo especificado en el primer argumento ($1),
# colocarlo en el directorio especificado en el segundo argumento ($2),
# y *opcionalmente*:
# - descomprimir el archivo descargado con gunzip si el tercer
#   argumento ($3) contiene la palabra "yes"
# - filtrar las secuencias basadas en una palabra contenida en sus líneas de encabezado:
#   las secuencias que contengan la palabra especificada en su encabezado deben ser **excluidas**
#
# Ejemplo del filtrado deseado:
#
#   > esta es mi secuencia
#   CACTATGGGAGGACATTATAC
#   > esta es mi segunda secuencia
#   CACTATGGGAGGGAGAGGAGA
#   > esta es otra secuencia
#   CCAGGATTTACAGACTTTAAA
#
#   Si $4 == "otra" solo las **primeras dos secuencias** deben ser incluidas

# Verifica si se proporcionan los argumentos requeridos
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 <url_de_descarga> <directorio_de_salida> [descomprimir_si_no] [palabra_de_filtro]"
    exit 1
fi

# Asigna argumentos a variables
FILE_URL=$1
OUTPUT_DIR=$2
UNCOMPRESS=$3
FILTER_WORD=$4
# Extrae el nombre del archivo de la URL
FILENAME=$(basename "$FILE_URL")

# Función para verificar si un archivo o directorio existe
check_existence() {
    if [ -e "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Función para verificar permiso de escritura
check_write_permission() {
    if [ -w "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Crea el directorio de salida si no existe
if ! check_existence "$OUTPUT_DIR"; then
    mkdir -p "$OUTPUT_DIR"
fi

# Verifica permiso de escritura para el directorio de salida
if ! check_write_permission "$OUTPUT_DIR"; then
    echo "No hay permiso de escritura para el directorio de salida $OUTPUT_DIR."
    exit 1
fi

# Descarga el archivo (sobrescribe si existe)
echo "Descargando $FILENAME"
wget -O "$OUTPUT_DIR"/"$FILENAME" "$FILE_URL"

# Verifica si la descarga fue exitosa
if [ $? -ne 0 ]; then
    echo "Falló la descarga del archivo. Por favor, verifica las URLs y vuelve a intentarlo."
    exit 1
fi

# Opcionalmente descomprime el archivo
echo "NOMBRE DE ARCHIVO:$FILENAME"

if [ "$UNCOMPRESS" = "yes" ]; then
    echo "Descomprimiendo archivos descargados..."
    gunzip -c "$OUTPUT_DIR"/"$FILENAME" > "$OUTPUT_DIR"/"${FILENAME%.gz}"
    # Asegúrate de que el archivo .gz original no se elimine
    if [ $? -ne 0 ]; then
        echo "Falló la descompresión del archivo."
        exit 1
    fi
fi

# Opcionalmente filtra la secuencia
if [ -n "$FILTER_WORD" ]; then
    echo "Filtrando la secuencia $FILTER_WORD en el archivo ${FILENAME%.gz}"

    # /$FILTER_WORD/ → encuentra la línea con la palabra small nuclear.
    # { :loop; N; /.*>.*>/!bloop; s/>.*>/>/; }
    #    :loop → Marca un punto de salto (loop).
    #    N → Agrega la siguiente línea al búfer.
    #    /^>[^>]+>/!bloop → Busca caracteres diferentes de `>`. Si no se encuentran, vuelve al bucle, agregando otra línea y sigue buscando recursivamente.
    #    s/>.*>/>/ → Una vez que tenemos todo el bloque, reemplazamos el contenido entre los dos símbolos > con un solo >.
    sed -r "/$FILTER_WORD/ { :loop; N; /^>[^>]+>/!bloop; s/>.*>/>/; }" "$OUTPUT_DIR"/"${FILENAME%.gz}" > "$OUTPUT_DIR"/"Filtered_${FILENAME%.gz}"
fi
