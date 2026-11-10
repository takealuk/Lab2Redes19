# Obligatorio 2 – 2026 · Laboratorios base (Kathará)

Configuraciones iniciales para el Obligatorio 2 de Redes de Computadoras.
Cada carpeta es un laboratorio Kathará independiente:

| Carpeta | Contenido | Partes |
|---|---|---|
| `parte1/` | Escenario estático de RíoNet, con NAT de A y B y servidor público de B | 1.1 |
| `parte1_2/` | Backbone OSPF, anuncios públicos de los clientes y retorno multipath en rint | 1.2 |
| `parte1_3/` | Resultados de las pruebas de convergencia; no es un laboratorio independiente | 1.3 |
| `parte1_4/` | Expansión del ISP con r7, r8 y una LAN nueva | 1.4 |
| `parte1_5/` | Ingeniería de caminos mediante costos OSPF | 1.5 |
| `parte2/` | Numeración de las cuatro redes del Cliente A; switches P4 base | 2.1 |
| `parte2_1/` | Escenario auxiliar y evidencia de ARP/Ethernet | 2.1 |
| `parte2_2/` | Reenvío Ethernet en P4 y reflexión sobre el cuarto host | 2.2 |
| `parte2_3/` | Política de acceso de INVITADOS, scripts y evidencias | 2.3 |
| `parte2_4/` | Política de acceso más port security, scripts y evidencias | 2.4 |
| `parte3/` | ISP ampliado y red de A con P4 integrados; pendiente validar y ampliar B | 3 |

La Parte 3 (integración) se construye como un laboratorio nuevo a partir de los anteriores.

Para levantar un laboratorio, desde su carpeta:

```bash
kathara lstart      # levantar
kathara lclean      # detener y borrar
```

> Kathará solo admite minúsculas, dígitos y `_` en los nombres de dispositivo.
> Por eso los equipos del enunciado se llaman aquí `rint`, `rcla`, `rclb`,
> `pca1`, `pcb1`, `srvb`, `pc_admin1`, etc.

---

## Parte 1 – Backbone de RíoNet

Topología de la Figura 2 del enunciado. Enlaces:

- Internet: `rint–pcint` (INET), `rint–r1`, `rint–r6`
- Backbone: `r1–r2`, `r1–r3`, `r2–r3`, `r2–r4`, `r2–r5`, `r3–r5`, `r4–r5`, `r4–r6`, `r5–r6`
- Clientes: `r3–rcla`, `r5–rclb`; LAN_A (`rcla–pca1`), LAN_B (`rclb–pcb1`), DMZ_B (`rclb–srvb`)

Cada enlace `X–Y` del backbone es el dominio de colisión `X_Y` (por ejemplo `R2_R4`).

| Dispositivo | Imagen | eth0 | eth1 | eth2 | eth3 | eth4 |
|---|---|---|---|---|---|---|
| rint  | kathara/base | INET | RINT_R1 | RINT_R6 | | |
| pcint | kathara/base | INET | | | | |
| r1 | kathara/frr | RINT_R1 | R1_R2 | R1_R3 | | |
| r2 | kathara/frr | R1_R2 | R2_R3 | R2_R4 | R2_R5 | |
| r3 | kathara/frr | R1_R3 | R2_R3 | R3_R5 | R3_RCLA | |
| r4 | kathara/frr | R2_R4 | R4_R5 | R4_R6 | | |
| r5 | kathara/frr | R2_R5 | R3_R5 | R4_R5 | R5_R6 | R5_RCLB |
| r6 | kathara/frr | RINT_R6 | R4_R6 | R5_R6 | | |
| rcla | kathara/base | R3_RCLA | LAN_A | | | |
| pca1 | kathara/base | LAN_A | | | | |
| rclb | kathara/base | R5_RCLB | LAN_B | DMZ_B | | |
| pcb1 | kathara/base | LAN_B | | | | |
| srvb | kathara/base | DMZ_B | | | | |

Qué viene configurado:
- **pca1** (único host del Cliente A): `192.168.100.10/24`, gateway `192.168.100.1`.
  El resto del direccionamiento debe ser diseñado y configurado por el grupo.
- **r1–r6**: FRR se inicia en el `.startup` con el demonio `ospfd` habilitado
  (`rN/etc/frr/daemons`). El archivo `rN/etc/frr/frr.conf` está vacío y debe ser
  completado por el grupo. Consola del router: `vtysh`.
- **srvb**: servidor web Apache (HTTP) iniciado.
- **rint, rcla, rclb**: `kathara/base` (Linux). Las rutas estáticas y el NAT
  (`iptables`, ver Anexo 1) se configuran en sus `.startup`.

### Avance de 1.1: árbol y direccionamiento

Para organizar las rutas estáticas elegimos el siguiente árbol de recubrimiento.
Conserva el camino ya configurado `rclb–r5–r6–rint`. Los enlaces restantes de
la topología física no se utilizan como caminos de tránsito en este diseño.
No se está configurando STP; cada ruta estática debe seguir el árbol hacia su destino.

```text
pcint
  |
rint
  |
 r6
  |
 r5 ─── rclb ─── pcb1
  |        |
  |       srvb
  |
 r2
 / \
r1  r4
 |
r3
 |
rcla
 |
pca1
```

El árbol muestra el diseño completo propuesto; hasta ahora se incorporaron
`r1`, `r2`, `r3`, `r4`, `r5`, `r6`, `rint`, `rclb`, `pcb1`, `pcint` y `srvb`.
La rama de A también está numerada: `rcla` tiene direcciones en sus dos interfaces.
En 1.1 también se configuraron la salida a Internet simulado y SNAT para A.
`rcla` usa una ruta por defecto hacia r3 (`203.0.113.13`) y traduce el origen
de `192.168.100.0/24` a su IP pública de eth0, `203.0.113.14`.
Las rutas de retorno a `203.0.113.12/30` siguen el árbol:
`rint → r6 → r5 → r2 → r1 → r3 → rcla`. En r3 esa red está directamente
conectada. El recorrido de ida es
`pca1 → rcla → r3 → r1 → r2 → r5 → r6 → rint → pcint`.
En `parte1_2/` también están configurados la ruta por defecto y SNAT de rcla,
el retorno desde rint y el anuncio OSPF de la red pública de A desde r3.
La conectividad de extremo a extremo se verificó tras recrear ese escenario.

Direcciones actualmente configuradas en `parte1/`:

| Red o uso | Prefijo | Interfaces y direcciones |
|---|---|---|
| LAN B | `10.19.0.0/25` | `rclb eth1: 10.19.0.1`, `pcb1 eth0: 10.19.0.2` |
| Enlace rclb–r5 | `203.0.113.4/30` | `r5 eth4: 203.0.113.5`, `rclb eth0: 203.0.113.6` |
| Enlace r5–r6 | `10.255.0.0/30` | `r5 eth3: 10.255.0.1`, `r6 eth2: 10.255.0.2` |
| Enlace r6–rint | `10.255.0.4/30` | `r6 eth0: 10.255.0.5`, `rint eth2: 10.255.0.6` |
| Enlace r2–r5 | `10.255.0.8/30` | `r5 eth0: 10.255.0.9`, `r2 eth3: 10.255.0.10` |
| Enlace r2–r4 | `10.255.0.12/30` | `r2 eth2: 10.255.0.13`, `r4 eth0: 10.255.0.14` |
| Enlace r1–r2 | `10.255.0.16/30` | `r2 eth0: 10.255.0.17`, `r1 eth1: 10.255.0.18` |
| Enlace r1–r3 | `10.255.0.20/30` | `r1 eth2: 10.255.0.21`, `r3 eth0: 10.255.0.22` |
| Enlace rint–r1 (fuera del árbol) | `10.255.0.24/30` | `rint eth1: 10.255.0.25`, `r1 eth0: 10.255.0.26` |
| Enlace r2–r3 (fuera del árbol) | `10.255.0.28/30` | `r2 eth1: 10.255.0.29`, `r3 eth1: 10.255.0.30` |
| Enlace r3–r5 (fuera del árbol) | `10.255.0.32/30` | `r3 eth2: 10.255.0.33`, `r5 eth1: 10.255.0.34` |
| Enlace r4–r5 (fuera del árbol) | `10.255.0.36/30` | `r4 eth1: 10.255.0.37`, `r5 eth2: 10.255.0.38` |
| Enlace r4–r6 (fuera del árbol) | `10.255.0.40/30` | `r4 eth2: 10.255.0.41`, `r6 eth1: 10.255.0.42` |
| Internet simulado | `8.8.8.0/24` | `rint eth0: 8.8.8.1`, `pcint eth0: 8.8.8.8` |
| IP pública de SNAT de B | `203.0.113.1/32` | `rclb lo: 203.0.113.1` |
| Red pública del servidor B | `203.0.113.8/30` | `rclb eth2: 203.0.113.9`, `srvb eth0: 203.0.113.10` |
| Enlace r3–rcla | `203.0.113.12/30` | `r3 eth3: 203.0.113.13`, `rcla eth0: 203.0.113.14` |
| LAN A | `192.168.100.0/24` | `rcla eth1: 192.168.100.1`, `pca1 eth0: 192.168.100.10` |

El enlace cliente–ISP usa direcciones públicas siguiendo la corrección enviada
por los docentes. La IP de SNAT se conserva separada en `lo` de `rclb`.

