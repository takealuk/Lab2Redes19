# Detiene las capturas de p4sw3 y muestra los archivos generados
# Se ejecuta en p4sw3
pkill -INT tcpdump
sleep 1
ls -l /shared/2_3-*.pcap
