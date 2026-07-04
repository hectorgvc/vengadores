# Prompt de instalación guiada por IA
# Para instalación 100% nueva. Pegar tal cual en Claude Code, en cualquier
# carpeta. La IA clona el repo, corre el setup y hace el onboarding sola.
# Fuente de verdad del bloque "Prompt (recomendado)" en index.html —
# si se edita acá, sincronizar también ahí.

Quiero instalar el sistema Vengadores (agentes + skills de Claude Code) en
esta máquina. Encargate vos de todo el proceso — yo no voy a tocar la
terminal, así que usá tus herramientas y contame qué vas haciendo en cada
paso.

Antes de instalar nada, preguntame en el chat (sí/no):
1. ¿Instalo las skills de GeneXus? (solo si trabajás con esa plataforma,
   ~9MB extra)
2. ¿Instalo los git guardrails? (bloquean comandos destructivos como
   push --force o reset --hard antes de ejecutarlos)

Con mis respuestas, hacé esto:

1. Verificá que git esté instalado (git --version). Si falta, explicame
   cómo instalarlo y parate ahí.
2. Cloná el repo en ~/vengadores (si la carpeta ya existe, hacé
   git -C ~/vengadores pull en vez de clonar de nuevo):
   git clone https://github.com/hectorgvc/vengadores.git ~/vengadores
3. Detectá mi sistema operativo y corré el setup sin pedirme que lo haga yo
   a mano, pasándole mis respuestas por stdin en este orden (confirmar
   instalación, GeneXus, guardrails):
   - Linux/macOS/WSL2:
     chmod +x setup.sh && printf 'S\n<respuesta-genexus>\n<respuesta-guardrails>\n' | ./setup.sh
   - Windows (PowerShell):
     "S`n<respuesta-genexus>`n<respuesta-guardrails>" | .\setup.ps1
4. Cuando termine, leeme el resumen que imprime el script (vault, agentes,
   skills instaladas).
5. Ejecutá vos mismo la skill jarvis ahora mismo para hacerme la entrevista
   de onboarding y generar mi CLAUDE-global.md — no esperes a que te lo
   pida.
6. Cerrá con un resumen corto: dónde quedó el vault, cuántos agentes y
   skills quedaron activos, y cuál es el próximo paso (crear mi primer
   proyecto con ./nuevo-proyecto.sh "Nombre" /ruta/al/repo).

Si algo falla (falta git, sin permisos, sin internet), explicámelo en
español simple y decime exactamente qué tengo que resolver antes de
reintentar.
