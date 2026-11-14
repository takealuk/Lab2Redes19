Obligatorio 2 - 2026 - Redes de Computadoras - Grupo 19

USO GENERAL
Cada carpeta parteX es un laboratorio Kathara independiente. Se ejecuta desde su propia carpeta:

    cd parteX
    kathara lstart        
    kathara lclean        

La carpeta shared/ de cada lab se monta en /shared dentro de los equipos.
Alli estan las capturas .pcap, las salidas de las pruebas y los scripts.

PARTE 1 

1.1  parte1_1/   (rutas estaticas, NAT de A y B, servidor publico de B)
    cd parte1_1 && kathara lstart
    Pruebas:
      kathara exec pcb1  -- ping -c 4 8.8.8.8        # LAN B a Internet (NAT)
      kathara exec pca1  -- ping -c 4 8.8.8.8        # LAN A a Internet (NAT)
      kathara exec pcint -- ping -c 4 203.0.113.10   # srvB alcanzable desde pcint
    Capturas de NAT: shared/nat-a.pcap (en rcla) y shared/nat-b.pcap (en rclb).
    Captura de srvB alcanzable desde pcint: shared/srvb-desde-pcint.pcap (en srvb).

1.2  parte1_2/  
    cd parte1_2 && kathara lstart
    Pruebas:
      Vecinos OSPF de r1: r1-show-ip-ospf-neighbor.txt
        kathara exec r1 -- vtysh -c "show ip ospf neighbor"

      LSDB y tablas de forwarding de r1 y r5: r1-r5-lsdb-forwarding.txt
        kathara exec r1 -- vtysh -c "show ip ospf database"
        kathara exec r5 -- vtysh -c "show ip ospf database"
        kathara exec r1 -- ip route
        kathara exec r5 -- ip route

      Caminos de A hacia B y hacia Internet: caminos-a-b-a-internet.txt
        kathara exec r3 -- vtysh -c "show ip route 203.0.113.10"
        kathara exec r3 -- vtysh -c "show ip route 0.0.0.0/0"
        kathara exec pca1 -- traceroute -I -n 203.0.113.10
        kathara exec pca1 -- traceroute -I -n 8.8.8.8

    Captura del arranque OSPF: ospf-arranque-r1-r2.pcap
      Se agrega temporalmente en r1.startup, antes de "systemctl start frr":
        tcpdump -ni eth1 -U -w /shared/ospf-arranque-r1-r2.pcap 'ip proto 89' 
      Se levanta el lab, se espera 40 s y se detiene con:
        kathara exec r1 -- pkill -INT -x tcpdump
      Luego se quita esa linea de r1.startup para no sobrescribir la captura.

1.3  parte1_3/   (misma configuracion que parte1_2)
    cd parte1_3 && kathara lstart

    Cada carpeta repeticionN contiene el ping con marcas de tiempo de r1 a
    r4 (10.255.0.41), la hora de la falla, las tablas de r1 antes y despues
    y las capturas de los enlaces r1-r2 y r4-r5.

    Procedimiento
      1. Iniciar capturas en los enlaces r1-r2 y r4-r5 (tcpdump -w /shared/...).
      2. En r1: ping -D -i 0.01 -c 800 10.255.0.41 > /shared/ping-r1-a-r4.txt
      3. Durante el ping, en r2: date +%s.%N > /shared/hora-falla.txt
         y dar de baja el enlace r2-r4:  ip link set eth2 down
      4. Detener las capturas

1.4  parte1_4/  
    cd parte1_4 && kathara lstart
    Pruebas:
      kathara exec r7 -- vtysh -c "show ip ospf neighbor"
      kathara exec r8 -- vtysh -c "show ip ospf neighbor"
      kathara exec pcint -- ping -c 4 203.0.113.18   # rclc (IP publica de C)
      kathara exec pcc1  -- ping -c 4 8.8.8.8        # LAN C a Internet (NAT)
    Evidencias en parte1_4/shared/.

