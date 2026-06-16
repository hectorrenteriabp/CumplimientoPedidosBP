# Berries Paradise — Dashboard de Cumplimiento de Órdenes

## Descripción General
Sistema de control de cumplimiento de pedidos (OVs) contra inventario disponible para una empresa de berries.
Monitorea stock en cámaras frías (coolers), propone traslados logísticos, rastrea embarques y publica resultados en la web.

**Owner:** Hector Francisco Renteria Magallanes  
**Usuarios:** Equipo operativo Berries Paradise (~5 usuarios con roles)

---

## Arquitectura: Modelo Dual de Despliegue

### Modo A — Pipeline Local (Primario)
1. `BP_Actualizador.bat` orquesta todo
2. Arranca `bp_servidor.py` (puerto 5000) como servidor de persistencia local
3. Ejecuta `BP_Cumplimiento_Actualizador.py` que:
   - Parsea `Semaforo.pdf` → inventario PT + Granel
   - Carga `Cumplimiento BP.xlsx` → órdenes, planes, coolers
   - Calcula cobertura stock vs pedidos
   - Genera `bp_data.js` (objeto global `D`)
   - Inyecta datos en `BP_Dashboard_Standalone.html` (entre marcadores `/* SE_DATA_START */` y `/* SE_DATA_END */`)
   - Guarda snapshots diarios en `historico/`
   - Git push --force a GitHub Pages

### Modo B — Pipeline Cloud (Next.js + Vercel)
1. Next.js app sirve `public/dashboard.html` como ruta raíz
2. `/api/datos` → CRUD a Supabase tabla `cloud_config` (key → JSON value)
3. `/api/actualizar` → Función serverless Python (Flask)
4. Parsers client-side (`excelParser.js`, `pdfParser.js`) para carga desde navegador
5. Persistencia redundante: Supabase + localStorage como fallback

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Procesamiento | Python 3.11 (pandas, openpyxl, pdfplumber) |
| Persistencia Local | Python http.server (puerto 5000, CORS, JSON whitelist) |
| Frontend | Vanilla HTML/CSS/JS, 10 tabs, autocontenido |
| Cloud Framework | Next.js 14 (App Router), React 18 |
| Base de Datos Cloud | Supabase (PostgreSQL) — tabla `cloud_config` |
| Hosting Cloud | Vercel (Hobby) — funciones serverless Python (Flask) |
| Despliegue Local | GitHub Pages (auto-push desde .bat) |
| Parsers Client | SheetJS (xlsx), pdf.js |

---

## Estructura de Archivos Clave

```
📁 Cumplimiento Ordenes/
├── BP_Actualizador.bat                 # Orquestador principal (Windows batch)
├── BP_Cumplimiento_Actualizador.py     # Procesador Python (4700+ líneas)
├── bp_servidor.py                      # Servidor local persistencia (puerto 5000)
├── bp_data.js                          # Datos generados (objeto D, ~1.3MB)
├── BP_Dashboard_Cumplimiento.html      # Template HTML del dashboard
├── BP_Dashboard_Standalone.html        # Dashboard producción autocontenido (1.7MB)
├── index.html                          # Redirect con cache-busting
├── Cumplimiento BP.xlsx                # Input: OVs de SAP
├── Semaforo.pdf                        # Inventario SAP (PT + Granel)
├── historico/                          # Snapshots diarios (YYYY-MM-DD.json)
│
└── web-dashboard/                      # Dashboard Cloud (Next.js)
    ├── app/
    │   ├── route.js                    # Raíz → sirve dashboard.html
    │   └── api/datos/route.js          # CRUD Supabase (GET/POST cloud_config)
    ├── api/
    │   ├── index.py                    # Flask serverless: /api/ping, /api/actualizar
    │   └── actualizador.py             # Procesador Python para serverless
    ├── public/
    │   └── dashboard.html              # Dashboard compilado (481KB)
    └── utils/
        ├── excelParser.js              # Parser Excel client-side
        └── pdfParser.js                # Parser PDF client-side
```

---

## Variables de Entorno Críticas

### Supabase (en Vercel → Settings → Environment Variables)
- `NEXT_PUBLIC_SUPABASE_URL` — URL del proyecto Supabase
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` — Clave JWT anónima

### Supabase: Tabla `cloud_config`
```sql
CREATE TABLE cloud_config (
  key TEXT PRIMARY KEY,
  value JSONB
);

-- RLS habilitado con política pública para anon
ALTER TABLE cloud_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permitir todo a la app"
  ON cloud_config FOR ALL TO anon
  USING (true) WITH CHECK (true);
