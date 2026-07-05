# Prompt de actualización guiada por IA
# Para una instalación que YA existe y solo necesita ponerse al día con
# los últimos cambios del repo. Pegar tal cual en Claude Code.
# Fuente de verdad del bloque "Actualización" en index.html — si se
# edita acá, sincronizar también ahí.

Quiero actualizar mi instalación del sistema Vengadores a la última
versión del repo. Encargate vos — yo no voy a tocar la terminal.

1. Si existe ~/vengadores y es un repo git, entrá ahí. Si no existe,
   cloná primero:
   git clone https://github.com/hectorgvc/vengadores.git ~/vengadores

2. Desde ~/vengadores, corré el script de actualización según mi sistema
   operativo:
   - Linux/macOS/WSL2: chmod +x update.sh && ./update.sh
   - Windows (PowerShell): .\update.ps1

   Este script actualiza los agentes y skills que ya tenía instalados
   (sobreescribe su contenido con la versión del repo), agrega lo que sea
   nuevo, y limpia cualquier skill renombrada u obsoleta. No toca mi vault
   más allá de 03-Skills/ — mis proyectos y notas quedan intactos.

3. Leeme el resumen que imprime el script: qué agentes se actualizaron,
   qué skills son nuevas, y si hubo alguna migración (por ejemplo,
   renombres de skills).

4. Si el resumen menciona que una skill fue renombrada o reemplazada,
   decime el nombre nuevo y cómo invocarla de ahora en más.

5. Si algo falla (el repo no existe, sin permisos, sin internet),
   explicámelo en español simple y decime exactamente qué tengo que
   resolver antes de reintentar.

No hace falta que repitas el onboarding (jarvis) a menos que yo te lo
pida explícitamente — mi perfil ya está configurado.
