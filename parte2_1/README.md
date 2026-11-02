# Escenario auxiliar de 2.1: ARP y Ethernet

Copia de `parte2/` con una modificación de conexiones: `pc_admin1` y
`pc_admin2` comparten directamente el dominio `ARP_TEST` en `lab.conf`.
Conservan las IPs `10.19.0.2/26` y `10.19.0.3/26`.
No se modificaron los programas P4 ni los startups originales.

El objetivo es capturar solicitud y respuesta ARP y el tráfico ICMP posterior
antes de implementar el forwarding P4. No verifica el funcionamiento de los
switches ni reproduce sus segmentos individuales de la topología original.
El conteo de dominios de la entrega se realiza sobre `parte2/lab.conf`.

## Procedimiento usado para la captura guardada

Se levantó el escenario completo con `kathara lstart`. En la terminal de
pc_admin1 se ejecutaron:

```bash
ip neigh flush dev eth0
tcpdump -i eth0 -w /shared/arp-admin.pcap
```

En la terminal de pc_admin2, una vez iniciada la captura:

```bash
ping -c 4 10.19.0.2
```

Se detuvo tcpdump al finalizar. `shared/arp-admin.pcap` fue revisado:
12 tramas, solicitud ARP broadcast de pc_admin2 y respuesta de pc_admin1,
cuatro pings con sus respuestas y un intercambio ARP unicast posterior.
El README de la raíz contiene direcciones, MAC y análisis por trama.

## Alternativa para repetir una prueba con solo dos dispositivos

Esta alternativa no es el procedimiento de la captura guardada.
Detener primero cualquier escenario anterior desde su propia carpeta con
`kathara lclean`. Desde `parte2_1/`, levantar solo las dos PCs:

```powershell
kathara lstart --noterminals pc_admin1 pc_admin2
```

En una consola PowerShell, desde esta carpeta:

```powershell
kathara exec pc_admin1 -- ip neigh flush dev eth0
kathara exec pc_admin1 -- tcpdump -ni eth0 -w /shared/arp-admin.pcap "arp or icmp"
```

Cuando tcpdump indique que está escuchando, ejecutar en otra consola, también
desde `parte2_1/`:

```powershell
kathara exec pc_admin1 -- ping -c 4 10.19.0.3
kathara exec pc_admin1 -- pkill -INT -x tcpdump
```

La limpieza de vecinos fuerza una nueva resolución ARP. La captura queda en
`parte2_1/shared/arp-admin.pcap`; revisar sus resultados antes de afirmar que
la prueba fue exitosa. La ruta por defecto no interviene en este ping local.