```

### Otros
- `BP_GITHUB_TOKEN` — PAT de GitHub (desde `bp_token.txt`, NUNCA hardcodeado)
- `BP_AUTORIZADO=1` — Salta prompts interactivos del .bat

---

## Tabs del Dashboard (10)
1. 📊 **Resumen** — KPIs, % cumplimiento, conteos
2. 📋 **Plan del Día** — Detalle por línea de OV
3. 📦 **Inventario** — Producto terminado en coolers
4. 🚚 **Traslados** — Propuestas automáticas de transferencia entre almacenes
5. 🫐 **Fruta Disponible** — Inventario por tipo (Blueberry, Blackberry, Raspberry, Strawberry)
6. 🏭 **Fruta a Granel** — Kilos y pallets en proceso
7. 🚛 **Embarques** — Control de embarques y consolidación de transporte
8. ✅ **Cumplimiento** — Análisis cuantitativo por cliente/destino/variedad
9. 🚦 **Sem. Embarques** — Semáforo visual de preparación de embarques
10. 📈 **Histórico** — Gráficas de tendencias desde snapshots

---

## Sistema de Usuarios y Roles

### 3 niveles de rol
- **administrador** — Acceso total, puede crear/eliminar usuarios, cambiar roles
- **usuario** (editor) — Puede editar planes, embarques, comentarios
- **solo_vista** — Solo lectura, no puede modificar nada

### Archivos de persistencia (en Supabase cloud_config)
- `bp_users.json` — Lista de usuarios [{name, username, password, role}]
- `bp_comentarios.json` — Comentarios del semáforo
- `bp_embarques_config.json` — Configuración de embarques manuales
- `bp_bitacora.json` — Auditoría de acciones (via `registrarAccionBitacora()`)
- `bp_overrides.json` — Sobreescrituras de cooler, prioridad, cajas

---

## Reglas Críticas de Desarrollo

1. **Seguridad Excel:** Siempre usar `_safe_save(wb, destino)` para manejar archivos bloqueados
2. **Parseo de Fechas:** Usar `parse_fecha_ovsap(val)` para fechas ambiguas de SAP (MM/DD vs DD/MM)
3. **Marcadores de Inyección:** NUNCA alterar `/* SE_DATA_START */` y `/* SE_DATA_END */`
4. **Credenciales:** Token desde env o `bp_token.txt` — NUNCA hardcodear
5. **Whitelist API:** Nuevos archivos JSON deben agregarse a `ARCHIVOS_PERMITIDOS` en `bp_servidor.py`
6. **Persistencia:** Dual — Supabase cloud + localStorage como fallback
7. **Overrides:** Motor de merge sin pérdida — clonar `D_ORIGINAL`, aplicar overrides encima, nunca mutar baseline
8. **Estilo Visual:** Diseño premium "Héctor Premium" — paleta verde corporativa, glassmorphism, micro-animaciones
9. **Auditoría:** Toda mutación se registra via `registrarAccionBitacora()` en `bp_bitacora.json`

---

## Flujo de Datos del Objeto `D`

```
Cumplimiento BP.xlsx ──→ BP_Cumplimiento_Actualizador.py ──→ bp_data.js (var D = {...})
Semaforo.pdf          ──┘                                      │
                                                               ↓
                                              BP_Dashboard_Standalone.html
                                              (inyectado entre SE_DATA markers)
```

### Estructura principal de `D`:
```js
D = {
  meta: { today, coolers:{code:nombre}, actualizado, version },
  plan_dia: [...],        // Líneas del plan diario
  inventario_pt: [...],   // Inventario producto terminado
  inventario_granel: [...],// Inventario granel (kilos, pallets)
  ordenes: [...],         // Órdenes de venta
  cumplimiento_sap: [...],// Cumplimiento calculado
  embarques: [...],       // Embarques del día
  traslados: [...],       // Propuestas de traslado
  semaforo: [...]         // Estado de semáforo embarques
}
```

---

## Comandos Esenciales

```cmd
# Pipeline completo (actualizar datos + publicar GitHub Pages)
BP_Actualizador.bat

# Servidor local de persistencia
py bp_servidor.py

# Procesador de datos manual
py BP_Cumplimiento_Actualizador.py

# Dashboard cloud (desarrollo)
cd web-dashboard && npm run dev

# Desplegar a Vercel (desde web-dashboard/)
vercel --prod
```

---

## URLs de Producción
- **GitHub Pages:** https://hectorrenteriabp.github.io/CumplimientoPedidosBP/
- **Vercel Cloud:** https://web-dashboard-ten-sand.vercel.app

---

## Estado Actual y Pendientes

### ✅ Completado
- Pipeline local completo con publicación automática a GitHub Pages
- Dashboard cloud en Vercel con Supabase para persistencia
- Sistema de login con 3 roles (admin, editor, solo_vista)
- Bitácora de auditoría
- Snapshots históricos diarios
- Carga manual de OVs por fecha
- Motor de overrides sin pérdida (cooler, prioridad, cajas)
- Tarjetas de embarque con compartir vía WhatsApp

### ⚠️ Verificar
- Políticas RLS de Supabase aplicadas correctamente para crear/eliminar usuarios
- Cambio de contraseña de usuarios (no implementado aún)

---

## Documentación Relacionada
- `CLAUDE.md` — Guías rápidas de desarrollo
- `CONTEXTO_DASHBOARD.md` — Arquitectura detallada
- `REGLAS_MEMORIA_MIGRACION_BP.md` — Playbook de migración a otros sistemas BP
- `Manual_Dashboard_BP.docx` — Manual de usuario
- `Novedades_Dashboard_BP.docx` — Notas de versión
