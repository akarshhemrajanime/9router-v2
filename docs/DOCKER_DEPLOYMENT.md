# Docker Deployment Guide — 9Router v2

Panduan lengkap untuk deploy 9Router v2 menggunakan Docker, khususnya untuk Hugging Face Spaces.

## 📋 Prerequisites

- Docker & Docker Compose terinstall
- Git
- Port 3000 tersedia (atau sesuaikan)

## 🚀 Quick Start (Hugging Face Spaces)

### 1. Setup di Hugging Face Spaces

1. Buat **new Space** di https://huggingface.co/spaces
2. Pilih **Docker** sebagai Space SDK
3. Clone repository 9Router v2:
   ```bash
   git clone https://github.com/akarshhemrajanime/9router-v2.git
   cd 9router-v2
   ```

### 2. Konfigurasi Environment

Buat file `.env` di root direktori:

```env
# .env
PORT=7860
REQUIRE_LOGIN=true
JWT_SECRET=your-very-secure-secret-key-here
ADMIN_PASSWORD=your-secure-admin-password
DATABASE_PATH=/data/9router.db
```

**Catatan untuk Hugging Face Spaces:**
- `PORT` harus `7860` (port default Spaces)
- Gunakan environment variables yang AMAN
- Database akan disimpan di `/data` (persistent volume)

### 3. Deploy

Push ke Hugging Face:

```bash
git remote add hf https://huggingface.co/spaces/YOUR_USERNAME/9router-v2
git push hf main
```

Hugging Face akan otomatis:
- Build Docker image
- Deploy container
- Expose di `https://your-username-9router-v2.hf.space`

---

## 🐳 Local Docker Setup

### Development dengan Hot-Reload

```bash
# Build dan start dengan development Dockerfile
docker-compose -f docker-compose.dev.yml up

# Akses:
# - Backend: http://localhost:3001
# - Frontend: http://localhost:5177
# - Dashboard: http://localhost:3000
```

### Production Build

```bash
# Build image
docker build -t 9router-v2:latest .

# Run container
docker-compose up -d

# Akses:
# - Dashboard: http://localhost:3000
# - API: http://localhost:3000/v1 atau http://localhost:3000/api
```

---

## 🔧 Konfigurasi

### Environment Variables

| Variable | Default | Deskripsi |
|---|---|---|
| `PORT` | `3000` | Port HTTP server (7860 untuk Spaces) |
| `BACKEND_PORT` | `3001` | Port backend (internal) |
| `NODE_ENV` | `production` | Environment (production/development) |
| `REQUIRE_LOGIN` | `true` | Aktifkan authentication |
| `JWT_SECRET` | *(required)* | Secret untuk JWT signing |
| `ADMIN_PASSWORD` | `admin` | Password admin dashboard |
| `DATABASE_PATH` | `/app/data/9router.db` | Path SQLite database |

### Contoh Configuration untuk Spaces

```env
PORT=7860
NODE_ENV=production
REQUIRE_LOGIN=true
JWT_SECRET=sk-super-secret-xyz123
ADMIN_PASSWORD=securepasswordhere123
```

---

## 📦 Docker Compose Commands

### Development
```bash
# Start dengan hot-reload
docker-compose -f docker-compose.dev.yml up

# Rebuild
docker-compose -f docker-compose.dev.yml up --build

# Stop
docker-compose -f docker-compose.dev.yml down
```

### Production
```bash
# Start
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down

# Restart
docker-compose restart
```

### Health Check
```bash
# Check status
docker-compose ps

# Manual health check
curl http://localhost:3000/api/health
```

---

## 🔐 Security Best Practices

1. **Ubah JWT_SECRET**
   ```env
   JWT_SECRET=$(openssl rand -base64 32)
   ```

2. **Ubah ADMIN_PASSWORD**
   - Gunakan password yang kuat
   - Minimal 12 karakter dengan mix huruf/angka/simbol

3. **Gunakan HTTPS di Production**
   - Setup Nginx reverse proxy dengan SSL
   - Atau gunakan Cloudflare Pages/Workers

4. **Secure Secrets**
   - Jangan commit `.env` ke git
   - Gunakan Hugging Face Space Secrets untuk sensitive data
   - Di Spaces: Settings → Repository secrets

---

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Check port (Linux/Mac)
lsof -i :3000

# Kill process (Linux/Mac)
kill -9 <PID>

# Atau ubah port di docker-compose.yml
ports:
  - "3001:3000"  # Host:Container
```

### Database Permission Error

```bash
# Pastikan /app/data writable
docker exec 9router-v2 chmod -R 755 /app/data
```

### Out of Memory

Update `docker-compose.yml`:
```yaml
services:
  9router:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

### Logs

```bash
# View real-time logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f 9router

# Last 100 lines
docker-compose logs --tail=100
```

---

## 📊 Monitoring & Persistence

### Persistent Storage

Data disimpan di Docker volume `9router-data`:

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect 9router-data

# Backup
docker run --rm -v 9router-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/9router-backup.tar.gz -C /data .

# Restore
docker run --rm -v 9router-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/9router-backup.tar.gz -C /data
```

### Health Monitoring

```bash
# Check health
docker-compose ps

# Inside container
docker exec 9router-v2 curl http://localhost:3000/api/health
```

---

## 🚢 Advanced: Custom Nginx Reverse Proxy

Untuk production, tambahkan Nginx di depan:

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - 9router

  9router:
    # ... existing config
    expose:
      - "3000"
```

---

## 📝 Hugging Face Spaces Specific

### Secrets Management

Di Hugging Face Space Settings:

```
Repository secrets
└── JWT_SECRET: sk-...
└── ADMIN_PASSWORD: ...
└── API_KEYS: ...
```

Kemudian di Dockerfile:
```dockerfile
ARG JWT_SECRET
ARG ADMIN_PASSWORD
ENV JWT_SECRET=${JWT_SECRET}
ENV ADMIN_PASSWORD=${ADMIN_PASSWORD}
```

### Persistent Data

Data otomatis persist di `/data` Spaces volume.

### Custom Domain

Spaces support custom domain — setup di Space settings.

---

## ❓ FAQ

**Q: Berapa resource yang dibutuhkan?**
A: Minimum 2GB RAM, 1-2 CPU cores. Spaces free tier biasanya cukup.

**Q: Bisa pakai GPU?**
A: Ya, pilih "GPU" space type saat create. Update Dockerfile untuk CUDA support.

**Q: Database data hilang setelah deploy?**
A: Data persist di volume. Jika ingin fresh start, delete volume atau gunakan backup.

**Q: Bagaimana update ke versi baru?**
A: Git pull terbaru, push ke Spaces — auto-rebuild.

---

## 📚 Referensi

- [Docker Docs](https://docs.docker.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Hugging Face Spaces Docs](https://huggingface.co/docs/hub/spaces)
- [9Router GitHub](https://github.com/akarshhemrajanime/9router-v2)