1.5  parte1_5/   
    cd parte1_5 && kathara lstart
    Con OSPF estabilizado. Los comandos se ejecutan en la terminal de cada
    router (la que abre kathara lstart); las salidas quedan en /shared.

    1. Camino principal (sin fallas):
      En r1:
        vtysh -c "show ip route 10.255.0.48/30" > /shared/r1-ruta-a-r6-principal.txt
        traceroute -n 10.255.0.49 > /shared/r1-traceroute-a-r6-principal.txt
      En r6:
        vtysh -c "show ip route 10.255.0.16/30" > /shared/r6-ruta-a-r1-principal.txt
        traceroute -n 10.255.0.18 > /shared/r6-traceroute-a-r1-principal.txt

    2. Falla del camino principal (enlace r2-r4):
      En r1 (ping a r6 cada 10 ms):
        ping -D -i 0.01 10.255.0.49 > /shared/falla-r1-ping.txt
      En r2, durante el ping (registra la hora y corta el enlace r2-r4):
        date +%s.%N > /shared/falla-hora.txt; ip link set eth2 down
      En r1: cortar el ping con Ctrl+C.

    3. Camino de respaldo (con el enlace r2-r4 todavia caido):
      En r1:
        vtysh -c "show ip route 10.255.0.48/30" > /shared/r1-ruta-a-r6-respaldo.txt
        traceroute -n 10.255.0.49 > /shared/r1-traceroute-a-r6-respaldo.txt
      En r6:
        vtysh -c "show ip route 10.255.0.16/30" > /shared/r6-ruta-a-r1-respaldo.txt
        traceroute -n 10.255.0.18 > /shared/r6-traceroute-a-r1-respaldo.txt


PARTE 2 

2.1  parte2/   
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
    Los comandos se ejecutan en la terminal de cada equipo (la que abre kathara lstart); las salidas quedan en /shared.
    pc_admin4 (10.19.0.5, MAC 02:00:00:00:00:08) es el host agregado sin
    modificar el switch: su MAC no esta en p4sw1/commands.txt.

    1. Conectividad entre los 3 hosts originales de ADMIN:
      En pc_admin1:
        ping -c 4 10.19.0.1   # gateway (rcla)
        ping -c 4 10.19.0.3   # pc_admin2
        ping -c 4 10.19.0.4   # pc_admin3

    2. Captura en el host nuevo (reflexion 2.2):
      En pc_admin4:
        tcpdump -i eth0 -w /shared/reflexion-admin4.pcap
      En pc_admin1:
        ping -c 3 10.19.0.5  # falla: 100% de perdida
      En pc_admin4: detener tcpdump con Ctrl+C.
      Resultado: la captura solo tiene el ARP request (broadcast) y el ARP
      reply de pc_admin4; los ICMP echo nunca llegan.

    3. Contadores por puerto de p4sw1 (con el lab recien levantado):
      En p4sw1:
        bash /shared/contadores.sh 5 > /shared/contadores-antes.txt
      En pc_admin1:
        ping -c 3 10.19.0.5
      En p4sw1:
        bash /shared/contadores.sh 5 > /shared/contadores-despues.txt
      Resultado: entran por el puerto 2 (pc_admin1) 4 paquetes = 1 ARP
      request + 3 ICMP echo; el ARP reply de pc_admin4 (puerto 5) sale por
      el puerto 2, pero los echo a la MAC ...:08 se descartan (no estan en
      mac_table, accion por defecto drop) y no salen por ningun puerto.

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


PARTE 3 
parte3/   
    cd parte3 && kathara lstart
    Esperar la convergencia de OSPF (unos 40 s). Pruebas principales:
      kathara exec pc_admin1 -- ping -c 4 8.8.8.8  # A a Internet (NAT)
      kathara exec pc_dev1   -- ping -c 4 8.8.8.8
      kathara exec pcb1      -- ping -c 4 8.8.8.8  # B a Internet (NAT)
      kathara exec pcint     -- ping -c 4 203.0.113.34     # srv1 desde Internet
      kathara exec pcint     -- curl -s http://203.0.113.26/   # srvB desde Internet
      kathara exec pc_guest1 -- ping -c 4 10.19.0.2        # debe fallar (politica)
      kathara exec rcla -- iptables -t nat -L POSTROUTING -n -v
    Salidas guardadas en parte3/shared/integracion-*.txt