`r2` tiene una ruta por defecto hacia `r5` (`10.255.0.9`). Para que las
respuestas regresen al enlace `r2–r5`, se agregaron rutas a `10.255.0.8/30`
en `r6` vía `10.255.0.1`, en `rint` vía `10.255.0.5` y en `rclb` vía
`203.0.113.5`. `r5` conoce esa red por estar directamente conectado.

`r4` tiene una ruta por defecto hacia `r2` (`10.255.0.13`). Las rutas hacia
`10.255.0.12/30` apuntan desde `r5` a `r2` (`10.255.0.10`), desde `r6` a
`r5` (`10.255.0.1`), desde `rint` a `r6` (`10.255.0.5`) y desde `rclb` a
`r5` (`203.0.113.5`). `r2` conoce esa subred por estar directamente conectado.
El camino de `r4` hacia Internet es `r4 → r2 → r5 → r6 → rint → pcint`.

`r1` tiene una ruta por defecto hacia `r2` (`10.255.0.17`). Las rutas hacia
`10.255.0.16/30` apuntan desde `r5` a `r2` (`10.255.0.10`), desde `r6` a
`r5` (`10.255.0.1`), desde `rint` a `r6` (`10.255.0.5`) y desde `rclb` a
`r5` (`203.0.113.5`). `r2` conoce esa subred por estar directamente conectado;
`r4` la alcanza mediante su ruta por defecto hacia `r2`.
El camino de `r1` hacia Internet es `r1 → r2 → r5 → r6 → rint → pcint`.

`r3` tiene una ruta por defecto hacia `r1` (`10.255.0.21`). Las rutas hacia
`10.255.0.20/30` apuntan desde `r2` a `r1` (`10.255.0.18`), desde `r5` a
`r2` (`10.255.0.10`), desde `r6` a `r5` (`10.255.0.1`), desde `rint` a
`r6` (`10.255.0.5`) y desde `rclb` a `r5` (`203.0.113.5`). `r1` conoce
esa subred por estar directamente conectado; `r4` la alcanza mediante su
ruta por defecto hacia `r2`.
El camino hacia Internet es `r3 → r1 → r2 → r5 → r6 → rint → pcint`.
Los seis routers del backbone ya tienen configurada su conexión al árbol;
los cinco enlaces fuera del árbol y la rama de A también están numerados.
Según la aclaración docente, se numera todo, pero
no es necesario enrutar hacia todas las interfaces: se conservan las rutas
necesarias para los servicios y el diseño estático elegido.

Para los enlaces fuera del árbol solo se agregaron direcciones IP. Linux crea
las rutas directamente conectadas, por lo que sus extremos pueden comunicarse
por esos enlaces. Se conservaron las rutas estáticas y por defecto existentes;
esto no garantiza todavía acceso a todas las nuevas IP desde el resto de la red.
El árbol sigue siendo la guía para las rutas de tránsito configuradas manualmente.

El servidor B usa `203.0.113.10/30` y tiene como gateway `203.0.113.9`
(`rclb eth2`). El prefijo `/30` admite exactamente las dos interfaces necesarias
para esta parte. No se aplica NAT al tráfico originado en el servidor: la regla
SNAT existente solo coincide con la LAN privada `10.19.0.0/25`.

Para alcanzar `203.0.113.8/30`, se configuraron rutas en `r5` vía
`203.0.113.6`, en `r6` vía `10.255.0.1` y en `rint` vía `10.255.0.5`.
El acceso desde Internet sigue `pcint → rint → r6 → r5 → rclb → srvb`.
Las respuestas hacia `8.8.8.0/24` usan las rutas ya existentes.

Flujo de trabajo: incorporar un nodo, probar el enlace directo, agregar las
rutas de retorno y probar la conectividad de extremo a extremo.

### Evidencia de NAT

La captura [nat-b.pcap](parte1/shared/nat-b.pcap) contiene cuatro intercambios
ICMP completos entre `pcb1` y `8.8.8.8`. Se verificaron las siguientes direcciones:

| Momento | Origen | Destino |
|---|---|---|
| Solicitud antes de SNAT | `10.19.0.2` | `8.8.8.8` |
| Solicitud después de SNAT | `203.0.113.1` | `8.8.8.8` |
| Respuesta desde Internet | `8.8.8.8` | `203.0.113.1` |
| Respuesta entregada a la LAN | `8.8.8.8` | `10.19.0.2` |

Los identificadores y números de secuencia ICMP permiten relacionar cada
solicitud y respuesta antes y después de la traducción. La captura evidencia
SNAT en la salida y la traducción inversa de las respuestas hacia la PC privada.

La captura [nat-a.pcap](parte1/shared/nat-a.pcap) se realizó en `rcla`,
con `tcpdump -ni any -w /shared/nat-a.pcap 'icmp and host 8.8.8.8'`,
mientras se ejecutaba `ping -c 4 8.8.8.8` desde `pca1`.
Se revisaron sus 16 registros: cuatro intercambios ICMP, observados antes
y después de NAT en ambos sentidos, con identificador 4 y secuencias 1–4.

| Momento | Origen | Destino |
|---|---|---|
| Solicitud antes de SNAT | `192.168.100.10` | `8.8.8.8` |
| Solicitud después de SNAT | `203.0.113.14` | `8.8.8.8` |
| Respuesta desde Internet | `8.8.8.8` | `203.0.113.14` |
| Respuesta entregada a la LAN | `8.8.8.8` | `192.168.100.10` |

La captura se detuvo desde otra consola con
`kathara exec rcla -- pkill -INT -x tcpdump`; el archivo quedó completo.

### Pruebas

Pruebas ejecutadas y confirmadas por Luca en el laboratorio:

- Cliente A: pings `rcla → 203.0.113.13`, `rcla → 192.168.100.10` y
  `pca1 → 192.168.100.1` funcionando.
- El 22/10/2026, tras recrear `parte1/` en Windows con Docker y Kathará,
  Luca confirmó `pca1 → 8.8.8.8`: cuatro respuestas, 0 % de pérdida y TTL 57.
  La regla SNAT en rcla registró un paquete de 84 bytes, traducido a
  `203.0.113.14`. También confirmó `pcb1 → 8.8.8.8` con cuatro respuestas
  y 0 % de pérdida. La captura `nat-a.pcap` verifica la traducción de A;
  las pruebas de entrega deben repetirse en la VM del curso.

- Ping directo entre `rclb` y `srvb`: funcionamiento confirmado.
- `pcint → 203.0.113.10`: cuatro respuestas, 0 % de pérdida en la salida compartida.
- HTTP desde `pcint` a `http://203.0.113.10/`: `curl` recibió la página de Apache.
- `srvb → 8.8.8.8`: funcionamiento confirmado.
- Después de `kathara lrestart`, Luca confirmó nuevamente ping y HTTP desde
  `pcint` al servidor y ping desde `pcb1` a `8.8.8.8` (salida con NAT).
- Ping del enlace directo entre `r2` y `r5`.
- `r2 → 8.8.8.8`: cuatro respuestas y 0 % de pérdida en la salida compartida.
- `pcb1 → 10.255.0.10` y `pcb1 → 8.8.8.8`: funcionamiento confirmado.
- `pcb1 → 10.255.0.9`: funcionamiento confirmado.
- Ping del enlace directo entre `r2` y `r4`: funcionamiento confirmado.
- Ping del enlace directo entre `r1` y `r2`: funcionamiento confirmado.
- Ping del enlace directo entre `r1` y `r3`: funcionamiento confirmado.
- Tras agregar las rutas de retorno de `r1`, Luca confirmó que funcionaron
  `r1 → 8.8.8.8`, `pcb1 → 10.255.0.18`, `pcb1 → 8.8.8.8` y
  `r4 → 10.255.0.18`.

Tras agregar las rutas de retorno de `r4`, las pruebas previstas son
`r4 → 8.8.8.8`, `pcb1 → 10.255.0.14` y `pcb1 → 8.8.8.8`.
No se adjuntaron resultados de estas tres pruebas en esta actualización.

Tras agregar las rutas de retorno de `r3`, quedan por confirmar los pings
`r3 → 8.8.8.8`, `pcb1 → 10.255.0.22`, `pcb1 → 8.8.8.8` y
`r4 → 10.255.0.22`. No se adjuntaron resultados de estas pruebas.

Para verificar los enlaces fuera del árbol, probar ping en ambos sentidos
entre `.25` y `.26`, `.29` y `.30`, `.33` y `.34`, `.37` y `.38`, y `.41` y
`.42`, todas dentro de `10.255.0.0/24`. Sus resultados quedan pendientes de
confirmación; esta actualización verifica los archivos, no ejecuta la emulación.

### Parte 1.2 – OSPF: avance actual

Se creó `parte1_2/` como copia independiente de `parte1/`, conservando las IP,
NAT y servicios de 1.1. Posteriormente se retiraron las rutas estáticas internas
heredadas que OSPF reemplaza. La versión estática de `parte1/` queda preservada.

En `r1–r6`, los archivos `etc/frr/frr.conf` activan OSPF en ambos extremos
de los nueve enlaces internos. Se utiliza una sola área `0.0.0.0`, suficiente
para este escenario pequeño, sin introducir una división en múltiples áreas.
Los identificadores son `1.1.1.1` para r1, hasta `6.6.6.6` para r6;
identifican a los routers en OSPF, sin asignar nuevas IP a sus interfaces.

