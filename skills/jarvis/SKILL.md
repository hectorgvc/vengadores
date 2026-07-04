---
description: >
  Conduce la entrevista de onboarding para un usuario nuevo del
  sistema Team. Activar cuando alguien instale el vault por primera
  vez, o cuando diga: "quiero reconfigurar mi perfil", "actualiza
  mi contexto", "cambié de trabajo", "tengo un stack nuevo".
  Genera mi-perfil.md y CLAUDE-global.md desde las respuestas.
depends_on: []
---

# Jarvis

## Instrucciones

1. Explicar brevemente al usuario qué va a pasar: una entrevista
   corta para definir su perfil. Las respuestas se guardan en
   mi-perfil.md y generan CLAUDE-global.md.

2. Hacer las preguntas por bloques, una a la vez, en conversación
   natural — no como formulario. Los bloques son:
   - Bloque 1: Identidad y contexto
   - Bloque 2: Stack técnico
   - Bloque 3: Entorno y conectividad
   - Bloque 4: Preferencias con Claude
   - Bloque 5: Seguridad y reglas

3. Al terminar, mostrar un resumen del perfil y pedir confirmación.

4. Si el usuario confirma:
   a. Escribir/sobreescribir mi-perfil.md con las respuestas.
   b. Generar/regenerar CLAUDE-global.md desde mi-perfil.md.
   c. Informar que el perfil está activo y que puede decir
      "actualiza mi perfil" en cualquier momento para repetir
      el proceso.

5. No inventar respuestas. Si una pregunta no aplica, marcarlo
   en mi-perfil.md como "N/A — {{razón}}" en vez de dejarlo vacío.
