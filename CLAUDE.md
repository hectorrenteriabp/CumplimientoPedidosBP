# Contexto de Desarrollo (CLAUDE.md) - BP Cumplimiento

Este archivo contiene las directrices rápidas y los comandos de desarrollo esenciales para trabajar en este proyecto. Para un análisis detallado de la arquitectura de datos, lógica de negocio y pipeline de publicación, consulta el archivo principal de contexto: **[CONTEXTO_DASHBOARD.md](file:///c:/Users/HectorFranciscoRente/Dashboard/OV/Cumplimiento%20Ordenes/CONTEXTO_DASHBOARD.md)**.

## 🛠️ Comandos Esenciales

### Pipeline Completo (Actualizar y Publicar)
- Ejecutar el actualizador automático (orquesta dependencias, servidor local, compilación y push a GitHub Pages):
  ```cmd
  BP_Actualizador.bat
  ```

### Ejecución Manual (Por Partes)
- Levantar el servidor local de persistencia (puerto `5000`):
  ```cmd
  py bp_servidor.py
  ```
- Ejecutar el parser de datos y compilador del dashboard:
  ```cmd
  py BP_Cumplimiento_Actualizador.py
  ```

---

## 🎨 Pautas de Código y Desarrollo

### Python (Procesamiento de Datos)
- **Estilo**: Código limpio, bien documentado y estructurado en bloques secuenciales delimitados por separadores (`# ═════...`).
- **Control de Errores**: Todo guardado de Excel debe realizarse usando `_safe_save(wb, destino)` para evitar fallos catastróficos de escritura si el usuario tiene los archivos Excel abiertos localmente.
- **Fechas**: Usar `parse_fecha_ovsap(val)` para tratar con robustez las fechas ambiguas de SAP (MM/DD/YYYY vs DD/MM/YYYY) y forzarlas a alinearse con la ventana de negocio activa (mes actual y mes siguiente).
- **Seguridad de Credenciales**: El token de GitHub se lee del entorno (`BP_GITHUB_TOKEN`) o del archivo git-ignorado `bp_token.txt`. **NUNCA** hardcodear claves o tokens en los scripts de Python o Batch.

### HTML / CSS / JS (Dashboard)
- **Carga de Datos**: El archivo standalone unificado (`BP_Dashboard_Standalone.html`) se compila inyectando `bp_data.js` en caliente. No alteres los delimitadores `/* SE_DATA_START */` y `/* SE_DATA_END */`.
- **Persistencia local**: El frontend consume y almacena comentarios y embarques manuales mediante peticiones GET y POST al servidor local (`http://127.0.0.1:5000/datos/bp_comentarios.json` y `bp_embarques_manual.json`).
- **Diseño**: Interfaz responsiva y premium dividida en **10 pestañas** de control con micro-animaciones, gráficos dinámicos e indicadores clave (KPIs).

---
*Para una inmersión completa en la lógica de negocio y las asignaciones lógicas de stock, consulta: [CONTEXTO_DASHBOARD.md](file:///c:/Users/HectorFranciscoRente/Dashboard/OV/Cumplimiento Ordenes/CONTEXTO_DASHBOARD.md).*
