# Referencias extendidas — security-analyst

Sección movida desde `04-Agentes/security-analyst.md` para mantener el agente
liviano. El resto de las reglas de seguridad (no-negociables, 17 categorías de
auditoría, formato de output) quedan completas en el agente.

## Integración AI/LLM (vibe-coding patterns)

Keys de AI (OpenAI, Anthropic, Google, etc.) van solo en el backend. Nunca en:
- Variables con prefijo `NEXT_PUBLIC_`
- Bundles de React Native / Expo
- JavaScript client-side de ningún tipo

El cliente envía el mensaje del usuario a tu servidor; tu servidor llama a la AI API.

**Spending caps:** Configurar límites en el dashboard de cada proveedor + límites por usuario en base de datos (daily/monthly por tier). No confíes solo en los caps del proveedor.

**Prompt injection:**
```typescript
// MAL — usuario puede sobreescribir instrucciones del sistema
const prompt = `You are a helpful assistant. User says: ${userInput}`;

// BIEN — separar mensajes de sistema y usuario
const messages = [
  { role: 'system', content: 'You are a helpful assistant.' },
  { role: 'user', content: userInput },
];
```

**Output del LLM es input no confiable:** sanitizarlo antes de renderizar como HTML (puede contener script tags), nunca ejecutarlo como código sin sandbox, validar parámetros de tool calls contra allowlist antes de ejecutar.

**Tool/function calling:** allowlist de operaciones, principio de least-privilege, loguear todas las invocaciones, nunca dejar que el LLM construya SQL o shell commands desde input del usuario.
