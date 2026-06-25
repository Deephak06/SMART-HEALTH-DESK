// @deno-types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Cursor/TS may not pick up Deno globals in this repo; ensure editor doesn't error.
// Runtime is Supabase Edge (Deno), so `Deno` will exist there.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const Deno: any;

// Admin: delete a user
// - Validates caller is admin (profiles.role == 'admin')
// - Deletes Supabase Auth user by id (triggers cascade to profiles/patients/doctors)

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

interface DeleteUserBody {
  userId: string;
}

// @ts-ignore - Supabase Edge runtime provides `Deno`.
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ success: false, error: "Method not allowed" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
    if (!token) {
      return new Response(JSON.stringify({ success: false, error: "Missing bearer token" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log('[admin-delete-user] received', {
      method: req.method,
      tokenPresent: !!token,
    });

    const supabaseUrl = Deno.env.get("SUPABASE_URL") as string | undefined;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") as string | undefined;
    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ success: false, error: "Server misconfiguration" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const serviceHeaders = {
      Authorization: `Bearer ${serviceRoleKey}`,
      apikey: serviceRoleKey,
    };

    // Verify caller: get user from GoTrue using the provided access token.
    const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        Authorization: `Bearer ${token}`,
        apikey: serviceRoleKey,
      },
    });
    console.log('[admin-delete-user] userRes', { status: userRes.status, ok: userRes.ok });
    const userJson = await userRes.json().catch(() => null);
    const callerId: string | undefined = userJson?.id ?? userJson?.user?.id ?? userJson?.data?.user?.id;

    if (!userRes.ok || !callerId) {
      const msg = userJson?.error_description ?? userJson?.message ?? "Invalid token";
      return new Response(JSON.stringify({ success: false, error: msg }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify admin role from profiles
    const profileRes = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${callerId}&select=role`,
      { headers: serviceHeaders },
    );
    console.log('[admin-delete-user] profileRes', { status: profileRes.status, ok: profileRes.ok });
    const profileJson = await profileRes.json().catch(() => null);
    const callerRole: string | undefined = Array.isArray(profileJson) ? profileJson[0]?.role : undefined;

    if (!profileRes.ok || callerRole !== "admin") {
      return new Response(JSON.stringify({ success: false, error: "Forbidden: admin only" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = (await req.json()) as DeleteUserBody;
    if (!body?.userId) {
      return new Response(JSON.stringify({ success: false, error: "Missing userId" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log('[admin-delete-user] delete request', {
      targetUserIdPresent: !!body.userId,
      targetUserIdLen: body.userId?.length ?? 0,
    });

    if (body.userId === callerId) {
      return new Response(JSON.stringify({ success: false, error: "Forbidden: cannot delete self" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const deleteRes = await fetch(`${supabaseUrl}/auth/v1/admin/users/${body.userId}?should_soft_delete=false`, {
      method: "DELETE",
      headers: serviceHeaders,
    });
    console.log('[admin-delete-user] deleteRes', { status: deleteRes.status, ok: deleteRes.ok });

    const deleteJson = await deleteRes.json().catch(() => null);
    if (!deleteRes.ok) {
      const msg =
        deleteJson?.error_description ?? deleteJson?.message ?? deleteJson?.error ?? `Delete failed (${deleteRes.status})`;
      return new Response(JSON.stringify({ success: false, error: msg }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const deletedId: string | undefined = deleteJson?.user?.id ?? deleteJson?.id ?? body.userId;

    return new Response(JSON.stringify({ success: true, deletedUserId: deletedId ?? body.userId }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const message = e instanceof Error ? e.message : "Unknown error";
    return new Response(JSON.stringify({ success: false, error: message }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