Cada interfaz interna tiene costo explícito 10. Como no se especificaron
diferencias de capacidad, todos los enlaces tienen igual preferencia: entre
caminos internos se minimiza el número de enlaces. El valor 10 es una escala
elegida, no una medida de latencia. Pueden existir caminos de igual costo.

| Router | Interfaces con OSPF | Vecinos esperados |
|---|---|---|
| r1 | eth1, eth2 | r2, r3 |
| r2 | eth0, eth1, eth2, eth3 | r1, r3, r4, r5 |
| r3 | eth0, eth1, eth2 | r1, r2, r5 |
| r4 | eth0, eth1, eth2 | r2, r5, r6 |
| r5 | eth0, eth1, eth2, eth3 | r2, r3, r4, r6 |
| r6 | eth1, eth2 | r4, r5 |

Luca confirmó los vecinos esperados en estado `Full` tras aplicar la
configuración. Se verifican dentro de cada router con:

```bash
vtysh -c "show ip ospf neighbor"
vtysh -c "show ip ospf interface"
```

Las interfaces Ethernet conservan el tipo OSPF predeterminado `BROADCAST`;
por eso aparecen roles DR y BDR aun cuando cada enlace conecta dos routers.
No se habilitó OSPF hacia `rint`, `rcla` ni `rclb` en este avance.

**Routing interno migrado a OSPF.** Se quitaron las rutas por defecto del árbol
estático en `r1–r4`, la ruta interna explícita de `r2` y las rutas a enlaces
del escenario anterior en `r5` y `r6`. Se mantienen las direcciones y el inicio
de FRR. En `r1`, Luca verificó vecinos `Full`, rutas internas remotas `O>*`
(seleccionadas e instaladas) y ping a `10.255.0.2` en `r6`: cuatro respuestas,
0 % de pérdida después del reinicio. Para algunos prefijos hay dos siguientes
saltos OSPF de igual costo. Ya no aparece la ruta por defecto estática de `r1`.

Esta limpieza no elimina todas las rutas estáticas del laboratorio: siguen
las de clientes, hosts y `rint`, y temporalmente las de borde en `r5/r6`
hacia Internet y destinos de B. No se redistribuyen indiscriminadamente.
La LAN privada de B no debe anunciarse mediante OSPF.

**Prefijos públicos de B anunciados y verificados.** En `r5`, las rutas a
`203.0.113.1/32` (IP de SNAT) y `203.0.113.8/30` (servidor) se definen
en `etc/frr/frr.conf` mediante `ip route`, con siguiente salto `203.0.113.6`
(`rclb`). El cliente no ejecuta OSPF, por lo que estas rutas de acceso siguen
siendo necesarias. Se retiraron sus comandos equivalentes de `r5.startup`.

`redistribute static` anuncia las rutas estáticas de FRR. Actualmente solo
se definen allí esos dos destinos públicos; la LAN privada de B y la ruta
a Internet permanecen configuradas desde Linux y no se redistribuyen.
No se utilizan prefix-list ni route-map. Si se agregan otras rutas estáticas
en FRR, también se anunciarán: hay que revisar ese alcance antes de hacerlo.

Se quitaron de `r6.startup` las rutas estáticas equivalentes hacia esos dos
prefijos; r6 ahora los aprende mediante OSPF.

Luca verificó desde r1 los dos anuncios externos originados por `5.5.5.5`
con `show ip ospf database external`. Sin métrica ni tipo explícitos, se
observaron anuncios tipo externo 2, métrica 20. En r1 ambas rutas aparecen
seleccionadas e instaladas por OSPF, con siguientes saltos por r2 y r3.
Tras eliminar las rutas estáticas en ejecución de r6, también se comprobaron
ambas rutas seleccionadas e instaladas por OSPF vía `10.255.0.1` (r5).
Esta verificación comprueba anuncios y selección de rutas, no constituye
todavía una prueba completa de conectividad desde A.

Tras simplificar la redistribución, el 22/10/2026 Luca confirmó en el entorno
local Windows con Docker y Kathará: las dos rutas `S>*` en r5, vecinos Full
en r1 y ambos prefijos `O>*` en r1 con siguientes saltos por r2 y r3.
También comprobó `pcb1 → 8.8.8.8` y `pcint → 203.0.113.10`, ambos con
cuatro respuestas y 0 % de pérdida, y HTTP desde pcint al servidor con
`200 OK`. Las verificaciones de entrega deben repetirse en la VM del curso.

El enlace de acceso `r5–rclb` conserva sus IP y no forma adyacencias OSPF.
Por ahora no se anuncia su subred mediante una interfaz pasiva: los destinos
públicos de B se alcanzan mediante los anuncios externos de r5. Se deja esa
opción fuera de este avance.

**Salidas por defecto y cliente A.** r1 tiene una ruta por defecto hacia
rint `10.255.0.25` y r6 hacia rint `10.255.0.6`. Ambos usan
`default-information originate`, sin `always`: anuncian la salida mientras
exista una ruta por defecto instalada. Luca verificó en r5 una ruta por
defecto OSPF seleccionada e instalada, métrica 10, vía r6 `10.255.0.2`.
Se retiraron las rutas específicas hacia `8.8.8.0/24` de r5 y r6.

rcla usa una ruta por defecto hacia r3 y SNAT a `203.0.113.14`.
En r3, eth3 participa en el área 0 como interfaz pasiva: anuncia
`203.0.113.12/30` sin formar adyacencias con rcla. Se verificó en r6 la
ruta OSPF instalada a ese prefijo, métrica 30, vía r5.
rclb tiene una ruta por defecto hacia r5 `203.0.113.5`, necesaria también
para devolver las respuestas de srvb a A.

**Limpieza de rutas heredadas.** Se eliminaron las siete rutas específicas
de rclb, reemplazadas por su ruta por defecto; las rutas a la LAN privada
de B de r5, r6 y rint; y cuatro rutas de rint hacia enlaces internos.
En r1–r6 no quedan rutas estáticas que impongan el árbol interno de 1.1.
Se conservan las dos rutas públicas de B en FRR de r5, las salidas por
defecto de r1/r6, los gateways de clientes y hosts, y tres rutas públicas
de retorno en rint. Este último no ejecuta OSPF. Inicialmente los retornos
de A y B estaban fijados vía r6; el ajuste multipath del 04/11/2026,
documentado abajo, reemplaza ese retorno fijo en 1.2, 1.4 y 1.5.

**Pruebas persistentes confirmadas el 22/10/2026.** Tras `lclean` y `lstart`,
incluyendo la última limpieza de rint, Luca verificó en Windows con Docker:
pings de pca1 y pcb1 a `8.8.8.8`, cuatro respuestas y 0 % de pérdida;
HTTP de pca1 y pcint a `203.0.113.10`, ambos `200 OK`.
Antes de esa última limpieza también se verificaron ping A–srvb sin pérdida
y la regla SNAT de A con tráfico registrado. Repetir las pruebas de entrega
en la VM del curso.

**Captura del arranque OSPF.**
[ospf-arranque-r1-r2.pcap](parte1_2/shared/ospf-arranque-r1-r2.pcap)
contiene 40 paquetes OSPF en el enlace r1–r2, durante unos 40,6 segundos.
Se capturó temporalmente en r1 eth1 antes de iniciar FRR:

```bash
tcpdump -ni eth1 -U -w /shared/ospf-arranque-r1-r2.pcap 'ip proto 89' &
```

Tras recrear el laboratorio, se detuvo con
`kathara exec r1 -- pkill -INT -x tcpdump`. La línea temporal se retiró
del startup para no sobrescribir la evidencia. La revisión identificó:

| Paquetes | Mensaje | Función |
|---|---|---|
| 1–9 | Hello | Descubrimiento, aproximadamente cada 10 segundos |
| 10–14 | Database Description | Intercambio de resúmenes de LSDB |
| 15–16 | Link State Request | Solicitud de LSAs faltantes |
| 17 en adelante | Link State Update | Transferencia y propagación de LSAs |
| 28 y 32 | Link State Acknowledgment | Confirmación de recepción |

La sincronización se observa alrededor del segundo 40. El archivo
[r1-show-ip-ospf-neighbor.txt](parte1_2/shared/r1-show-ip-ospf-neighbor.txt)
registra una consulta posterior con r2 y r3 en `Full/DR`, y colas
RXmtL/RqstL/DBsmL en cero. La consulta es local y no genera paquetes OSPF:
el TXT confirma el estado posterior y complementa la captura de arranque.

### Evidencias y consultas de 1.2

Los siguientes archivos guardan observaciones reales compartidas por Luca
el 22/10/2026. No son configuraciones ni se ejecutan al iniciar el laboratorio.
Kathará comparte `parte1_2/shared/` como `/shared` dentro de los dispositivos.

