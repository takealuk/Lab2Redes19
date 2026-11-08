# Inicia las capturas en p4sw3: entrada desde pc_guest1 (eth1) y salida hacia rcla (eth0)
# Se ejecuta en p4sw3
nohup tcpdump -ni eth1 -w /shared/2_3-entrada-guest1.pcap > /dev/null 2>&1 &
nohup tcpdump -ni eth0 -w /shared/2_3-salida-rcla.pcap > /dev/null 2>&1 &
sleep 1
echo "Capturas en curso:"
pgrep -a tcpdump
