# Muestra los contadores por puerto y los de la política (ACL) del switch
# Se ejecuta dentro de un switch P4
# Uso: bash /shared/contadores.sh <cantidad de puertos>
{
  for p in $(seq 1 "${1:-5}"); do
    echo "counter_read MyIngress.ingress_port $p"
    echo "counter_read MyEgress.egress_port $p"
  done
  echo "counter_read MyIngress.acl_allowed 0"
  echo "counter_read MyIngress.acl_denied 0"
  echo "counter_read MyIngress.ps_violations 0"
} | simple_switch_CLI | grep -E "ingress_port|egress_port|acl_|ps_"
