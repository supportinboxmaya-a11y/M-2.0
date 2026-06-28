# PDF 11 - Security & DevOps

## 1. Security Model
- Risk levels: low, medium, high, critical
- Dangerous keywords detection
- File sandbox (workspace/ only)
- Approval modes: auto/human/skip
- JWT authentication
- RBAC authorization

## 2. OAuth
- Providers: Google, GitHub
- Flow: Authorization Code
- Token storage: httpOnly cookies
- Refresh token rotation

## 3. JWT
- Algorithm: HS256
- Expiry: 1 hour (access), 7 days (refresh)
- Payload: user_id, role, exp

## 4. Docker Setup
- Dockerfile for Python backend
- docker-compose.yml for full stack
- Volume mounts for persistence
- Environment variables via .env

## 5. Kubernetes (Production)
- Deployment: 2 replicas minimum
- Service: ClusterIP
- Ingress: nginx
- HPA: CPU-based autoscaling
- PVC: for SQLite storage

## 6. CI/CD Pipeline
- Trigger: push to main
- Steps: lint, test, build, deploy
- Platform: GitHub Actions
- Deploy: Cloudflare Workers (API) + Vercel (Frontend)

## 7. Monitoring
- Logs: structured JSON logging
- Metrics: task success rate, latency, cost
- Alerts: budget exceeded, error rate spike
- Dashboard: Grafana / Cloudflare Analytics

## 8. Deployment
- Frontend: Vercel / Netlify
- Backend API: Cloudflare Workers
- Database: Cloudflare D1
- Storage: Cloudflare R2
- Cache: Cloudflare KV