| Archivo | Contenido y propósito |
|---|---|
| [ospf-arranque-r1-r2.pcap](parte1_2/shared/ospf-arranque-r1-r2.pcap) | Paquetes del arranque OSPF entre r1 y r2; se abre con Wireshark para estudiar los mensajes descritos arriba. |
| [r1-show-ip-ospf-neighbor.txt](parte1_2/shared/r1-show-ip-ospf-neighbor.txt) | Consulta posterior de vecinos de r1: r2 y r3 en Full/DR, sin elementos pendientes en las colas mostradas. |
| [r1-r5-lsdb-forwarding.txt](parte1_2/shared/r1-r5-lsdb-forwarding.txt) | LSDB y tabla principal de rutas de Linux de r1 y r5, para comparar información del protocolo con decisiones de reenvío. |
| [caminos-a-b-a-internet.txt](parte1_2/shared/caminos-a-b-a-internet.txt) | Consultas de rutas en r3 y traceroute ICMP desde pca1 hacia srvb y pcint; permiten contrastar rutas elegidas y saltos observados. |

Los comandos siguientes se ejecutan desde PowerShell, ubicado en `parte1_2/`,
con el laboratorio encendido y OSPF estabilizado. `kathara exec EQUIPO --`
ejecuta el resto del comando dentro del equipo indicado. `vtysh -c` consulta
FRR; `ip route` consulta las rutas de Linux. Son consultas de solo lectura.

**Vecinos.** El comando guardado en el TXT es:

```powershell
kathara exec r1 -- vtysh -c "show ip ospf neighbor"
```

`Full` indica que se completó la sincronización con el vecino. DR es el rol
elegido en ese enlace Ethernet de tipo OSPF broadcast. El TXT confirma el
estado posterior al intercambio; no es necesario que el comando aparezca
en la captura, porque consultar FRR no genera paquetes OSPF.

**Captura.** En el comando `tcpdump` usado arriba, `-n` evita resolver nombres,
`-i eth1` selecciona el enlace r1–r2 y `-w` escribe un archivo PCAP.
`-U` escribe los paquetes conforme llegan, `ip proto 89` selecciona OSPF
y `&` deja la captura en segundo plano para iniciar FRR a continuación.
`pkill -INT -x tcpdump` envía una señal de interrupción a los procesos tcpdump
del router y permite cerrar el archivo. La captura es del enlace r1–r2;
no contiene todo el tráfico de los demás enlaces del backbone.

**LSDB y forwarding.** Se ejecutaron:

```powershell
kathara exec r1 -- vtysh -c "show ip ospf database"
kathara exec r5 -- vtysh -c "show ip ospf database"
kathara exec r1 -- ip route
kathara exec r5 -- ip route
```

Las LSDB observadas contienen los mismos identificadores, secuencias y checksums:
seis Router LSAs, nueve Network LSAs y cuatro anuncios externos E2.
Estos últimos corresponden a las salidas por defecto de r1 y r6 y a los
dos prefijos públicos de B originados por r5. Las edades difieren levemente
porque las consultas no son simultáneas. La red pública de A forma parte
de la información de r3 como red de su interfaz pasiva, no de un anuncio externo.

Las tablas de forwarding difieren porque se calculan desde cada ubicación:
r1 sale directamente a rint por su ruta estática, mientras r5 aprende la
salida OSPF vía r6. Los destinos públicos de B son estáticos en r5 y
aprendidos por OSPF en r1. La red pública de A se alcanza por r3 desde ambos,
usando vecinos e interfaces diferentes. Por eso LSDB y forwarding no contienen
la misma información: una describe topología y anuncios; la otra selecciona
prefijos y siguientes saltos para reenviar, incluyendo conectadas y estáticas.

En `ip route`, `nhid` referencia un objeto de siguiente salto de Linux y puede
representar un grupo multipath. Se puede ampliar con `ip nexthop show`.
El `metric 20` mostrado por Linux no debe interpretarse como el costo SPF
del camino; para consultar las métricas OSPF se usa `vtysh`.

**Caminos y costos.** Las consultas y sondas guardadas son:

```powershell
kathara exec r3 -- vtysh -c "show ip route 203.0.113.10"
kathara exec r3 -- vtysh -c "show ip route 0.0.0.0/0"
kathara exec pca1 -- traceroute -I -n 203.0.113.10
kathara exec pca1 -- traceroute -I -n 8.8.8.8
```

Las consultas de r3 indican siguiente salto, origen y métrica de la ruta
seleccionada. `traceroute` contrasta el recorrido con sondas de TTL creciente;
`-I` usa ICMP y `-n` muestra direcciones sin resolución de nombres.
Se dejaron los valores predeterminados: tres sondas por salto. Cada tiempo
es de ida y vuelta de una sonda hasta quien responde, no la latencia aislada
de un enlace. La versión final del TXT conserva esas nuevas ejecuciones.

| Destino | Recorrido observado |
|---|---|
| Servidor público B | `pca1 → rcla → r3 → r5 → rclb → srvb` |
| Internet simulado | `pca1 → rcla → r3 → r1 → rint → pcint` |

En el traceroute a pcint, el cuarto salto responde como `10.255.0.6`, una
dirección de rint en su interfaz hacia r6. No significa que la sonda haya
atravesado r6: el salto anterior es r1 y el router puede responder con una
dirección de otra interfaz. El recorrido observado concuerda con las rutas.

Cada enlace interno tiene costo 10. Para B, r3 alcanza directamente al
anunciante r5 con costo interno 10. El prefijo del servidor se observa como
externo E2 de métrica 20: esa cifra no suma los costos de enlaces internos.
Las salidas por defecto también son E2, con igual métrica externa 10;
desde r3, alcanzar r1 cuesta 10 y alcanzar r6 por r5 cuesta 20, lo que
explica la elección de r1. Los caminos de igual costo observados desde r1
hacia B no implican que todos los pares de extremos tengan ECMP.
OSPF decide dentro del ISP; los saltos de acceso dependen de las redes
conectadas, gateways y rutas estáticas de clientes y bordes.

Queda que el grupo integre e interprete estas evidencias en su informe,
revise tablas y diagramas y reproduzca las verificaciones de entrega en la VM.

Para ejecutar esta copia, detener primero el laboratorio anterior desde su
carpeta con `kathara lclean`; luego ejecutar `kathara lstart` desde `parte1_2/`.
Para aplicar cambios de archivos en la copia ya activa, usar `kathara lrestart`
desde `parte1_2/`. La captura de NAT de 1.1 se conserva únicamente en
`parte1/shared/nat-b.pcap` y `parte1/shared/nat-a.pcap`; las evidencias OSPF
de 1.2 están en `parte1_2/shared/`.

### Parte 1.4 – `parte1_4/`
El escenario ya incorpora r7/r8, sus enlaces y la LAN del cliente nuevo
`203.0.113.16/29`, con gateway r8 `203.0.113.17` y pcc1 `203.0.113.18`.
Las evidencias previas están en `parte1_4/shared/`. Las repeticiones pendientes
por el cambio de retorno de rint se detallan a continuación.

### Ajuste del retorno de rint en 1.2, 1.4 y 1.5 — 04/11/2026

Se reemplazó el siguiente salto único vía r6 por rutas estáticas multipath
de igual peso hacia r1 (`10.255.0.26`, eth1 de rint) y r6 (`10.255.0.5`,
eth2 de rint). No se agregó FRR/OSPF a rint ni se modificaron los costos
OSPF, las direcciones o las reglas NAT. Los clientes conservan sus gateways.

Se modificaron únicamente los `rint.startup` de estos escenarios:

| Escenario | Prefijos con dos siguientes saltos |
|---|---|
| parte1_2 | `203.0.113.1/32`, `203.0.113.8/30`, `203.0.113.12/30` |
| parte1_4 y parte1_5 | Los anteriores y `203.0.113.16/29` |

Cada ruta se configura como un único comando; por ejemplo:

```bash
ip route add 203.0.113.1/32 \
    nexthop via 10.255.0.26 \
    nexthop via 10.255.0.5
```

Los dos siguientes saltos tienen peso 1 por defecto. Linux selecciona el
camino mediante su mecanismo de hashing ECMP: no se exige alternancia por
paquete ni un reparto exacto 50/50. Duplicar dos comandos `ip route add`
para el mismo prefijo y prioridad devolvió `File exists` y no instaló el
segundo. El kernel WSL anterior tampoco admitía multipath; la ruta se
comprobó en la VM del curso y, tras actualizar WSL, en Docker sobre Windows.
Si aparece `Multipath support not enabled in kernel`, es necesario resolver
el soporte del entorno; no sustituir por comandos duplicados.

**Verificado en 1.2:** las tres rutas se instalaron con ambos nexthop.
Luca confirmó pings A/B a pcint y pcint a srvb, todos con cuatro respuestas
y 0 % de pérdida, y HTTP pcint–srvb con `200 OK`.
Las consultas de reenvío desde `8.8.8.8` por eth0 de rint seleccionaron
r6 para `203.0.113.1` y `203.0.113.14`, y r1 para `203.0.113.10`.
Una captura de texto posterior con `tcpdump -ni any icmp` confirmó cuatro
intercambios por destino: solicitudes hacia NAT B saliendo por eth2 y hacia
srvb por eth1; las respuestas de ambos regresaron por eth2. Esto demuestra
uso de ambos enlaces y asimetría válida, no un reparto estadístico 50/50.
Estas salidas fueron compartidas en el chat; aún no se guardó una nueva
captura PCAP de este ajuste en el repositorio.

