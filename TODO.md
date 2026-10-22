# Continuaci?n del laboratorio ? 22/10/2026

## D?nde retomar

Rama `luk-tests`, escenario `parte1_2/`. `parte1/` conserva el escenario
est?tico de 1.1, ahora con NAT y salida de A y B. No modificar sus archivos
al implementar OSPF. El README contiene el direccionamiento y las evidencias.

?ltimo avance publicado: `e62bf9b`; merge a main: `f4b3baf`.
Este TODO se publica solo en luk-tests, no se mergea a main.

En otra computadora:

```bash
git switch luk-tests
git pull --ff-only origin luk-tests
```

En esta computadora se instal? Kathar? 3.8.3 para Windows con Docker Desktop.
Se trabaja desde PowerShell; no se necesita abrir la VM para desarrollo.
La letra exige ejecutar las pruebas de entrega en la VM provista.

## Forma de trabajar acordada

- Explicar qué requisito resuelve cada cambio y por qué es necesario.
- Luca escribe las configuraciones: no editarlas automáticamente salvo pedido
  explícito. Sí puede pedir edición de documentación y operaciones de Git.
- Dar comandos sencillos y comentarios que expliquen cada bloque.
- Configurar un paso, verificarlo y continuar; no es necesario probar cada
  eliminación de ruta individualmente si una prueba conjunta es suficiente.
- Juntar comandos de aplicación y consulta en un bloque para copiar en consola.
  En los archivos persistentes solo guardar configuración, no consultas.
- Distinguir comandos del anfitrión (`kathara ...`) de los ejecutados dentro
  de un router (`ip ...`, `vtysh ...`, `ping ...`).
- Numerar todo no significa enrutar hacia todas las interfaces. Evitar trabajo
  adicional sin justificarlo por los requisitos. No anticipar la parte 3.
- No activar interfaces pasivas de borde por rutina: explicar primero si son
  necesarias para el diseño elegido. El enlace r5–rclb quedó sin ese anuncio.
- Subir o mergear solo cuando Luca lo pida. Este TODO se publica únicamente
  en `luk-tests`, sin merge a `main`.

## Estado completado

### Parte 1.1

- Backbone numerado y routing est?tico siguiendo el ?rbol documentado.
- B: LAN 10.19.0.0/25, NAT a 203.0.113.1/32, acceso r5-rclb
  203.0.113.4/30 y servidor 203.0.113.10/30, gateway 203.0.113.9.
- A: LAN 192.168.100.0/24, gateway 192.168.100.1, pca1 .10;
  rcla eth0 203.0.113.14/30, r3 eth3 203.0.113.13/30.
  Ruta por defecto de rcla hacia r3 y SNAT a 203.0.113.14.
- Retorno p?blico de A por el ?rbol rint-r6-r5-r2-r1-r3-rcla.
- Pings de A y B a pcint confirmados sin p?rdida tras recrear el escenario.
- Capturas NAT A y B revisadas en parte1/shared/: cada una muestra cuatro
  intercambios completos antes y despu?s de NAT en ambos sentidos.
- Compa?eras preparan diagrama y tablas. El informe lo redacta el grupo;
  declarar uso de IA y poder justificar la configuraci?n.

### Parte 1.2

- OSPF en los nueve enlaces internos de r1-r6, ?rea 0, costo 10 por interfaz,
  router IDs 1.1.1.1 a 6.6.6.6. Puede haber ECMP. Vecinos Full verificados.
- Se simplific? B tras consulta docente: las dos rutas p?blicas a
  203.0.113.1/32 y 203.0.113.8/30 est?n en FRR de r5 v?a 203.0.113.6.
  `redistribute static` las anuncia. Ya no hay prefix-list ni route-map ni
  redistribuci?n kernel. Cualquier futura est?tica en FRR tambi?n se anunciar?.
- r1/r6: rutas por defecto hacia rint (.25 y .6 respectivamente), anunciadas
  con `default-information originate`, sin always. r5 aprendi? e instal?
  la salida OSPF v?a r6 (10.255.0.2), m?trica 10.
- A: default y SNAT copiados a rcla. r3 eth3 anuncia 203.0.113.12/30 como
  interfaz OSPF pasiva; no forma vecinos con rcla. Ruta aprendida en r6,
  m?trica 30 v?a r5. No anunciar las LAN privadas.
- rclb usa default hacia 203.0.113.5. Esto resolvi? el retorno de srvb hacia A.
- Limpieza: quitadas rutas internas est?ticas del backbone, espec?ficas de
  r5/r6 a 8.8.8.0/24, siete espec?ficas de rclb, rutas a LAN privada B de
  r5/r6/rint y cuatro retornos de rint hacia enlaces internos.
- Est?ticas conservadas: acceso p?blico B en FRR de r5, defaults de r1/r6,
  gateways de clientes/hosts y tres retornos p?blicos en rint v?a r6.
- Limitaci?n: rint no corre OSPF y todos los retornos p?blicos van por r6.
  No hay respaldo v?a r1 si falla r6 o su enlace a rint. Registrado y dejado
  para revisar seg?n alcance de los experimentos de fallas; no es un error
  que ida y vuelta usen caminos distintos.
- Tras ?ltima limpieza y recreaci?n, Luca confirm? A/B a 8.8.8.8 con cuatro
  respuestas y 0 % p?rdida; HTTP desde A y pcint a srvb con 200 OK.
- Evidencias en parte1_2/shared/: ospf-arranque-r1-r2.pcap y
  r1-show-ip-ospf-neighbor.txt. PCAP revisada: 40 paquetes, 40.6 s,
  cinco tipos OSPF; TXT posterior: r2/r3 Full/DR y colas cero.
- Captura iniciada desde r1.startup antes de FRR; detenida con
  `kathara exec r1 -- pkill -INT -x tcpdump`. L?nea temporal retirada
  del startup para no sobrescribir el archivo. Consulta show es local,
  no produce paquetes OSPF. No hace falta repetir esa captura por el TXT.

## Pr?ximos pasos de 1.2

1. [ ] Guardar LSDB y forwarding de al menos dos routers (r1 y r5 sugeridos).
   Explicar diferencias entre topolog?a/anuncios y rutas elegidas.
2. [ ] Comprobar caminos A-B y A-Internet y relacionarlos con costos y ECMP.
   Para A-B usar srvb p?blico; SNAT no permite conexiones arbitrarias
   iniciadas desde afuera hacia las PCs privadas.
3. [ ] Completar explicaci?n propia del arranque y estado estable apoyada
   en PCAP y TXT; no generar el informe completo con IA.
4. [ ] Revisar documentaci?n con el grupo, tablas y diagramas; reproducir
   las pruebas de entrega en la VM del curso.
5. [ ] Planificar 1.3 despu?s: ca?da r2-r4, al menos cinco repeticiones,
   capturas en dos enlaces y tiempos de recuperaci?n. Revisar caminos
   y limitaci?n de retorno de rint seg?n extremos/falla elegidos.

## Consultas ?tiles (desde PowerShell en parte1_2)

```powershell
kathara exec r1 -- vtysh -c "show ip ospf neighbor"
kathara exec r1 -- vtysh -c "show ip ospf database"
kathara exec r1 -- vtysh -c "show ip route"
kathara exec r1 -- ip route
```

En FRR, O indica OSPF, > seleccionada y * instalada. Una ruta anunciada
no prueba por s? sola conectividad: siempre hace falta retorno.
