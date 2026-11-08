# Lee los contadores de p4sw3 y los guarda con una etiqueta
# Se ejecuta en p4sw3
# Uso: bash /shared/p4sw3-contadores.sh <etiqueta>
bash /shared/contadores.sh 4 | tee "/shared/contadores-$1.txt"