Durante una prueba anterior al estado estable aparecieron bucles entre rint
y sus vecinos, con ICMP Time Exceeded. Después se comprobaron vecinos Full
y rutas públicas OSPF instaladas en r1/r6, y la repetición no mostró bucles.
Antes de probar, esperar la estabilización y confirmar esas rutas específicas:
las defaults de r1/r6 hacia rint no deben sustituirlas para estos destinos.

**Alcance:** `parte1/` conserva su diseño estático anterior. `parte1_3/`
contiene resultados de ensayos r1–r4 que no pasan por rint; este ajuste
no exige repetirlos. Los cambios de 1.4 y 1.5 solo fueron revisados en los
archivos: sus responsables deben ejecutar las siguientes verificaciones.

#### Verificaciones pendientes en 1.4

- [ ] Recrear el escenario desde su carpeta y esperar vecinos Full y rutas
  públicas instaladas. Comprobar `kathara exec rint -- ip route`: los cuatro
  prefijos deben mostrar ambos siguientes saltos. Revisar el startup log.
- [ ] Repetir pings pca1–pcc1, pcint–pcc1 y pcc1–pcint. La primera prueba
  sirve de control; las otras dos dependen directamente del nuevo retorno.
  Confirmar también salida de A/B y acceso HTTP pcint–srvb.
- [ ] Repetir la caída del enlace r6–r8 y la conectividad desde pcint hacia
  pcc1. Guardar el nuevo traceroute: rint puede elegir ahora r1 o r6, por lo
  que no se debe asumir el recorrido anterior que empezaba por r6.
- [ ] Observar tráfico por ambos enlaces de rint usando varios destinos o
  flujos. Si una prueba utiliza solo uno, no implica por sí sola un fallo
  de ECMP. No identificar balanceo solo a partir de una ruta instalada.
- [ ] Conservar resultados originales y guardar las nuevas evidencias con
  nombres distintos y sus condiciones. Actualizar el informe para distinguir
  las pruebas con retorno fijo de las realizadas con multipath.

La medición de incorporación de la nueva LAN, desde habilitar los enlaces
hasta que r1 instala la ruta, no usa rint y no requiere repetirse por este
ajuste. Tampoco cambia su direccionamiento ni el anuncio OSPF del POP.

#### Verificaciones pendientes en 1.5

- [ ] Recrear el escenario y comprobar instalación de las cuatro rutas
  multipath y ausencia de errores del startup de rint.
- [ ] Repetir conectividad A/B–pcint, pcint–srvb por ping/HTTP y
  pcint–pcc1/pcc1–pcint: son pruebas de integración afectadas por el retorno.
  Confirmar uso de ambos enlaces con tráfico de varios destinos o flujos.
- [ ] Como control, consultar rutas y traceroute r1–r6 en ambos sentidos
  antes y después de la falla elegida en 1.5. No modificar los costos ni
  forzar que los resultados coincidan con evidencias anteriores.
- [ ] Documentar el nuevo retorno en el informe y conservar separadas las
  evidencias nuevas, indicando que multipath no prueba por sí solo tolerancia
  automática a cualquier caída de enlace o router.

Las mediciones originales entre r1 y r6 utilizan destinos internos del ISP
y no pasan por rint. No es obligatorio repetir su medición temporal solo
por este cambio; la consulta de control comprueba que sigue vigente la
selección del camino principal y de respaldo. Si el control encuentra
diferencias o se cambian otros parámetros, revisar y repetir los ensayos
correspondientes antes de dar 1.5 por validada con la configuración final.

---

## Parte 2 – LAN del Cliente A con switches P4

```
                 ┌── p4sw1 ── pc_admin1, pc_admin2, pc_admin3, pc_admin4
                 │
rcla (gateway) ──┼── p4sw2 ── pc_dev1, pc_dev2, pc_dev3
                 │
                 ├── p4sw3 ── pc_guest1, pc_guest2, pc_guest3
                 │
                 └── p4sw4 ── srv1 (HTTP/HTTPS)
```

| Dispositivo | Imagen | Interfaces (dominio de colisión) |
|---|---|---|
| rcla | kathara/base | eth0 RCLA_SW1 · eth1 RCLA_SW2 · eth2 RCLA_SW3 · eth3 RCLA_SW4 |
| p4sw1 | kathara/p4 | eth0 RCLA_SW1 · eth1–eth4 SW1_ADMIN1–4 |
| p4sw2 | kathara/p4 | eth0 RCLA_SW2 · eth1–eth3 SW2_DEV1–3 |
| p4sw3 | kathara/p4 | eth0 RCLA_SW3 · eth1–eth3 SW3_GUEST1–3 |
| p4sw4 | kathara/p4 | eth0 RCLA_SW4 · eth1 SW4_SRV1 |
| pc_admin1–4 | kathara/base | eth0 SW1_ADMIN1–4 |
| pc_dev1–3 | kathara/base | eth0 SW2_DEV1–3 |
| pc_guest1–3 | kathara/base | eth0 SW3_GUEST1–3 |
| srv1 | kathara/base | eth0 SW4_SRV1 |

`pc_admin4` es el host adicional para la **Reflexión 2.2**. Está conectado a p4sw1,
pero la idea es que no se incluya en la configuración del switch.

### Avance de 2.1: numeración de las cuatro redes

Se configuró la subred privada `10.19.0.0/26` para ADMIN, dentro del bloque
`10.19.0.0/16` del grupo 19. Un `/27` ofrece solo 30 direcciones utilizables
y no alcanza para los 31 hosts solicitados. El `/26` ofrece 62, suficientes
también para el gateway; su máscara es `255.255.255.192`, la dirección de
red es `10.19.0.0` y el broadcast es `10.19.0.63`.

| Dispositivo | Interfaz | Dirección | Gateway |
|---|---|---|---|
| rcla | eth0, hacia p4sw1 | `10.19.0.1/26` | No corresponde para este enlace |
| pc_admin1 | eth0 | `10.19.0.2/26` | `10.19.0.1` |
| pc_admin2 | eth0 | `10.19.0.3/26` | `10.19.0.1` |
| pc_admin3 | eth0 | `10.19.0.4/26` | `10.19.0.1` |
| pc_admin4 | eth0 | `10.19.0.5/26` | `10.19.0.1` |

Las direcciones se guardaron con `ip addr add ... dev ...` en los `.startup`.
Cada PC tiene `ip route add default via 10.19.0.1` para entregar al gateway
los paquetes destinados fuera de su LAN. Las interfaces se identificaron
en `lab.conf`: eth0 de rcla conecta con p4sw1; cada PC conecta por su eth0.
No se modificó la topología ni se asignaron IP de gestión a los switches.

`pc_admin4` también se numera en 2.1. Para la reflexión de 2.2 se dejará
inicialmente su MAC fuera de las tablas de forwarding del switch:
configurar la IP de un host no equivale a registrar su MAC en esas tablas.

**Decisión provisional:** ADMIN se numera con el tercer octeto en cero,
según lo acordado por el grupo. Se superpone con la LAN privada de B de
la parte 1 (`10.19.0.0/25`). Las redes privadas pueden reutilizar prefijos
si la comunicación se realiza mediante destinos públicos y NAT, pero la
superposición dificulta el acceso directo entre sus direcciones privadas.
Se consultará al docente qué conectividad entre clientes espera en la
integración de la parte 3 y, si corresponde, se cambiará ADMIN a otra subred
del mismo `/16` antes de integrar los escenarios.

**Verificación realizada:** revisión de los archivos y consistencia de las
IPs, prefijos, gateways e interfaces. No se levantó ni probó la conectividad
de la parte 2; el programa P4 sigue siendo el esqueleto y todavía no implementa
forwarding. No se afirma que los pings funcionen con esta configuración.

**DESARROLLO:** se configuró `10.19.0.128/25`, sin superposición con ADMIN
ni INVITADOS. La máscara es `255.255.255.128`, la dirección de red
`10.19.0.128` y el broadcast `10.19.0.255`.

| Dispositivo | Interfaz | Dirección | Gateway |
|---|---|---|---|
| rcla | eth1, hacia p4sw2 | `10.19.0.129/25` | No corresponde para este enlace |
| pc_dev1 | eth0 | `10.19.0.130/25` | `10.19.0.129` |
| pc_dev2 | eth0 | `10.19.0.131/25` | `10.19.0.129` |
| pc_dev3 | eth0 | `10.19.0.132/25` | `10.19.0.129` |

Las IPs y rutas por defecto están guardadas en los `.startup`, con el mismo
procedimiento usado en ADMIN. Se revisó su consistencia en los archivos;
todavía no se probó conectividad, dado que falta implementar el forwarding P4.

**Aclaración docente aplicada el 04/11/2026:** DESARROLLO debe admitir hasta
62 dispositivos, por ejemplo PCs, simultáneamente. Se reemplazó el `/26`
provisional por `/25`, que ofrece 126 IPs utilizables y permite alojar esos
62 dispositivos además del gateway. Un `/26` solo permite 61 equipos más
gateway. El nuevo bloque debe comenzar en `.128`: conservar `.65/25`
ubicaría la interfaz en `10.19.0.0/25`, superpuesta con ADMIN. El espacio
`10.19.0.64/26` queda disponible para otra asignación.

