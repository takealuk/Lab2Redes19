# Obligatorio 2 – 2026 · Laboratorios base (Kathará)

Configuraciones iniciales para el Obligatorio 2 de Redes de Computadoras.
Cada carpeta es un laboratorio Kathará independiente:

| Carpeta | Contenido | Partes |
|---|---|---|
| `parte1/` | Escenario estático de RíoNet, con NAT de B y servidor público | 1.1 |
| `parte1_2/` | Copia de `parte1/` con OSPF habilitado en los enlaces internos de r1–r6; trabajo en curso | 1.2 |
| `parte1_4/` | Igual a `parte1/` más los routers r7 y r8, **sin enlaces ni direccionamiento** | 1.4 |
| `parte2/` | LAN del Cliente A con los switches P4 | 2.1 – 2.4 |

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
de retorno en rint. Este último no ejecuta OSPF y conserva los retornos
de A y B vía r6: no tiene retorno de respaldo si falla r6 o su enlace a rint.

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

**Pendiente para completar 1.2:** guardar y comparar LSDB y forwarding de
al menos dos routers; comprobar los caminos A–B (usando srvb como destino
público) y A–Internet, relacionándolos con los costos y posibles alternativas
de igual costo; y completar la explicación propia de las evidencias.

Para ejecutar esta copia, detener primero el laboratorio anterior desde su
carpeta con `kathara lclean`; luego ejecutar `kathara lstart` desde `parte1_2/`.
Para aplicar cambios de archivos en la copia ya activa, usar `kathara lrestart`
desde `parte1_2/`. La captura de NAT de 1.1 se conserva únicamente en
`parte1/shared/nat-b.pcap` y `parte1/shared/nat-a.pcap`; las evidencias OSPF
de 1.2 están en `parte1_2/shared/`.

### Parte 1.4 – `parte1_4/`
Igual a `parte1/`, más `r7` y `r8` (`kathara/frr`, con ospfd habilitado y
`frr.conf` vacío). Se declaran en `lab.conf` sin interfaces: el grupo debe
agregar los enlaces, la nueva LAN de cliente en r8 y el direccionamiento.

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

Ningún host tiene dirección IP: la numeración es parte del Entregable 2.1.
**srv1** inicia Apache con HTTP (80) y HTTPS (443, certificado autofirmado).

### Switches P4

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
