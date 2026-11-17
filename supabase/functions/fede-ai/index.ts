// Supabase Edge Function: fede-ai
// Deploy with: supabase functions deploy fede-ai
// Set secret: supabase secrets set OPENAI_API_KEY=...
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type"};
Deno.serve(async (req) => {
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 try {
  const auth=req.headers.get("Authorization")||"";
  const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_ANON_KEY")!,{global:{headers:{Authorization:auth}}});
  const {data:{user},error:authErr}=await supabase.auth.getUser();
  if(authErr||!user) return Response.json({error:"Inicia sesión para continuar."},{status:401,headers:cors});
  const {data:membership,error:mErr}=await supabase.from("family_members").select("family_id").eq("user_id",user.id).single();
  if(mErr||!membership) return Response.json({error:"No tienes un espacio familiar configurado."},{status:403,headers:cors});
  const {question}=await req.json();
  if(typeof question!=="string"||question.trim().length<2||question.length>1200) return Response.json({error:"Escribe una pregunta válida."},{status:400,headers:cors});
  const {data:entries,error:eErr}=await supabase.from("entries").select("kind,occurred_at,ended_at,details").eq("family_id",membership.family_id).order("occurred_at",{ascending:false}).limit(100);
  if(eErr) throw eErr;
  const apiKey=Deno.env.get("OPENAI_API_KEY");
  if(!apiKey) return Response.json({error:"La IA aún no está configurada. Falta añadir OPENAI_API_KEY como secreto del servidor."},{status:503,headers:cors});
  const prompt="Eres Fede AI, un asistente amable para ayudar a una familia a observar registros de cuidado de un bebé. Usa solo los datos proporcionados; si no hay suficientes datos, dilo claramente y no inventes tendencias ni predicciones exactas. Puedes describir patrones observacionales, nunca diagnosticar ni atribuir causalidad médica. No recomiendes retrasar ni limitar la lactancia. No sustituyas al pediatra. Si se menciona fiebre de 38 °C o más en un bebé menor de 3 meses, dificultad respiratoria, coloración azulada, decaimiento importante o rechazo de tomas, indica valoración médica urgente. Distingue datos observados de hipótesis. Responde en español, con calidez y brevedad.";
  const ai=await fetch("https://api.openai.com/v1/responses",{method:"POST",headers:{"Authorization":"Bearer "+apiKey,"Content-Type":"application/json"},body:JSON.stringify({model:"gpt-4.1-mini",input:[{role:"system",content:prompt},{role:"user",content:"Registros recientes (JSON): "+JSON.stringify(entries)+"\n\nPregunta de la familia: "+question}]})});
  const result=await ai.json();
  if(!ai.ok) return Response.json({error:"El servicio de IA no pudo responder en este momento."},{status:502,headers:cors});
  const answer=result.output?.flatMap((o:any)=>o.content||[]).filter((c:any)=>c.type==="output_text").map((c:any)=>c.text).join("\n")||"No pude generar una respuesta.";
  return Response.json({answer},{headers:{...cors,"Content-Type":"application/json"}});
 } catch(e) { return Response.json({error:"Ocurrió un error al procesar la consulta."},{status:500,headers:cors}); }
});