Se actualizaron el gateway y las tres PCs tanto en `parte2/` como en
`parte2_1/`, y se comprobó que sus configuraciones coinciden. No se ejecutaron
pruebas de conectividad de DESARROLLO. La captura ARP existente sigue siendo
válida: utiliza las PCs de ADMIN, cuyas direcciones no cambiaron.

**INVITADOS:** se requiere capacidad para 256 hosts.
Un `/24` solo ofrece 254 direcciones utilizables, mientras que un `/23`
ofrece 510. Se eligió `10.19.2.0/23`, con máscara `255.255.254.0` y rango
completo desde `10.19.2.0` hasta `10.19.3.255`, sin superponer ADMIN ni
DESARROLLO. Las direcciones y rutas por defecto se guardaron en los `.startup`:

| Dispositivo | Interfaz | Dirección | Gateway |
|---|---|---|---|
| rcla | eth2, hacia p4sw3 | `10.19.2.1/23` | No corresponde para este enlace |
| pc_guest1 | eth0 | `10.19.2.2/23` | `10.19.2.1` |
| pc_guest2 | eth0 | `10.19.2.3/23` | `10.19.2.1` |
| pc_guest3 | eth0 | `10.19.2.4/23` | `10.19.2.1` |

Se revisaron IPs, prefijos, gateways e interfaces contra `lab.conf`, sin
superposiciones con ADMIN y DESARROLLO. No se ejecutaron pruebas de
conectividad: el forwarding P4 todavía no está implementado. La política
que restringe el tráfico de INVITADOS corresponde a 2.3 y no se configura
mediante estas direcciones ni mediante las rutas por defecto.

Un `/23` agrupa dos bloques `/24` consecutivos y alineados: el tercer
octeto de su dirección de red debe ser par (0, 2, 4, etc.). Por eso
`10.19.1.0/23` no define una red desde `10.19.1.0` hasta `10.19.2.255`:
esa dirección pertenece a `10.19.0.0/23`, que abarca los terceros octetos
0 y 1 y se superpone con las redes ya asignadas. El siguiente bloque `/23`
disponible comienza en `10.19.2.0`. En binario, el prefijo fija los primeros
siete bits del tercer octeto y deja su último bit para hosts; así agrupa
0–1, 2–3, etc., pero no 1–2.

**SERVIDORES:** se configuró `203.0.113.32/27`, dentro del bloque público
`203.0.113.0/24`. Un `/28` ofrece 14 IPs utilizables y no alcanza para
los 16 hosts requeridos; el `/27` ofrece 30. La máscara es `255.255.255.224`,
la dirección de red `203.0.113.32` y el broadcast `203.0.113.63`.
No se superpone con los prefijos públicos usados en la parte 1:
`203.0.113.1/32`, `203.0.113.4/30`, `203.0.113.8/30`,
`203.0.113.12/30` y `203.0.113.16/29`.

| Dispositivo | Interfaz | Dirección | Gateway |
|---|---|---|---|
| rcla | eth3, hacia p4sw4 | `203.0.113.33/27` | No corresponde para este enlace |
| srv1 | eth0 | `203.0.113.34/27` | `203.0.113.33` |

En srv1, las IP y la ruta por defecto se configuran antes de preparar
el certificado e iniciar Apache. Se conservaron los servicios HTTP/HTTPS.
No se aplica NAT a esta red pública; la integración y las rutas externas
se resolverán en el escenario correspondiente.

La numeración de las cuatro redes está guardada en los `.startup` y fue
revisada contra `lab.conf`, sin IPs duplicadas ni superposiciones dentro de A.
No se ejecutaron pruebas de conectividad ni de HTTP/HTTPS de esta parte.
Queda pendiente la aclaración docente sobre reutilización de rangos privados
entre clientes. La duda sobre capacidad de DESARROLLO ya fue resuelta.

### Punto 2 de 2.1: dominios de broadcast y colisión

Este punto requiere análisis de la topología y documentación, no cambios en
las configuraciones. El conteo siguiente considera el comportamiento Ethernet
previsto: cada switch P4 conecta los hosts de su LAN y propaga los broadcasts
entre sus puertos, sin reenviarlos al puerto de ingreso. El esqueleto P4 aún
no implementa ese forwarding, por lo que el conteo no constituye una prueba
de conectividad ejecutada.

Un dominio de broadcast comprende los equipos alcanzados por una trama
broadcast de capa 2, como una solicitud ARP. El switch la distribuye dentro
de la LAN, mientras rcla no la reenvía hacia sus otras interfaces.
Resultan **cuatro dominios de broadcast**:

| Dominio | Equipos e interfaz del gateway |
|---|---|
| ADMIN | pc_admin1–4, p4sw1 y rcla eth0 |
| DESARROLLO | pc_dev1–3, p4sw2 y rcla eth1 |
| INVITADOS | pc_guest1–3, p4sw3 y rcla eth2 |
| SERVIDORES | srv1, p4sw4 y rcla eth3 |

Por ejemplo, un ARP broadcast de pc_admin1 se distribuye hacia los demás
hosts de ADMIN y su gateway, pero no hacia las otras tres LAN.

Para los dominios de colisión se cuenta cada segmento Ethernet independiente
conectado a un puerto del switch. En Kathará se identifican mediante los
dominios declarados en `lab.conf`; en esta topología cada uno conecta dos
interfaces. El conteo incluye al host adicional pc_admin4:

| Switch | Enlaces a hosts | Enlace a rcla | Total |
|---|---|---|---|
| p4sw1 | 4 | 1 | 5 |
| p4sw2 | 3 | 1 | 4 |
| p4sw3 | 3 | 1 | 4 |
| p4sw4 | 1 | 1 | 2 |
| Total | 11 | 4 | **15** |

Son `RCLA_SW1`–`RCLA_SW4`, `SW1_ADMIN1`–`SW1_ADMIN4`,
`SW2_DEV1`–`SW2_DEV3`, `SW3_GUEST1`–`SW3_GUEST3` y `SW4_SRV1`.
En Ethernet conmutada full-duplex no se producen las colisiones propias del
medio compartido; aquí se cuentan los 15 segmentos separados por los puertos.
El switch separa esos segmentos pero mantiene el dominio de broadcast de su
LAN; el router separa los cuatro dominios de broadcast.

### Punto 3 de 2.1: captura ARP/Ethernet

Se creó `parte2_1/` como copia auxiliar de `parte2/`. En su `lab.conf`,
pc_admin1 y pc_admin2 comparten directamente `ARP_TEST`, conservando
`10.19.0.2/26` y `10.19.0.3/26`. No se alteraron los programas P4 ni los
startups. Esta conexión permite observar ARP antes de implementar forwarding
P4; no prueba los switches ni cambia el conteo de dominios de la topología
original de `parte2/`.

Se usó `kathara lstart` desde `parte2_1/` para abrir las terminales de los
dispositivos. En pc_admin1 se preparó y ejecutó la captura:

```bash
ip neigh flush dev eth0
tcpdump -i eth0 -w /shared/arp-admin.pcap
```

La primera instrucción elimina las asociaciones IP–MAC de esa interfaz.
`-i eth0` selecciona la interfaz y `-w` guarda las tramas en un archivo,
sin aplicar filtros de captura. En pc_admin2 se ejecutó:

```bash
ping -c 4 10.19.0.2
```

`-c 4` limita la prueba a cuatro solicitudes. Al terminar se detuvo tcpdump
con Ctrl+C en pc_admin1. Si el entorno no transmite esa señal, puede usarse
desde PowerShell `kathara exec pc_admin1 -- pkill -INT -x tcpdump`.
La limpieza de vecinos de pc_admin1 no borra la caché de pc_admin2; si se
repite la prueba y falta el ARP inicial, limpiar también la de pc_admin2
antes de su ping. No es necesario usar el gateway para este destino local.

La captura [arp-admin.pcap](parte2_1/shared/arp-admin.pcap) fue revisada:
contiene 12 tramas y abarca aproximadamente 5,02 segundos.

| Equipo | IP | MAC observada |
|---|---|---|
| pc_admin1, donde se captura | `10.19.0.2` | `b6:66:fd:3b:fc:86` |
| pc_admin2, que inicia el ping | `10.19.0.3` | `52:18:a2:14:16:13` |

| Tramas | Observación |
|---|---|
| 1 | pc_admin2 solicita la MAC de `10.19.0.2` mediante broadcast Ethernet (`ff:ff:ff:ff:ff:ff`). |
| 2 | pc_admin1 responde por unicast indicando su MAC. |
| 3–10 | Cuatro solicitudes ICMP y sus cuatro respuestas, encapsuladas en Ethernet unicast. |
| 11–12 | Solicitud ARP posterior de pc_admin1 por pc_admin2 y respuesta, ambas unicast. |

En las tramas ARP, EtherType es `0x0806`; la operación 1 identifica una
solicitud y la 2 una respuesta. Los campos de emisor y objetivo permiten
relacionar las IP y MAC con los hosts. En la solicitud inicial, el objetivo
es `10.19.0.2` y todavía se busca su MAC. En la respuesta se informa la
asociación con `b6:66:fd:3b:fc:86`. Las tramas del ping tienen EtherType
`0x0800` (IPv4), MAC destino individual y TTL IP 64, coherente con una
comunicación local sin routers intermedios.

