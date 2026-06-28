/**
 * Maya 2.0 - Cloudflare Worker (Secure)
 * Main API endpoint with authentication and rate limiting.
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    const corsHeaders = {
      "Access-Control-Allow-Origin": env.ALLOWED_ORIGIN || "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    // Public routes (no auth needed)
    if (path === "/health") {
      return jsonResponse({ status: "ok", timestamp: new Date().toISOString() }, corsHeaders);
    }

    // Auth check for all other routes
    const authResult = await authenticate(request, env);
    if (!authResult.valid) {
      return jsonResponse({ error: "Unauthorized" }, corsHeaders, 401);
    }

    // Rate limiting
    const rateLimitResult = await checkRateLimit(request, env, authResult.userId);
    if (!rateLimitResult.allowed) {
      return jsonResponse(
        { error: "Rate limit exceeded", retry_after: rateLimitResult.retryAfter },
        corsHeaders, 429
      );
    }

    try {
      if (path === "/" && request.method === "GET") {
        return jsonResponse({ status: "Maya 2.0 ULTRA", version: "2.0.0" }, corsHeaders);
      }

      if (path === "/run" && request.method === "POST") {
        return await handleRun(request, env, corsHeaders);
      }

      if (path === "/memory/search" && request.method === "POST") {
        return await handleMemorySearch(request, env, corsHeaders);
      }

      if (path === "/memory/add" && request.method === "POST") {
        return await handleMemoryAdd(request, env, corsHeaders);
      }

      if (path === "/tasks" && request.method === "GET") {
        return await handleGetTasks(request, env, corsHeaders);
      }

      if (path === "/tasks/status" && request.method === "GET") {
        return await handleTaskStatus(request, env, corsHeaders);
      }

      if (path === "/files/list" && request.method === "GET") {
        return await handleListFiles(env, corsHeaders);
      }

      return jsonResponse({ error: "Not found" }, corsHeaders, 404);

    } catch (error) {
      console.error("Worker error:", error);
      return jsonResponse({ error: "Internal server error" }, corsHeaders, 500);
    }
  },

  async scheduled(event, env, ctx) {
    await cleanOldMemories(env);
    await cleanOldTasks(env);
  }
};

// Authentication
async function authenticate(request, env) {
  const authHeader = request.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return { valid: false };
  }
  const token = authHeader.slice(7);
  const validToken = env.API_SECRET;
  if (!validToken || token !== validToken) {
    return { valid: false };
  }
  return { valid: true, userId: "default" };
}

// Rate limiting using KV
async function checkRateLimit(request, env, userId) {
  const key = `ratelimit:${userId}`;
  const limit = 60; // requests per minute
  const window = 60; // seconds

  try {
    const current = await env.CACHE.get(key);
    const count = current ? parseInt(current) : 0;

    if (count >= limit) {
      return { allowed: false, retryAfter: window };
    }

    await env.CACHE.put(key, String(count + 1), { expirationTtl: window });
    return { allowed: true };
  } catch {
    return { allowed: true }; // Fail open
  }
}

async function handleRun(request, env, headers) {
  const body = await request.json().catch(() => null);
  if (!body || !body.goal) {
    return jsonResponse({ error: "Goal is required" }, headers, 400);
  }

  const { goal, priority = "normal" } = body;

  // Input validation
  if (typeof goal !== "string" || goal.length > 2000) {
    return jsonResponse({ error: "Invalid goal" }, headers, 400);
  }

  const taskId = crypto.randomUUID();
  const now = new Date().toISOString();

  await env.DB.prepare(
    "INSERT INTO tasks (id, goal, status, priority, created_at) VALUES (?, ?, ?, ?, ?)"
  ).bind(taskId, goal, "pending", priority, now).run();

  await env.CACHE.put(
    `task:${taskId}`,
    JSON.stringify({ goal, status: "pending", created_at: now }),
    { expirationTtl: 3600 }
  );

  return jsonResponse({ task_id: taskId, goal, status: "pending" }, headers, 201);
}

async function handleMemorySearch(request, env, headers) {
  const body = await request.json().catch(() => null);
  if (!body || !body.query) {
    return jsonResponse({ error: "Query is required" }, headers, 400);
  }

  const { query, limit = 5 } = body;
  const safeLimit = Math.min(Math.max(1, parseInt(limit) || 5), 50);

  const results = await env.DB.prepare(
    "SELECT id, content, memory_type, created_at FROM memories WHERE content LIKE ? ORDER BY created_at DESC LIMIT ?"
  ).bind(`%${query}%`, safeLimit).all();

  return jsonResponse({ results: results.results, count: results.results.length }, headers);
}

async function handleMemoryAdd(request, env, headers) {
  const body = await request.json().catch(() => null);
  if (!body || !body.content) {
    return jsonResponse({ error: "Content is required" }, headers, 400);
  }

  const { content, memory_type = "general" } = body;

  if (typeof content !== "string" || content.length > 10000) {
    return jsonResponse({ error: "Invalid content" }, headers, 400);
  }

  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  await env.DB.prepare(
    "INSERT INTO memories (id, content, memory_type, created_at) VALUES (?, ?, ?, ?)"
  ).bind(id, content, memory_type, now).run();

  return jsonResponse({ id, status: "saved" }, headers, 201);
}

async function handleGetTasks(request, env, headers) {
  const url = new URL(request.url);
  const status = url.searchParams.get("status");
  const limit = Math.min(parseInt(url.searchParams.get("limit") || "20"), 100);

  let tasks;
  if (status) {
    tasks = await env.DB.prepare(
      "SELECT * FROM tasks WHERE status = ? ORDER BY created_at DESC LIMIT ?"
    ).bind(status, limit).all();
  } else {
    tasks = await env.DB.prepare(
      "SELECT * FROM tasks ORDER BY created_at DESC LIMIT ?"
    ).bind(limit).all();
  }

  return jsonResponse({ tasks: tasks.results, count: tasks.results.length }, headers);
}

async function handleTaskStatus(request, env, headers) {
  const url = new URL(request.url);
  const taskId = url.searchParams.get("id");

  if (!taskId) {
    return jsonResponse({ error: "Task ID required" }, headers, 400);
  }

  // Check cache first
  const cached = await env.CACHE.get(`task:${taskId}`);
  if (cached) {
    return jsonResponse(JSON.parse(cached), headers);
  }

  const task = await env.DB.prepare(
    "SELECT * FROM tasks WHERE id = ?"
  ).bind(taskId).first();

  if (!task) {
    return jsonResponse({ error: "Task not found" }, headers, 404);
  }

  return jsonResponse(task, headers);
}

async function handleListFiles(env, headers) {
  try {
    const files = await env.STORAGE.list({ limit: 100 });
    return jsonResponse({
      files: files.objects.map(f => ({ name: f.key, size: f.size, uploaded: f.uploaded })),
      count: files.objects.length
    }, headers);
  } catch {
    return jsonResponse({ files: [], count: 0 }, headers);
  }
}

async function cleanOldMemories(env) {
  await env.DB.prepare(
    "DELETE FROM memories WHERE created_at < datetime('now', '-30 days')"
  ).run();
}

async function cleanOldTasks(env) {
  await env.DB.prepare(
    "DELETE FROM tasks WHERE status IN ('done', 'failed') AND created_at < datetime('now', '-7 days')"
  ).run();
}

function jsonResponse(data, headers = {}, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS", "Access-Control-Allow-Headers": "Content-Type, Authorization"ype": "application/json", ...headers }
  });
}
