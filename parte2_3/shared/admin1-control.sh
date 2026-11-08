# Control: ADMIN no esta restringido y debe funcionar normalmente
# Se ejecuta en pc_admin1
echo "===== Ping a srv1 ====="
ping -c 3 203.0.113.34 2>&1 | tee /shared/2_3-control-admin-ping-srv1.txt
echo "===== HTTP a srv1 ====="
curl -s -o /dev/null -w "%{http_code}\n" http://203.0.113.34 2>&1 | tee /shared/2_3-control-admin-http.txt