La secuencia evidencia resolución ARP seguida de comunicación IPv4 unicast.
Las tramas 11–12 muestran además que una solicitud ARP puede ser unicast
cuando se consulta una asociación ya conocida; no toda solicitud es broadcast.
Las MAC corresponden a esta ejecución y pueden cambiar al recrear el escenario.
El informe debe explicar estos resultados propios y el uso del escenario auxiliar.

**Pendiente de 2.1:** completar figura y tabla; representar y explicar los
dominios de broadcast y colisión e incorporar el análisis de la captura al informe.

**srv1** inicia Apache con HTTP (80) y HTTPS (443, certificado autofirmado).

### Switches P4 base de `parte2/` y `parte2_1/`

Cada `p4swN/` contiene:
- `switch.p4`: **esqueleto** del programa. Define el encabezado Ethernet, el
  parser y el deparser. Ingress y egress están vacíos (`TODO`).
- `commands.txt`: configuración del plano de control (vacío). Cada línea es un
  comando de `simple_switch_CLI` (por ejemplo `table_add ...`), y se aplica al
  iniciar el switch.

El `.startup` de cada switch compila `switch.p4`, inicia el switch P4 (BMv2 `simple_switch`)
y carga `commands.txt`. Puertos P4 ↔ interfaces:

| Puerto P4 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Interfaz | eth0 (hacia rcla) | eth1 | eth2 | eth3 | eth4 (solo p4sw1) |

Dentro de un switch:

```bash
cat /var/log/simple_switch.log     # log de BMv2 (incluye errores de compilación/arranque)
simple_switch_CLI                  # CLI interactiva (help, table_dump, counter_read, ...)
```

Para aplicar cambios en `switch.p4` o `commands.txt`: `kathara lrestart`.

### Parte 2.2 – Reenvío Ethernet en P4

Catalina incorporó el escenario independiente `parte2_2/`. Los cuatro switches
implementan una tabla estática `mac_table` que asocia la MAC de destino con un
puerto de salida. Las MAC y los puertos se cargan desde `commands.txt`.
El destino broadcast se replica mediante el grupo multicast 1; en egress se
descarta la copia destinada al mismo puerto por el que ingresó la trama.
Los destinos desconocidos se descartan por defecto: no hay aprendizaje automático
de MAC ni flooding de unicast desconocido.

Se agregaron contadores de paquetes y bytes por puerto de entrada y de salida.
Para la reflexión sobre `pc_admin4`, su MAC no figura en la tabla inicial de
`p4sw1`, aunque su puerto participa del grupo broadcast. Por ello, recibir un
broadcast no implica que el switch pueda reenviarle un unicast dirigido a su MAC.

Evidencias en `parte2_2/shared/`:

| Archivo | Contenido |
|---|---|
| `contadores.sh` | Consulta los contadores ingress/egress; se ejecuta dentro del switch con `bash /shared/contadores.sh 5` para sus cinco puertos. |
| `contadores-antes.txt`, `contadores-despues.txt` | Lecturas guardadas para comparar el tráfico por puerto. |
| `reflexion-admin4.pcap` | Captura guardada para analizar la incorporación del cuarto host sin modificar la tabla MAC. |

### Parte 2.3 – Política de acceso de INVITADOS

Olivia creó `parte2_3/` a partir del reenvío Ethernet. El parser incorpora IPv4 y
TCP. En `p4sw3`, los puertos de los invitados se marcan como restringidos y se
aplica una lista de permisos antes de consultar la tabla MAC:

- ARP permitido.
- Tráfico IPv4 al gateway `10.19.2.1` permitido.
- TCP a `srv1` (`203.0.113.34`) permitido únicamente para los puertos 80 y 443.
- El resto del tráfico que ingresa por esos puertos se descarta.

La política se basa en el puerto de entrada y los campos del paquete; no mantiene
estado de conexiones. Se agregaron los contadores `acl_allowed` y `acl_denied`.
Los otros switches conservan el reenvío sin marcar sus puertos como restringidos.

Evidencias y scripts en `parte2_3/shared/`:

| Archivos | Contenido |
|---|---|
| `guest1-permitidos.sh`, `2_3-ok-*.txt` | Ping al gateway y consultas HTTP/HTTPS a srv1. Los resultados guardados muestran ping exitoso y código HTTP `200` en ambos servicios. |
| `guest1-bloqueados.sh`, `2_3-bloq-*.txt` | Intentos de ping a srv1, ADMIN y otro invitado, y conexión TCP al puerto 8080. Los pings no reciben respuestas y curl no obtiene respuesta HTTP (`000`). |
| `admin1-control.sh`, `2_3-control-*.txt` | Pruebas de control desde ADMIN hacia srv1. |
| `admin1-stateless.sh`, `2_3-stateless-admin-a-guest.txt` | Prueba desde ADMIN hacia un invitado: el ping falla, consistente con el bloqueo de las respuestas que ingresan desde el puerto restringido. |
| `contadores.sh`, `p4sw3-contadores.sh`, `contadores-0-inicio.txt` a `contadores-3-final.txt` | Consultas y lecturas de los contadores antes y después de las pruebas. La lectura final registra 38 paquetes permitidos y 16 denegados por la ACL. |
| `p4sw3-verificar.sh` | Consulta la configuración del switch. |
| `p4sw3-capturas-iniciar.sh`, `p4sw3-capturas-detener.sh` | Inician y detienen las capturas en el switch. |
| `2_3-entrada-guest1.pcap`, `2_3-salida-rcla.pcap` | Capturas del enlace con guest1 y del enlace hacia rcla para comparar el tráfico antes y después del filtrado. |

Los scripts destinados a un host se ejecutan en su terminal, por ejemplo
`bash /shared/guest1-permitidos.sh` en `pc_guest1`. En HTTPS se utiliza un
certificado autofirmado; el script emplea `curl -k` para realizar esa prueba.

### Parte 2.4 – Port security

Olivia agregó `parte2_4/`, que conserva la política de 2.3 e incorpora en los
cuatro switches una tabla `port_security`. Cada entrada autoriza una combinación
de puerto de ingreso y MAC de origen. Las combinaciones no autorizadas se
descartan antes de aplicar la política de INVITADOS y el reenvío Ethernet.
Las entradas se cargan desde `commands.txt`; en este escenario también se incluye
la MAC de `pc_admin4` en las tablas de reenvío y de port security.

Evidencias y scripts en `parte2_4/shared/`:

| Archivos | Contenido |
|---|---|
| `guest1-ps-correcto.sh`, `2_4-correcto.txt` | Prueba con la MAC legítima de guest1: tres respuestas al ping al gateway, sin pérdida. |
| `guest1-ps-suplantar-admin1.sh`, `2_4-suplantacion-admin1.txt` | Cambia temporalmente la MAC de guest1 por la de admin1 y prueba el gateway. Los tres pings fallan; al restaurar la MAC, la conectividad se recupera. |
| `guest1-ps-suplantar-guest2.sh`, `2_4-suplantacion-guest2.txt` | Repite la prueba usando la MAC de otro invitado, autorizado en un puerto diferente. También se bloquea y se recupera al restaurar la MAC. |
| `contadores.sh`, `p4sw3-contadores.sh`, `contadores-0-inicio.txt` a `contadores-3-tras-suplantar-guest2.txt` | Lecturas por puerto, ACL y violaciones de port security. La lectura final registra seis paquetes en `ps_violations`. |
| `p4sw3-verificar.sh` | Consulta las tablas configuradas. |
| `p4sw3-capturas-iniciar.sh`, `p4sw3-capturas-detener.sh` | Control de las capturas. |
| `2_4-entrada-guest1.pcap`, `2_4-salida-rcla.pcap` | Capturas para contrastar el tráfico recibido del host con el reenviado hacia el router. |

Los scripts de suplantación se ejecutan en `pc_guest1` y restauran su MAC
original al terminar. Las pruebas registradas corresponden a cambios de MAC de
origen; la tabla no implementa una validación de identidad basada en la IP.

Esta actualización resume el código y los resultados incorporados al repositorio
por Catalina y Olivia. No implica una nueva ejecución de los tres escenarios.
El direccionamiento de DESARROLLO se conserva en `10.19.0.128/25` en estas copias.

## Parte 3 – Integración: avance de configuración

La integración queda a cargo de Luca. Se creó `parte3/` copiando `parte1_4/`
para conservar el ISP ampliado con r7, r8 y la LAN de pcc1. Se cambió la
identificación del laboratorio a `redes-ob2-parte3`.

### Incorporación del Cliente A

Se reemplazó la LAN simple de pca1 por la red de `parte2_4/`: cuatro switches
P4, cuatro PCs de ADMIN, tres de DESARROLLO, tres de INVITADOS y srv1.
Se copiaron los programas `switch.p4`, las tablas `commands.txt` y los archivos
de arranque de switches y hosts. Se conservan las MAC configuradas, el reenvío
Ethernet, la política de INVITADOS y port security. Se retiraron pca1 y su startup.

Las interfaces de rcla quedan así:

| Interfaz | Conexión | Dirección |
|---|---|---|
| eth0 | ADMIN, por p4sw1 | `10.19.0.1/26` |
| eth1 | DESARROLLO, por p4sw2 | `10.19.0.129/25` |
| eth2 | INVITADOS, por p4sw3 | `10.19.2.1/23` |
| eth3 | SERVIDORES, por p4sw4 | `203.0.113.33/27` |
| eth4 | ISP, hacia r3 | `203.0.113.14/30` |

