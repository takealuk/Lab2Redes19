# Trafico que la politica debe BLOQUEAR desde INVITADOS
# Se ejecuta en pc_guest1
echo "===== Ping a srv1 (ICMP, no permitido) ====="
ping -c 3 -W 1 203.0.113.34 2>&1 | tee /shared/2_3-bloq-ping-srv1.txt
echo "===== Ping a pc_admin1 (otra red) ====="
ping -c 3 -W 1 10.19.0.2 2>&1 | tee /shared/2_3-bloq-ping-admin.txt
echo "===== Ping a pc_guest2 (otro invitado) ====="
ping -c 3 -W 1 10.19.2.3 2>&1 | tee /shared/2_3-bloq-ping-guest2.txt
echo "===== TCP a srv1 puerto 8080 (puerto no permitido) ====="
curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://203.0.113.34:8080 2>&1 | tee /shared/2_3-bloq-srv1-8080.txt
