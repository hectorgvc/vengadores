---
name: changelog-generator
description: Genera changelogs user-facing desde el historial de git. Analiza commits, categoriza cambios y transforma lenguaje técnico en notas de release que los usuarios entienden. Invocar cuando el usuario pide release notes, changelog, o notas de versión.
user-invocable: true
---

Transformás commits técnicos en un changelog polished, orientado al usuario final.

## Proceso

1. **Determiná el rango.** Si el usuario especificó fechas, versión o commit, usá eso. Si no, pedí el punto de partida (tag, rama, fecha, o `HEAD~N`).

2. **Leé el historial:**
   ```bash
   git log <desde>..HEAD --oneline --no-merges
   ```

3. **Filtrá ruido:** excluí commits de refactoring interno, tests, CI, linting, bumps de versión y mensajes de merge. Quedáte con lo que impacta al usuario.

4. **Categorizá los cambios:**
   - **Nuevas funcionalidades** — features que el usuario puede usar
   - **Mejoras** — features existentes mejoradas (performance, UX, etc.)
   - **Correcciones** — bugs resueltos que afectaban al usuario
   - **Breaking changes** — cambios que rompen compatibilidad (si los hay, al tope)
   - **Seguridad** — parches de seguridad (si los hay, al tope)

5. **Traducí a lenguaje de usuario.** `fix(auth): handle JWT expiry edge case` → "Corregido cierre de sesión inesperado al expirar el token". Foco en qué gana el usuario, no en qué cambió en el código.

6. **Generá el changelog** con el formato de abajo.

## Formato de salida

```markdown
# Changelog — v{versión} / {fecha}

## Breaking Changes  ← solo si hay, siempre al tope

- Descripción del cambio y qué debe hacer el usuario para adaptarse

## Nuevas funcionalidades

- **Nombre de feature**: descripción breve orientada al beneficio para el usuario.

## Mejoras

- Descripción de la mejora y qué nota el usuario.

## Correcciones

- Descripción del bug corregido en términos del síntoma, no de la causa técnica.

## Seguridad  ← solo si hay
```

## Reglas de escritura

- Cada ítem en una línea. Si necesita más contexto, máximo dos líneas.
- Verbos en pasado: "Corregido", "Mejorado", "Agregado", "Eliminado".
- Sin jerga técnica (no `refactor`, `migration`, `PR`, `commit`, nombres de funciones).
- Si un commit no tiene impacto visible para el usuario, no aparece.
- Si el repo tiene `CHANGELOG_STYLE.md` o guía de estilo, seguila por encima de estas reglas.

## Al terminar

Preguntá si el usuario quiere:
- Guardar en `CHANGELOG.md` (append al tope)
- Copiar como release notes de GitHub/GitLab
- Ajustar el tono o alguna categoría
