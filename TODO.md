# Pendientes de la Parte 2.1 — Grupo 19

Actualizado: 02/11/2026. Este archivo se comparte también en `main` para
coordinar la documentación del equipo. El README contiene las decisiones
y la tabla de direcciones por dispositivo.

## Estado implementado

- [x] Numerar las cuatro redes en los `.startup` de `parte2/`.
- [x] Configurar las rutas por defecto de todos los hosts hacia su gateway.
- [x] Revisar IPs, interfaces y gateways contra `lab.conf`.
- [x] Documentar direccionamiento y decisiones en el README.

| Red | Prefijo | Gateway en rcla | Hosts configurados |
|---|---|---|---|
| ADMIN | `10.19.0.0/26` | eth0: `10.19.0.1` | pc_admin1–4: `.2`–`.5` |
| DESARROLLO | `10.19.0.64/26` | eth1: `10.19.0.65` | pc_dev1–3: `.66`–`.68` |
| INVITADOS | `10.19.2.0/23` | eth2: `10.19.2.1` | pc_guest1–3: `.2`–`.4` de `10.19.2.x` |
| SERVIDORES | `203.0.113.32/27` | eth3: `203.0.113.33` | srv1: `203.0.113.34` |

El código P4 sigue siendo el esqueleto del curso. No se probaron todavía
conectividad ni servicios web de esta parte. No presentar la revisión de
archivos como evidencia de ejecución exitosa.

## Punto 1: documentación del direccionamiento

- [ ] Preparar tabla con red, prefijo/máscara, capacidad utilizable, broadcast,
  gateway y direcciones/interfaces de cada equipo.
- [ ] Preparar figura anotada a partir de `parte2/lab.conf`.
- [ ] Explicar brevemente la elección de cada prefijo y cómo minimiza desperdicio.
- [ ] Explicar que INVITADOS necesita `/23`: `/24` ofrece solo 254 IPs útiles;
  los bloques `/23` comienzan en un tercer octeto par. Ver README.
- [ ] Explicar que SERVIDORES necesita `/27`: `/28` ofrece solo 14 IPs útiles.
  Verificar consistencia con las asignaciones públicas de la parte 1,
  incluida la LAN `203.0.113.16/29` de 1.4/1.5.
- [ ] Mantener la numeración de pc_admin4 en figura y tabla. Su papel de host
  adicional sin entrada inicial en el switch corresponde a la reflexión 2.2.

## Decisiones pendientes de respuesta docente

- [ ] Confirmar si los 62 hosts de DESARROLLO incluyen el gateway. Se eligió
  provisionalmente `/26`: admite 61 equipos más gateway. Si se exigen 62
  equipos además del gateway, revisar prefijo, direcciones y documentación.
- [ ] Confirmar la conectividad esperada entre clientes en la integración.
  ADMIN y DESARROLLO reutilizan direcciones dentro de la LAN privada de B
  (`10.19.0.0/25`). La comunicación mediante destinos públicos y NAT permite
  reutilizar rangos, pero el acceso privado directo presenta superposición.
  Revisar el plan si la respuesta docente exige evitarla.

## Punto 2: dominios de broadcast y colisión

- [ ] Identificar y contar los dominios de broadcast según la topología y el
  comportamiento Ethernet previsto. Explicar el papel separador de rcla.
- [ ] Identificar y contar los dominios de colisión/enlaces Ethernet usando
  los nombres de dominio de `lab.conf`.
- [ ] Marcar los dominios en una figura o tabla y explicar el criterio usado.
  Distinguir la topología prevista del comportamiento aún no implementado
  del switch P4.

## Punto 3: captura ARP/Ethernet

- [x] Definir cómo comunicar dos hosts del mismo dominio antes de programar
  el switch, conforme pide la letra. El esqueleto P4 no reenvía tráfico;
  no asumir que el ping funcionará solo por asignar IPs. Si se utiliza un
  escenario auxiliar, documentar sus cambios y conservar la base P4.
- [x] Ejecutar la prueba y guardar una captura `.pcap` con solicitud y respuesta
  ARP, registrando hosts, interfaces, comandos y condiciones del experimento.
- [x] Interpretar MAC origen/destino, broadcast Ethernet, EtherType y campos
  ARP relevantes (operación, direcciones de emisor y objetivo).
- [x] Relacionar la resolución ARP con la comunicación posterior entre hosts.
- [x] Guardar y enlazar la captura desde el README: se utilizó
  `parte2_1/shared/arp-admin.pcap`, en vez de `parte2/shared/`, para conservar
  separado el escenario auxiliar. pc_admin1 y pc_admin2 comparten ARP_TEST;
  no se modificó parte2 ni se implementó forwarding P4. La captura revisada
  tiene 12 tramas: ARP inicial, cuatro intercambios ICMP y ARP unicast posterior.

## Cierre de 2.1

- [ ] Incorporar al informe la tabla, figura, decisiones y análisis propio de ARP.
- [ ] Resolver o dejar explícitas las aclaraciones docentes pendientes.
- [ ] Reproducir las ejecuciones y capturas de entrega en la VM del curso,
  como exige la letra; registrar el entorno real de cada evidencia.
- [ ] Declarar las herramientas de IA utilizadas y su alcance; el grupo debe
  revisar, comprender y poder justificar todo lo entregado.

El forwarding Ethernet, las tablas MAC, el broadcast y los contadores P4
corresponden a 2.2; la política de invitados a 2.3 y port security a 2.4.
La numeración por sí sola no implementa esas funcionalidades.
