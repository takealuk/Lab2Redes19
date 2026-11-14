Obligatorio 2 - 2026 - Redes de Computadoras - Grupo 19

USO GENERAL
Cada carpeta parteX es un laboratorio Kathara independiente (salvo parte1_3,
que solo contiene resultados). Se ejecuta desde su propia carpeta:

    cd parteX
    kathara lstart        # levanta el escenario
    kathara lclean        # lo detiene y borra (hacerlo antes de levantar otro)

- Para aplicar cambios en archivos de un lab activo: kathara lrestart
- La carpeta shared/ de cada lab se monta en /shared dentro de los equipos.
  Alli estan las capturas .pcap, las salidas de las pruebas y los scripts.

PARTE 1 

1.1  parte1_1/   (rutas estaticas, NAT de A y B, servidor publico de B)
    cd parte1_1 && kathara lstart
    Pruebas:
      kathara exec pcb1  -- ping -c 4 8.8.8.8        # LAN B a Internet (NAT)
      kathara exec pca1  -- ping -c 4 8.8.8.8        # LAN A a Internet (NAT)
      kathara exec pcint -- ping -c 4 203.0.113.10   # srvB alcanzable desde pcint
    Capturas de NAT: shared/nat-a.pcap (en rcla) y shared/nat-b.pcap (en rclb).

1.2  parte1_2/   (OSPF en el backbone)
    cd parte1_2 && kathara lstart
    Verificacion:
      kathara exec r1 -- vtysh -c "show ip ospf neighbor"
      kathara exec r1 -- vtysh -c "show ip ospf database"
      kathara exec r1 -- ip route
      kathara exec pca1 -- traceroute -I -n 203.0.113.10
      kathara exec pca1 -- traceroute -I -n 8.8.8.8
    Evidencias en parte1_2/shared/.

1.3  parte1_3/   (convergencia; NO es un laboratorio)
    Usa el escenario de parte1_2. Cada carpeta repeticionN contiene el ping
    con marcas de tiempo de r1 a r4 (10.255.0.41), la hora de la falla, las
    tablas de r1 antes y despues y las capturas de los enlaces r1-r2 y r4-r5.
    Procedimiento resumido (con parte1_2 levantado y OSPF estable):
      1. Iniciar capturas en los enlaces r1-r2 y r4-r5 (tcpdump -w /shared/...).
      2. En r1: ping -D -i 0.01 -c 800 10.255.0.41 > /shared/ping-r1-a-r4.txt
      3. Durante el ping, en r2: date +%s.%N > /shared/hora-falla.txt
         y dar de baja el enlace r2-r4:  ip link set eth2 down
      4. Detener las capturas: kathara exec <equipo> -- pkill -INT -x tcpdump

1.4  parte1_4/   (expansion con r7, r8 y LAN C 203.0.113.16/29)
    cd parte1_4 && kathara lstart
    Pruebas:
      kathara exec r7 -- vtysh -c "show ip ospf neighbor"
      kathara exec r8 -- vtysh -c "show ip ospf neighbor"
      kathara exec pcint -- ping -c 4 203.0.113.18   # pcc1 desde Internet
      kathara exec pca1  -- ping -c 4 203.0.113.18
    Evidencias en parte1_4/shared/.

1.5  parte1_5/   (ingenieria de caminos con costos OSPF)
    cd parte1_5 && kathara lstart
    Pruebas:
      kathara exec r1 -- vtysh -c "show ip route 10.255.0.48/30"
      kathara exec r1 -- traceroute -n 10.255.0.49
      kathara exec r6 -- traceroute -n 10.255.0.18
    Evidencias (camino principal, respaldo y falla) en parte1_5/shared/.


PARTE 2 - SWITCHES P4 (red del cliente A)
-----------------------------------------
En todos los escenarios de la Parte 2 y en parte3, el .startup de cada switch
compila switch.p4, inicia BMv2 (simple_switch) y carga commands.txt. No hay
que hacerlo a mano. Puertos P4: 1 = eth0 (hacia rcla), 2 = eth1, 3 = eth2, ...
Para revisar un switch:
    kathara exec p4sw1 -- cat /var/log/simple_switch.log
    kathara exec p4sw1 -- bash /shared/contadores.sh 5

