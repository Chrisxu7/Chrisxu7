# Oficina Virtual DEMO · Hermes3D

Oficina virtual de demostración construida sobre
[Hermes3D](https://github.com/iamlukethedev/Hermes3D): una oficina en 3D / 2D
pixel-art donde los agentes de IA aparecen como trabajadores que se mueven,
se sientan en sus mesas y responden por chat.

**Es una DEMO**: no hay ningún modelo de IA conectado. Un gateway simulado
(`gateway/oficina-demo-gateway.js`) responde en español con mensajes
predefinidos para poder explorar la oficina sin instalar nada más.

![Oficina virtual](docs/oficina-virtual-demo.png)

## El equipo

| Agente | Rol | |
|---|---|---|
| Lucía | Directora | 🧭 |
| Mateo | Investigación | 🔎 |
| Sofía | Desarrollo | 🛠️ |
| Diego | Diseño | 🎨 |
| Valentina | QA | ✅ |

Para cambiar nombres, roles o respuestas edita [`gateway/equipo.json`](gateway/equipo.json)
y reinicia el script. También puedes añadir agentes desde el botón **ADD** de la
oficina (se pierden al reiniciar, porque la demo no guarda nada).

## Cómo arrancarla

Requisitos: **Node.js 22** (mínimo 20), **npm** y **git**.

```bash
./scripts/oficina-demo.sh
```

La primera vez el script:

1. Descarga Hermes3D (commit fijado) en `.hermes3d/`.
2. Instala sus dependencias y lo compila (tarda unos minutos).
3. Arranca el gateway demo en `ws://localhost:18789`.
4. Arranca Hermes3D Studio en <http://localhost:3000>, ya conectado al gateway en modo **Demo**.

Abre <http://localhost:3000/office>. Las siguientes veces arranca en segundos.
`Ctrl+C` cierra todo.

Opciones:

- `--rebuild` recompila Hermes3D (por ejemplo, tras cambiar `HERMES3D_REF`).
- `--dev` usa el modo desarrollo de Next.js (para tocar el código de Hermes3D).
- Variables: `PORT` (Studio, 3000), `DEMO_ADAPTER_PORT` (gateway, 18789),
  `OFICINA_NOMBRE`, `OFICINA_EQUIPO` (otro JSON de equipo), `HERMES3D_REF`.

## Uso rápido

- La primera vez aparece el asistente de bienvenida de Hermes3D: ciérralo con la **X**
  (la conexión ya está hecha; arriba a la derecha verás `DEMO • CONNECTED`).
- **CHAT** (abajo a la derecha) o clic en un agente para hablar con él. Prueba con "Hola".
- Botón **3D / 2D PIXEL** de la barra superior para cambiar de vista.
- **OPEN HQ**, **MARKETPLACE** y **ANALYTICS** en el lateral derecho.

![Chat con Lucía](docs/oficina-chat.png)

## Pasar de DEMO a agentes reales

Cuando quieras agentes de verdad, sustituye el gateway demo por el adaptador de
Hermes (`npm run hermes-adapter` dentro de `.hermes3d/`) o por un runtime
propio. Consulta el [README de Hermes3D](https://github.com/iamlukethedev/Hermes3D#quick-start)
y su [tutorial](https://github.com/iamlukethedev/Hermes3D/blob/main/TUTORIAL.md).

## Créditos

Hermes3D es © 2026 Luke The Dev, licencia MIT. `gateway/oficina-demo-gateway.js`
es una adaptación de su `server/demo-gateway-adapter.js` (misma licencia).
