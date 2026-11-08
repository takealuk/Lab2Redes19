# Verifica que p4sw3 compilo y cargo las reglas de 2.3
# Se ejecuta en p4sw3
echo "===== Log del switch (ultimas lineas) ====="
tail -n 20 /var/log/simple_switch.log
echo "===== restricted_ports ====="
simple_switch_CLI <<< "table_dump MyIngress.restricted_ports"
echo "===== acl ====="
simple_switch_CLI <<< "table_dump MyIngress.acl"
