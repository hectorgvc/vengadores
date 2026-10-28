# Origen

Skill propia del vault (2026-07-02, ampliada 2026-10-28). Criterios **adaptados y traducidos**,
no copiados tal cual, de:

- `SNLabat/SEO-GEO-AEO-Skill` — commit `a2c8769` (2026-03-13). **El repo no declara licencia**:
  por eso solo se tomaron criterios de auditoría (checklist SEO/GEO/AEO, escala 1-10, modo
  Rápida/Completa, "no marcar como faltante sin verificar", manejo de sitio inaccesible), con
  redacción propia. No se tomó su generación de DOCX/PDF: usa rutas de Cowork
  (`/sessions/...`), firma de su autor y `npm install -g docx`.
- `AgriciDaniel/claude-seo` — estructura de comandos multi-propósito (`/seo audit|page|…`).

Aportes propios (2026-10-28):

- `scripts/extraer.py` (solo stdlib) + `scripts/test_extraer.py`: HTML crudo vía `curl` en vez de
  depender del resumen de WebFetch, que pierde `<head>` y JSON-LD.
- Chequeo de crawlers de IA en `robots.txt` (búsqueda vs. entrenamiento).
- Detección de SPA sin contenido en HTML (crítico para GEO).
- Cuerpo de los comandos `page`, `geo`, `technical`, `content`, `sitemap` (antes solo listados).
- Comando `implementar` (modo Dev) con plantillas JSON-LD, `robots.txt`, `sitemap.xml`, `llms.txt`.
- Estado real de Google: rich results de FAQ restringidos y HowTo retirados (2023);
  `SpeakableSpecification` en beta solo para noticias.
