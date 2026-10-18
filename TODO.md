# Continuación del laboratorio — 18/10/2026

## Dónde retomar

Trabajamos en la rama `luk-tests`, en `parte1_2/`. `parte1/` conserva la
configuración estática de 1.1 y no debe modificarse al implementar 1.2.
Este documento resume el contexto técnico; no es una transcripción del chat.

En otra computadora, clonar el repositorio si hace falta y ejecutar:

```bash
git switch luk-tests
git pull --ff-only origin luk-tests
```

Levantar únicamente el escenario que se está probando. Antes de iniciar la
copia, detener el laboratorio anterior desde su carpeta. Todas las pruebas
penden del entorno Kathará donde se ejecute el laboratorio.

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

- Backbone y enlaces numerados; árbol utilizado para routing estático documentado
  en README. No se agregaron rutas para hacer accesibles todas las interfaces
  de los enlaces fuera del árbol desde B.
- B: LAN `10.19.0.0/25`, gateway `.1`, PC `.2`.
- Enlace B–ISP: r5 eth4 `203.0.113.5/30`, rclb eth0 `203.0.113.6/30`.
- SNAT de B a `203.0.113.1/32`, configurada en loopback de rclb.
- Servidor B: srvb `203.0.113.10/30`, gateway rclb eth2 `203.0.113.9/30`.
  Ping y HTTP desde pcint y salida de B comprobados, también tras reiniciar.
- A solo numerado en 1.1: r3 eth3 `203.0.113.13/30`, rcla eth0
  `203.0.113.14/30`; LAN A `192.168.100.0/24`, rcla eth1 `.1`, pca1 `.10`.
  Pings directos confirmados. Sin NAT ni salida de A en 1.1.
- `parte1/shared/nat-b.pcap` revisada: cuatro intercambios ICMP completos,
  con origen privado `10.19.0.2` antes de NAT y público `203.0.113.1` después,
  y traducción inversa de respuestas. No está duplicada en `parte1_2`.
- Compañeras se encargan de diagrama y tablas. El informe y las instrucciones
  finales se cerrarán con esos materiales. Declarar uso de IA según la letra;
  comprender y justificar lo entregado. No generar el informe completo con IA.

### Parte 1.2

- Copia independiente `parte1_2/`, conservando IP y servicios.
- OSPF activo en ambos extremos de los nueve enlaces entre r1–r6.
- Una sola área `0.0.0.0`, costo 10 en cada interfaz interna, router ID
  `1.1.1.1` hasta `6.6.6.6`. Igual costo favorece menos enlaces; puede haber ECMP.
- Vecinos esperados confirmados en Full: r1=2, r2=4, r3=3, r4=3, r5=4, r6=2.
- Retiradas las rutas estáticas internas heredadas de 1.1. En r1 se verificaron
  rutas OSPF instaladas y ping a r6 `10.255.0.2` sin pérdida tras reinicio.
- r5 anuncia exclusivamente NAT B `203.0.113.1/32` y servidor B
  `203.0.113.8/30`, con prefix-list PUBLICOS_B y route-map ANUNCIAR_B permit 1.
- Se usa `redistribute kernel route-map ANUNCIAR_B`: las rutas se crearon
  con `ip route add` en Linux, no como rutas static dentro de FRR.
- El filtro evita anunciar la LAN privada de B o la ruta a Internet de r5.
  El número 1 del route-map es orden de regla, no costo; se conserva explícito.
- Sin métrica ni tipo explícitos, se observaron LSAs externos tipo 2, métrica 20,
  originados por `5.5.5.5`. En r1 ambos prefijos se instalaron por OSPF con
  siguientes saltos por r2 y r3. Se eliminaron las dos rutas estáticas públicas
  equivalentes en r6 y se verificó su reemplazo por OSPF vía r5.
- Las rutas de r5 hacia esos destinos por rclb permanecen: el cliente no corre
  OSPF y r5 necesita esas rutas para alcanzar los prefijos que anuncia.
- Último merge antes de este TODO: main `1bf6f69`; commit de avance en
  luk-tests `afb4345`. Este TODO tendrá su propio commit posterior.

## Próximos pasos de 1.2

1. [ ] Configurar salida a Internet en r1 y r6: rutas por defecto estáticas
   hacia sus interfaces vecinas de rint. r1 usa el enlace `10.255.0.24/30`
   (rint `.25`, r1 `.26`); r6 usa `10.255.0.4/30` (rint `.6`, r6 `.5`).
2. [ ] Anunciar esas salidas por defecto por OSPF y verificar su instalación
   en el resto del backbone. Justificar costos y elección de salida.
3. [ ] Después de verificar, retirar la ruta específica de r5 a `8.8.8.0/24`
   por r6. Reemplazar la específica de r6 por su salida por defecto.
4. [ ] Completar rcla: ruta por defecto hacia r3 `203.0.113.13` y SNAT de
   `192.168.100.0/24` a la IP pública existente `203.0.113.14`.
5. [ ] Elegir y justificar cómo anunciar desde r3 el destino público de A
   (por ejemplo, su subred de acceso como pasiva si se adopta ese diseño).
   Asegurar retorno desde rint. Aún no hay implementación acordada.
6. [ ] Revisar estáticas restantes de r5, r6 y bordes. Quitar las heredadas
   innecesarias; conservar las de acceso necesarias en equipos sin OSPF.
   No anunciar LAN privadas. No borrar todas las estáticas indiscriminadamente.
7. [ ] Probar A–Internet, B–Internet, A–servidor público B y pcint–srvb.
   Para A–B se planteó usar el servidor público: SNAT no permite iniciar
   conexiones arbitrarias desde afuera a PCs privadas. Justificar los extremos.
8. [ ] Capturar mensajes OSPF durante arranque/sincronización. Aún no hay
   captura OSPF guardada; planificar la captura antes del experimento.
9. [ ] Mostrar LSDB y forwarding de al menos dos routers y explicar diferencias.
10. [ ] Determinar caminos A–B y A–Internet observados y relacionarlos con costos.
11. [ ] Actualizar README con verificaciones reales y cerrar documentación con
    el equipo. No afirmar que una prueba se ejecutó sin evidencia o confirmación.

## Verificaciones útiles dentro de los routers

```bash
vtysh -c "show ip ospf neighbor"
vtysh -c "show ip ospf route"
vtysh -c "show ip ospf database"
vtysh -c "show ip ospf database external"
vtysh -c "show ip route"
ip route
```

FRR calcula y comparte rutas; Linux reenvía paquetes. `O` identifica rutas
OSPF en FRR, `>` seleccionadas y `*` instaladas. Se comprobó E2 métrica 20
para los prefijos públicos de B. Un anuncio instalado no prueba por sí solo
conectividad completa: hace falta camino de vuelta.
