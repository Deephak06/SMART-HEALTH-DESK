// @deno-types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Type declaration for Deno global (Supabase Edge Functions runtime)
declare global {
  const Deno: {
    serve: (handler: (req: Request) => Response | Promise<Response>) => void;
  };
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface NotificationRequest {
  user_id: string;
  type: string;
  title: string;
  message: string;
  channel: "sms" | "whatsapp" | "in_app";
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const { user_id, type, title, message, channel }: NotificationRequest = await req.json();

    if (channel === "sms") {
      console.log(`[${type}] SMS Notification to user ${user_id}: ${title} - ${message}`);
    } else if (channel === "whatsapp") {
      console.log(`[${type}] WhatsApp Notification to user ${user_id}: ${title} - ${message}`);
    } else {
      console.log(`[${type}] In-app Notification to user ${user_id}: ${title} - ${message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Notification sent successfully",
        channel: channel,
        type,
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
