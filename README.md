# Obligatorio 2 – 2026 · Laboratorios base (Kathará)

Configuraciones iniciales para el Obligatorio 2 de Redes de Computadoras.
Cada carpeta es un laboratorio Kathará independiente:

| Carpeta | Contenido | Partes |
|---|---|---|
| `parte1/` | Backbone inicial de RíoNet (r1–r6), rint/pcint, Cliente A y Cliente B | 1.1, 1.2, 1.3, 1.5 |
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
`r2`, `r5`, `r6`, `rint`, `rclb`, `pcb1` y `pcint`. Las otras ramas y el
direccionamiento de `srvb` siguen pendientes.

Direcciones actualmente configuradas en `parte1/`:

| Red o uso | Prefijo | Interfaces y direcciones |
|---|---|---|
| LAN B | `10.19.0.0/25` | `rclb eth1: 10.19.0.1`, `pcb1 eth0: 10.19.0.2` |
| Enlace rclb–r5 | `203.0.113.4/30` | `r5 eth4: 203.0.113.5`, `rclb eth0: 203.0.113.6` |
| Enlace r5–r6 | `10.255.0.0/30` | `r5 eth3: 10.255.0.1`, `r6 eth2: 10.255.0.2` |
| Enlace r6–rint | `10.255.0.4/30` | `r6 eth0: 10.255.0.5`, `rint eth2: 10.255.0.6` |
| Enlace r2–r5 | `10.255.0.8/30` | `r5 eth0: 10.255.0.9`, `r2 eth3: 10.255.0.10` |
| Internet simulado | `8.8.8.0/24` | `rint eth0: 8.8.8.1`, `pcint eth0: 8.8.8.8` |
| IP pública de SNAT de B | `203.0.113.1/32` | `rclb lo: 203.0.113.1` |
| LAN A (configuración inicial parcial) | `192.168.100.0/24` | `pca1 eth0: 192.168.100.10`; gateway previsto `192.168.100.1`, aún pendiente en `rcla` |

El enlace cliente–ISP usa direcciones públicas siguiendo la corrección enviada
por los docentes. La IP de SNAT se conserva separada en `lo` de `rclb`.

`r2` tiene una ruta por defecto hacia `r5` (`10.255.0.9`). Para que las
respuestas regresen al enlace `r2–r5`, se agregaron rutas a `10.255.0.8/30`
en `r6` vía `10.255.0.1`, en `rint` vía `10.255.0.5` y en `rclb` vía
`203.0.113.5`. `r5` conoce esa red por estar directamente conectado.

Flujo de trabajo: incorporar un nodo, probar el enlace directo, agregar las
rutas de retorno y probar la conectividad de extremo a extremo.

Pruebas ejecutadas y confirmadas por Luca en el laboratorio:

- Ping del enlace directo entre `r2` y `r5`.
- `r2 → 8.8.8.8`: cuatro respuestas y 0 % de pérdida en la salida compartida.
- `pcb1 → 10.255.0.10` y `pcb1 → 8.8.8.8`: funcionamiento confirmado.
- `pcb1 → 10.255.0.9`: funcionamiento confirmado.

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
