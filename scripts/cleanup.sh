#!/bin/bash

# Añade un script cleanup.sh que elimina los archivos creados.
# Debe tomar cero o más de los siguientes argumentos: data, resources, output, logs.
# Si no se pasan argumentos, debe eliminar todo excepto ./data/urls.

# Si no se proporcionan argumentos, elimina todo excepto ./data/urls
if [ "$#" -eq 0 ]; then
    echo "Eliminar todos los archivos excepto ./data/urls"
    find data -type f ! -name "urls" -exec rm -f {} \;
    rm -rf res out log
else
    # Si se proporcionan argumentos, elimina solo los directorios indicados
    for arg in "$@"; do
        if [ "$arg" == "data" ]; then
            echo "Eliminando directorio: data (excepto ./data/urls)"
            find data -type f ! -name "urls" -exec rm -f {} \;
        elif [ "$arg" == "resources" ]; then
            echo "Eliminando directorio: resources"
            rm -rf res
        elif [ "$arg" == "output" ]; then
            echo "Eliminando directorio: output"
            rm -rf out
        elif [ "$arg" == "logs" ]; then
            echo "Eliminando directorio: logs"
            rm -rf log
        else
            echo "Argumento desconocido: $arg"
        fi
    done
fi
