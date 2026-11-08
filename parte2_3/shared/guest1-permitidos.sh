# Trafico que la politica debe PERMITIR desde INVITADOS
# Se ejecuta en pc_guest1
echo "===== Ping al gateway 10.19.2.1 ====="
ping -c 3 10.19.2.1 2>&1 | tee /shared/2_3-ok-ping-gateway.txt
echo "===== HTTP a srv1 (puerto 80) ====="
curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.34 2>&1 | tee /shared/2_3-ok-http.txt
echo "===== HTTPS a srv1 (puerto 443) ====="
curl -sk -o /dev/null -w "%{http_code}\n" https://203.0.113.34 2>&1 | tee /shared/2_3-ok-https.txt
