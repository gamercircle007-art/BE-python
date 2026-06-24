# Paythan

Enterprise-grade modular monolith for payment and financial services. Designed for clean architecture, domain-driven design, and future microservice extraction.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | FastAPI, Python 3.12+, SQLAlchemy 2.0, Alembic, Pydantic v2 |
| Frontend | Flutter, Riverpod 3.x, go_router, Dio |
| Database | PostgreSQL 16 |
| Cache | Redis 7 |
| Auth | Email OTP (SMTP) + WhatsApp OTP (Twilio) + JWT |
| Infra | Docker, Terraform (AWS skeleton) |

## Project Structure

```
paythan/
├── backend/          # FastAPI modular monolith
├── frontend/         # Flutter mobile app
├── infra/            # Terraform for AWS
├── docker-compose.yml
└── README.md
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Python 3.12+ & Poetry (for local backend dev)
- Flutter SDK (for mobile app)

### 1. Clone and Configure

```bash
cd paythan
cp .env.example .env
cp backend/.env.example backend/.env

# Generate a secure JWT secret
python3 -c "import secrets; print(secrets.token_urlsafe(48))"
# Paste result into JWT_SECRET_KEY in both .env files
```

### 2. Start with Docker

```bash
docker compose up --build -d

# Run database migrations
docker compose exec backend alembic upgrade head

# Verify health
curl http://localhost:8000/health
```

- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

### 3. Run Flutter App

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Android emulator uses 10.0.2.2 for host localhost
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

# iOS simulator / desktop
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

## Authentication Flow

```
┌─────────┐    request-otp     ┌─────────┐    Redis (TTL)    ┌──────────┐
│ Client  │ ─────────────────► │ Backend │ ─────────────────► │ OTP Store │
└─────────┘                    └─────────┘                    └──────────┘
     │                              │
     │                              ├── Email → SMTP (Gmail)
     │                              └── WhatsApp → Twilio
     │
     │    verify-otp ──────────────►│
     │    login ───────────────────►│ ──► JWT access + refresh tokens
     ▼                              ▼
```

1. **Request OTP** — `POST /api/v1/auth/request-otp` with `email` or `phone`
2. **Verify OTP** — `POST /api/v1/auth/verify-otp` with OTP code
3. **Login** — `POST /api/v1/auth/login` to receive JWT tokens

## Environment Variables

Root `.env` is used by `docker-compose.yml`. Backend `.env` is for local Poetry development.

| Variable | Required | Description |
|----------|----------|-------------|
| `JWT_SECRET_KEY` | Yes | 32+ character secret for JWT signing |
| `DATABASE_URL` | Yes | `postgresql+asyncpg://user:pass@host:5432/db` |
| `REDIS_URL` | Yes | `redis://host:6379/0` |
| `EMAIL_HOST` | For email OTP | SMTP server (e.g., `smtp.gmail.com`) |
| `EMAIL_USERNAME` | For email OTP | SMTP username |
| `EMAIL_PASSWORD` | For email OTP | SMTP password / app password |
| `TWILIO_ACCOUNT_SID` | For WhatsApp OTP | Twilio account SID |
| `TWILIO_AUTH_TOKEN` | For WhatsApp OTP | Twilio auth token |
| `TWILIO_WHATSAPP_FROM` | For WhatsApp OTP | `whatsapp:+14155238886` (sandbox) |
| `OTP_EXPIRE_MINUTES` | No | Default: 10 |
| `CORS_ORIGINS` | No | Comma-separated allowed origins |

## Local Development (without full Docker)

```bash
# Start only infrastructure
docker compose up postgres redis -d

# Backend
cd backend && poetry install && poetry run alembic upgrade head
poetry run uvicorn app.main:app --reload

# Frontend
cd frontend && flutter run
```

## Adding a New Domain

1. Create folder under `backend/app/domains/<name>/`
2. Add `router.py`, `service.py`, `repository.py`, `schemas.py`, `models.py`
3. Create Alembic migration for new models
4. Register router in `backend/app/main.py`
5. Add Flutter feature under `frontend/lib/features/<name>/`

See [backend/README.md](backend/README.md) for detailed instructions.

## Microservice Migration Path

The codebase is structured so each `domains/<name>/` folder can become an independent service:

| Current (Monolith) | Future (Microservices) |
|--------------------|------------------------|
| `domains/auth/` | `auth-service` (OTP, JWT) |
| `domains/user/` | `user-service` (profiles) |
| Shared `core/` | Per-service config + API Gateway |
| Single PostgreSQL | Per-service DB or schema-per-service |
| In-process calls | HTTP/gRPC + event bus (SQS/SNS) |

Comments in router files explain extraction steps for each domain.

## Testing

```bash
# Backend
cd backend && poetry run pytest -v

# Frontend
cd frontend && flutter test
```

## AWS Deployment (Future)

Terraform skeleton in `infra/terraform/` targets:

- **ECS Fargate** — backend containers
- **RDS PostgreSQL** — managed database
- **ElastiCache Redis** — OTP cache + rate limiting
- **ALB** — HTTPS load balancing
- **Secrets Manager** — JWT, Twilio, SMTP credentials
- **CloudWatch** — structured JSON logs

```bash
cd infra/terraform
terraform init
terraform plan -var-file=environments/dev.tfvars
```

## Security Notes

- Never commit `.env` files
- Rotate `JWT_SECRET_KEY` regularly in production
- Use AWS Secrets Manager for credentials in prod
- Enable `LOG_JSON=true` and `APP_ENV=prod` for production
- Rate limiting is scaffolded in `main.py` (uncomment slowapi block)

## License

Proprietary — Paythan Team