En `rcla.startup` se conserva la salida por defecto hacia r3 (`203.0.113.13`).
Se reemplazó la regla de NAT de la antigua LAN `192.168.100.0/24` por tres
reglas SNAT, una para cada subred privada de A, con salida por eth4 y traducción
a `203.0.113.14`. La red pública de SERVIDORES no se traduce. La regla de NAT de
INVITADOS no elimina las restricciones aplicadas previamente por el switch P4.

Para alcanzar srv1 desde el ISP se agregó en `r3/etc/frr/frr.conf` la ruta
`ip route 203.0.113.32/27 203.0.113.14` y `redistribute static` dentro de OSPF.
Así, r3 entrega los paquetes de esa red a rcla y anuncia el prefijo al backbone.
El anuncio pasivo del enlace público `203.0.113.12/30` se conserva.
En `rint.startup` se agregó el retorno a `203.0.113.32/27` con dos nexthops de
igual peso, vía r1 (`10.255.0.26`) y r6 (`10.255.0.5`), como para los otros
prefijos públicos. rint continúa sin participar en OSPF.

### Primeras pruebas de integración — 10/11/2026

Se inició el laboratorio y se ejecutaron los siguientes comandos en las
terminales de los dispositivos. Los resultados corresponden a las salidas de
consola compartidas durante las pruebas; no se guardaron nuevas capturas pcap
ni archivos de resultados para estas verificaciones.

| Origen | Comando | Resultado observado |
|---|---|---|
| pc_admin1 | `ping -c 4 10.19.0.1` | Gateway de ADMIN: 4 respuestas, 0 % de pérdida. |
| pc_admin1 | `ping -c 4 8.8.8.8` | Internet simulado: 4 respuestas, 0 % de pérdida. |
| pc_dev1 | `ping -c 4 10.19.0.129` | Gateway de DESARROLLO: 4 respuestas, 0 % de pérdida. |
| pc_dev1 | `ping -c 4 8.8.8.8` | Internet simulado: 4 respuestas, 0 % de pérdida. |
| pcint | `ping -c 4 203.0.113.34` | Servidor público de A: 4 respuestas, 0 % de pérdida. |
| pcint | `curl --max-time 5 -I http://203.0.113.34/` | HTTP de srv1: `200 OK`. |
| pc_guest1 | `ping -c 4 10.19.2.1` | Gateway de INVITADOS: 4 respuestas, 0 % de pérdida. |
| pc_guest1 | `curl --max-time 5 -I http://203.0.113.34/` | HTTP de srv1 permitido: `200 OK`. |
| pc_guest1 | `curl -k --max-time 5 -I https://203.0.113.34/` | HTTPS de srv1 permitido: `200 OK`. |
| pc_guest1 | `ping -c 4 10.19.0.2` | ADMIN: ninguna respuesta, 100 % de pérdida, conforme a la política. |
| pc_guest1 | `ping -c 4 8.8.8.8` | Internet simulado: ninguna respuesta, 100 % de pérdida, conforme a la política. |
| pc_admin1 | `curl --max-time 5 -I http://203.0.113.10/` | Acceso desde A al servidor público de B: `200 OK`. |
| pcb1 | `curl --max-time 5 -I http://203.0.113.34/` | Acceso desde B al servidor público de A: `200 OK`. |

En estos comandos, `ping -c 4` envía cuatro solicitudes ICMP. En curl,
`-I` solicita las cabeceras HTTP y `--max-time 5` limita la prueba a cinco
segundos; `-k` permite probar HTTPS con el certificado autofirmado de srv1.

Las pruebas verifican acceso al gateway y salida a Internet simulado desde
ADMIN y DESARROLLO, acceso externo al servidor público de A y acceso HTTP
entre clientes mediante sus servidores públicos. Son consistentes con las
rutas y reglas SNAT configuradas; queda pendiente observar la traducción
directamente mediante contadores o captura de paquetes en este escenario.
No se probó comunicación directa entre las PCs privadas de A y B.

Los resultados de INVITADOS coinciden con los permisos y bloqueos ensayados:
gateway y servicios web de srv1 accesibles, ping a ADMIN y pcint bloqueado.
Esto no constituye todavía una repetición completa de las pruebas de 2.3 ni
una prueba de suplantación de MAC para port security en la integración.

### Ampliación de la LAN de B y pruebas — 10/11/2026

Se agregaron pcb2 y pcb3 al dominio `LAN_B` en `lab.conf` y se crearon sus
archivos de arranque. La LAN queda con tres PCs:

| Host | Dirección | Gateway |
|---|---|---|
| pcb1 | `10.19.0.2/25` | `10.19.0.1` |
| pcb2 | `10.19.0.3/25` | `10.19.0.1` |
| pcb3 | `10.19.0.4/25` | `10.19.0.1` |

No fue necesario modificar SNAT en rclb: la regla existente abarca toda la
LAN `10.19.0.0/25`. Tras reiniciar el laboratorio, se ejecutaron estas pruebas:

| Origen | Comando | Resultado observado |
|---|---|---|
| pcb2 | `ping -c 4 10.19.0.4` | Comunicación con pcb3: 4 respuestas, 0 % de pérdida. |
| pcb2 | `ping -c 4 8.8.8.8` | Internet simulado: 4 respuestas, 0 % de pérdida. |
| pcb3 | `ping -c 4 8.8.8.8` | Internet simulado: 4 respuestas, 0 % de pérdida. |

Los resultados se registran a partir de las salidas de consola compartidas;
no se guardaron nuevas capturas para estas pruebas.

### Traslado y ampliación de la red pública de B — 10/11/2026

La red original `203.0.113.8/30` solo admitía el gateway y srvb. Ampliarla
directamente a `/29` se superpondría con el enlace de A `203.0.113.12/30`.
Se trasladó la DMZ de B al bloque libre `203.0.113.24/29`, conservando una
sola red de servidores sin agregar interfaces ni renumerar las otras redes.

| Elemento | Configuración actual |
|---|---|
| Red pública de servidores de B | `203.0.113.24/29` |
| Gateway rclb, eth2 | `203.0.113.25/29` |
| srvb, eth0 | `203.0.113.26/29`, gateway `203.0.113.25` |
| Direcciones disponibles | `203.0.113.27` a `203.0.113.30` |
| Broadcast | `203.0.113.31` |

El bloque tiene seis direcciones utilizables: una para el gateway y hasta cinco
para servidores. Queda capacidad para el servidor web adicional previsto por
la letra; todavía no se agregó un segundo servidor a la emulación.
La IP de NAT de B sigue siendo `203.0.113.1/32`, sin cambios en la LAN privada.

Además de actualizar `rclb.startup` y `srvb.startup`, se reemplazó la ruta del
prefijo antiguo en `r5/etc/frr/frr.conf` por
`ip route 203.0.113.24/29 203.0.113.6`. El `redistribute static` existente
anuncia el nuevo prefijo por OSPF. En `rint.startup` se actualizó el retorno
a `203.0.113.24/29`, conservando ambos nexthops vía r1 y r6.
Estos cambios se aplicaron únicamente en `parte3/`.

Después de reiniciar el escenario se obtuvieron los siguientes resultados:

| Origen | Comando | Resultado observado |
|---|---|---|
| pcint | `ping -c 4 203.0.113.26` | 4 respuestas, 0 % de pérdida. |
| pcint | `curl --max-time 5 -I http://203.0.113.26/` | HTTP de srvb desde Internet simulado: `200 OK`. |
| pc_admin1 | `curl --max-time 5 -I http://203.0.113.26/` | HTTP de srvb desde A: `200 OK`. |

Las salidas de consola confirman el acceso al servidor después del traslado;
no se guardaron nuevas capturas pcap para estas pruebas. Los resultados
anteriores dirigidos a `203.0.113.10` corresponden a la numeración previa y
se conservan como registro histórico, no como comandos para el estado actual.

### Estado y próximos pasos

La integración básica de A ya fue probada con los resultados anteriores.
Los archivos que actualmente contiene `parte3/shared/` fueron
heredados de la copia de 1.4 y no constituyen evidencia de la Parte 3; incluyen
pruebas con pca1, dispositivo que ya no forma parte de este escenario.

Queda pendiente:

- Guardar consultas explícitas de interfaces, tablas P4, vecinos OSPF,
  anuncio de la red de servidores y rutas de retorno.
- Completar las pruebas internas de A, observar NAT directamente y ampliar
  las comprobaciones de la política de INVITADOS. Repetir las pruebas de
  suplantación de MAC de port security en el escenario integrado.
- Completar las comprobaciones de conectividad tras ampliar B, incluido el
  sentido B hacia el servidor de A, y comprobar la conectividad con la LAN de r8.
- Guardar capturas y resultados propios de integración y documentarlos.

La LAN de r8 conserva por ahora `203.0.113.16/29`, con pcc1 en
`203.0.113.18/29` y sin NAT. Se consultará al profesor si debe convertirse en
una LAN privada con NAT; no se cambió ese diseño en este avance.
Las redes privadas de A y B conservan el solapamiento ya documentado: las
pruebas de acceso entre clientes deben distinguir los servicios públicos de
la comunicación directa entre direcciones privadas.
