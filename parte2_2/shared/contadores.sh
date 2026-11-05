# Muestra los contadores ingress_port y egress_port de todos los puertos del switch
# Se ejecuta dentro de un switch P4
# Uso: bash /shared/contadores.sh <cantidad de puertos>
for p in $(seq 1 "${1:-5}"); do
  echo "counter_read MyIngress.ingress_port $p"
  echo "counter_read MyEgress.egress_port $p"
done | simple_switch_CLI | grep -E "ingress_port|egress_port"
