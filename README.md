# Fede's Sleep 2.0 — rama de desarrollo

Esta rama prepara una versión familiar con Supabase y Fede AI. La versión 1.0 de `main` permanece intacta.

## Antes de publicar
1. Crea un proyecto en Supabase con una cuenta que controles.
2. En Supabase > SQL Editor, ejecuta `supabase/schema.sql`.
3. En Project Settings > API, copia Project URL y la clave pública publishable/anon.
4. Abre `v2/index.html` y pega esos dos valores en la pantalla de conexión. La clave pública es apta para el navegador si RLS está correctamente configurado. Nunca uses service_role.
5. Para activar Fede AI, despliega la Edge Function `supabase/functions/fede-ai/index.ts` y configura el secreto del servidor:
   `supabase secrets set OPENAI_API_KEY=...`
   La clave de OpenAI nunca se coloca en GitHub Pages ni en el navegador.
6. Laura crea su cuenta, confirma el correo si Supabase lo solicita, inicia sesión y crea el espacio familiar. Luego comparte el código de invitación con David. David crea su propia cuenta e introduce ese código.
7. En GitHub Pages, cuando se haya probado todo, se puede cambiar la fuente de publicación a la rama `v2-development`, carpeta `/ (root)`, pero primero habrá que mover el archivo de `v2/index.html` a la raíz o configurar una publicación desde una carpeta raíz dedicada.

## Alcance y seguridad
- Datos nuevos, sin migración de la versión 1.0.
- Acceso familiar limitado por RLS a miembros de la familia.
- Fede AI consulta solo los registros de la familia autenticada.
- Predicciones observacionales; no diagnóstico ni indicaciones médicas.
- Esta rama es un prototipo de integración. No está lista para uso con datos reales hasta configurar y probar Supabase, correo de confirmación, políticas y función de IA.
