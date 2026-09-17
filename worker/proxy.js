export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const backend = env.BACKEND_URL || "http://130.210.46.182:8000";
    
    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return handleCORS();
    }
    
    // Handle WebSocket upgrade
    if (request.headers.get("Upgrade") === "websocket") {
      return proxyWebSocket(request, backend);
    }
    
    // Health check - respond even if backend is down
    if (url.pathname === "/health" || url.pathname === "/api/v1/health") {
      return handleHealthCheck(backend);
    }
    
    // API routes -> FastAPI backend
    if (url.pathname.startsWith("/api/") || 
        url.pathname.startsWith("/ws/") ||
        url.pathname.startsWith("/events")) {
      return proxyRequest(request, backend);
    }
    
    // Let Cloudflare Pages handle static assets
    return fetch(request);
  }
};

function handleCORS() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Requested-With",
      "Access-Control-Max-Age": "86400",
    },
  });
}

async function handleHealthCheck(backend) {
  try {
    // Try to reach backend
    const response = await fetch(`${backend}/health`, {
      method: "GET",
      signal: AbortSignal.timeout(5000),
    });
    
    if (response.ok) {
      const data = await response.json();
      return new Response(JSON.stringify({
        status: "healthy",
        backend: "connected",
        ...data
      }), {
        status: 200,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
      });
    }
  } catch (e) {
    // Backend unreachable
  }
  
  // Backend down - return degraded status
  return new Response(JSON.stringify({
    status: "degraded",
    backend: "unreachable",
    message: "Backend service is currently unavailable",
    timestamp: new Date().toISOString()
  }), {
    status: 503,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
  });
}

async function proxyRequest(request, backend) {
  const url = new URL(request.url);
  const backendUrl = new URL(backend);
  
  // Rewrite URL to backend
  url.hostname = backendUrl.hostname;
  url.port = backendUrl.port;
  url.protocol = backendUrl.protocol;
  
  const headers = new Headers(request.headers);
  headers.set("Host", backendUrl.host);
  headers.set("X-Forwarded-For", request.headers.get("CF-Connecting-IP") || "");
  headers.set("X-Forwarded-Proto", "https");
  headers.set("X-Forwarded-Host", request.headers.get("Host") || "");
  
  // Remove headers that shouldn't be forwarded
  headers.delete("CF-Connecting-IP");
  headers.delete("CF-Ray");
  headers.delete("CF-Visitor");
  
  try {
    const response = await fetch(url.toString(), {
      method: request.method,
      headers,
      body: request.body,
      redirect: "manual",
      signal: AbortSignal.timeout(30000),
    });
    
    // Add CORS headers to response
    const responseHeaders = new Headers(response.headers);
    responseHeaders.set("Access-Control-Allow-Origin", "*");
    responseHeaders.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
    responseHeaders.set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
    
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: responseHeaders,
    });
  } catch (e) {
    // Backend connection failed
    return new Response(JSON.stringify({
      error: "Backend unavailable",
      message: "The backend service is currently unreachable",
      timestamp: new Date().toISOString()
    }), {
      status: 502,
      headers: { 
        "Content-Type": "application/json", 
        "Access-Control-Allow-Origin": "*" 
      }
    });
  }
}

async function proxyWebSocket(request, backend) {
  const backendUrl = new URL(backend);
  const wsUrl = new URL(request.url);
  wsUrl.hostname = backendUrl.hostname;
  wsUrl.port = backendUrl.port;
  wsUrl.protocol = backendUrl.protocol.replace("http", "ws");
  
  // Create WebSocket pair
  const { 0: client, 1: server } = new WebSocketPair();
  
  // Accept client connection
  server.accept();
  
  try {
    // Connect to backend WebSocket
    const backendWs = await fetch(wsUrl.toString(), {
      headers: {
        "Upgrade": "websocket",
        "Connection": "Upgrade",
        "Sec-WebSocket-Key": request.headers.get("Sec-WebSocket-Key") || "",
        "Sec-WebSocket-Version": request.headers.get("Sec-WebSocket-Version") || "13",
        "Sec-WebSocket-Protocol": request.headers.get("Sec-WebSocket-Protocol") || "",
      },
    });
    
    if (!backendWs.ok || !backendWs.body) {
      server.close(1011, "Backend WebSocket connection failed");
      return new Response(null, { status: 502 });
    }
    
    // Pipe data between client and backend
    const reader = backendWs.body.getReader();
    const writer = server.writable.getWriter();
    
    // Backend -> Client
    (async () => {
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          await writer.write(value);
        }
      } catch (e) {
        server.close(1011, "Backend read error");
      }
    })();
    
    // Client -> Backend
    const clientReader = server.readable.getReader();
    const backendWriter = backendWs.body?.getWriter();
    
    if (backendWriter) {
      (async () => {
        try {
          while (true) {
            const { done, value } = await clientReader.read();
            if (done) break;
            await backendWriter.write(value);
          }
        } catch (e) {
          // Connection closed
        }
      })();
    }
    
    return new Response(null, {
      status: 101,
      webSocket: client,
    });
  } catch (e) {
    server.close(1011, "Backend WebSocket connection failed");
    return new Response(null, { status: 502 });
  }
}