2.1  parte2/    (numeracion de las cuatro redes; switches con esqueleto P4)
    cd parte2 && kathara lstart
    El esqueleto no reenvia tramas: este lab sirve para ver la topologia y la
    numeracion (lab.conf y .startup).

     parte2_1/  (escenario auxiliar para la captura ARP/Ethernet)
    cd parte2_1 && kathara lstart
    pc_admin1 y pc_admin2 comparten directamente el dominio ARP_TEST.
      En pc_admin1:  ip neigh flush dev eth0
                     tcpdump -i eth0 -w /shared/arp-admin.pcap
      En pc_admin2:  ping -c 4 10.19.0.2
    Captura guardada: parte2_1/shared/arp-admin.pcap

2.2  parte2_2/   (reenvio Ethernet en P4)
    cd parte2_2 && kathara lstart
    Pruebas:
      kathara exec pc_admin1 -- ping -c 4 10.19.0.1    # gateway (rcla)
      kathara exec pc_admin1 -- ping -c 4 10.19.0.3    # otro host de ADMIN
      kathara exec p4sw1 -- bash /shared/contadores.sh 5
    Evidencias: shared/contadores-*.txt y shared/reflexion-admin4.pcap

2.3  parte2_3/   (politica de acceso de INVITADOS)
    cd parte2_3 && kathara lstart
    Orden de las pruebas (scripts en /shared):
      En p4sw3:      bash /shared/p4sw3-verificar.sh
                     bash /shared/p4sw3-capturas-iniciar.sh
                     bash /shared/p4sw3-contadores.sh 0-inicio
      En pc_guest1:  bash /shared/guest1-permitidos.sh
      En p4sw3:      bash /shared/p4sw3-contadores.sh 1-tras-permitidos
      En pc_guest1:  bash /shared/guest1-bloqueados.sh
      En p4sw3:      bash /shared/p4sw3-contadores.sh 2-tras-bloqueados
      En pc_admin1:  bash /shared/admin1-control.sh
                     bash /shared/admin1-stateless.sh
      En p4sw3:      bash /shared/p4sw3-contadores.sh 3-final
                     bash /shared/p4sw3-capturas-detener.sh

2.4  parte2_4/   (politica de 2.3 + port security)
    cd parte2_4 && kathara lstart
    Orden de las pruebas (scripts en /shared):
      En p4sw3:      bash /shared/p4sw3-verificar.sh
                     bash /shared/p4sw3-capturas-iniciar.sh
                     bash /shared/p4sw3-contadores.sh 0-inicio
      En pc_guest1:  bash /shared/guest1-ps-correcto.sh
      En p4sw3:      bash /shared/p4sw3-contadores.sh 1-tras-correcto
      En pc_guest1:  bash /shared/guest1-ps-suplantar-admin1.sh
      En p4sw3:      bash /shared/p4sw3-contadores.sh 2-tras-suplantar-admin1
      En pc_guest1:  bash /shared/guest1-ps-suplantar-guest2.sh
      En p4sw3:      bash /shared/p4sw3-contadores.sh 3-tras-suplantar-guest2
                     bash /shared/p4sw3-capturas-detener.sh


PARTE 3 - INTEGRACION
---------------------
parte3/   (ISP con OSPF + red de A con switches P4 + clientes B y C)
    cd parte3 && kathara lstart
    Esperar la convergencia de OSPF (unos 40 s). Pruebas principales:
      kathara exec pc_admin1 -- ping -c 4 8.8.8.8          # A a Internet (NAT)
      kathara exec pc_dev1   -- ping -c 4 8.8.8.8
      kathara exec pcb1      -- ping -c 4 8.8.8.8          # B a Internet (NAT)
      kathara exec pcint     -- ping -c 4 203.0.113.34     # srv1 desde Internet
      kathara exec pcint     -- curl -s http://203.0.113.26/   # srvB desde Internet
      kathara exec pc_guest1 -- ping -c 4 10.19.0.2        # debe fallar (politica)
      kathara exec rcla -- iptables -t nat -L POSTROUTING -n -v
    Salidas guardadas en parte3/shared/integracion-*.txt
