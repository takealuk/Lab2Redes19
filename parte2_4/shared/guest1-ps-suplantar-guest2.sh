# Suplantacion: pc_guest1 usa la MAC de pc_guest2 (02:00:00:00:00:0d), autorizada en el mismo switch pero en el puerto 3
# Al final restaura la MAC original (02:00:00:00:00:0c)
# Se ejecuta en pc_guest1
F=/shared/2_4-suplantacion-guest2.txt
ip link set dev eth0 down
ip link set dev eth0 address 02:00:00:00:00:0d
ip link set dev eth0 up
ip route add default via 10.19.2.1
ip neigh flush dev eth0
echo "===== MAC falsificada en eth0 =====" | tee $F
ip link show eth0 2>&1 | tee -a $F
echo "===== Ping al gateway 10.19.2.1 con MAC falsificada =====" | tee -a $F
ping -c 3 -W 1 10.19.2.1 2>&1 | tee -a $F
ip link set dev eth0 down
ip link set dev eth0 address 02:00:00:00:00:0c
ip link set dev eth0 up
ip route add default via 10.19.2.1
ip neigh flush dev eth0
echo "===== MAC restaurada: ping al gateway =====" | tee -a $F
ping -c 2 -W 1 10.19.2.1 2>&1 | tee -a $F
