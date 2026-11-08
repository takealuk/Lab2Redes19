# Caso correcto: pc_guest1 usa su MAC autorizada (02:00:00:00:00:0c)
# Se ejecuta en pc_guest1
echo "===== MAC actual de eth0 ====="
ip link show eth0 2>&1 | tee /shared/2_4-correcto.txt
echo "===== Ping al gateway 10.19.2.1 ====="
ping -c 3 -W 1 10.19.2.1 2>&1 | tee -a /shared/2_4-correcto.txt
