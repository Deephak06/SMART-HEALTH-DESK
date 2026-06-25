// @deno-types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts"
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Cursor/TS may not pick up Deno globals in this repo; ensure editor doesn't error.
// Runtime is Supabase Edge (Deno), so `Deno` will exist there.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
declare const Deno: any;

// Admin: create patient/doctor users
// - Validates caller is admin (profiles.role == 'admin')
// - Creates Supabase Auth user with metadata so existing triggers create:
//   - public.profiles
//   - public.patients or public.doctors

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

type Role = "patient" | "doctor";

interface CreateUserBody {
  email: string;
  password: string;
  fullName: string;
  phone: string | null;
  role: Role;
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

    console.log('[admin-create-user] received', {
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

    // 1) Verify the caller: get user from GoTrue with the access token.
    const userRes = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: {
        Authorization: `Bearer ${token}`,
        apikey: serviceRoleKey,
      },
    });
    console.log('[admin-create-user] userRes', { status: userRes.status, ok: userRes.ok });
    const userJson = await userRes.json().catch(() => null);
    const callerId: string | undefined = userJson?.id ?? userJson?.user?.id ?? userJson?.data?.user?.id;

    if (!userRes.ok || !callerId) {
      const msg = userJson?.error_description ?? userJson?.message ?? "Invalid token";
      return new Response(JSON.stringify({ success: false, error: msg }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2) Verify admin role from profiles using service role (bypasses RLS).
    const profileRes = await fetch(
      `${supabaseUrl}/rest/v1/profiles?id=eq.${callerId}&select=role`,
      { headers: serviceHeaders },
    );
    console.log('[admin-create-user] profileRes', { status: profileRes.status, ok: profileRes.ok });
    const profileJson = await profileRes.json().catch(() => null);
    const callerRole: string | undefined = Array.isArray(profileJson) ? profileJson[0]?.role : undefined;

    if (!profileRes.ok || callerRole !== "admin") {
      return new Response(JSON.stringify({ success: false, error: "Forbidden: admin only" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2) Parse input
    const body = (await req.json()) as CreateUserBody;
    if (!body?.email || !body?.password || !body?.fullName || !body?.role) {
      return new Response(JSON.stringify({ success: false, error: "Missing required fields" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (body.role !== "patient" && body.role !== "doctor") {
      return new Response(JSON.stringify({ success: false, error: "Invalid role" }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log('[admin-create-user] create payload', {
      role: body.role,
      emailLen: body.email?.length ?? 0,
      fullNameLen: body.fullName?.length ?? 0,
      phonePresent: !!body.phone,
    });

    // 3) Create the user (service role) via GoTrue admin endpoint.
    const createRes = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
      method: "POST",
      headers: {
        ...serviceHeaders,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: body.email,
        password: body.password,
        email_confirm: true,
        user_metadata: {
          full_name: body.fullName,
          phone: body.phone,
          role: body.role,
        },
      }),
    });

    console.log('[admin-create-user] createRes', { status: createRes.status, ok: createRes.ok });
    const createJson = await createRes.json().catch(() => null);
    const createdUserId: string | undefined = createJson?.id ?? createJson?.user?.id ?? createJson?.data?.user?.id;

    if (!createRes.ok || !createdUserId) {
      const msg =
        createJson?.error_description ?? createJson?.message ?? createJson?.error ?? `Failed to create user (${createRes.status})`;
      return new Response(JSON.stringify({ success: false, error: msg }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, userId: createdUserId }), {
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

