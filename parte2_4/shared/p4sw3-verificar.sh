# Verifica que p4sw3 compilo y cargo las reglas de 2.4
# Se ejecuta en p4sw3
echo "===== Log del switch (ultimas lineas) ====="
tail -n 20 /var/log/simple_switch.log
echo "===== port_security ====="
simple_switch_CLI <<< "table_dump MyIngress.port_security"
