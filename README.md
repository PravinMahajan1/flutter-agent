Vision 2.0 - QR-based Attendance System

This monorepo contains a Flutter mobile app (Material 3) and a Node.js/Express backend with PostgreSQL for a modern, role-based attendance and academic management system.

Directories
- apps/mobile: Flutter app (Material 3, QR scanning/generation)
- apps/backend: Node.js/Express API (Prisma ORM, JWT auth)
- infra: Docker Compose for PostgreSQL and dev tooling
- docs: Documentation and specs

Core Features
- Role-based auth (Student/Teacher/Admin) with JWT
- QR-based attendance (lecture, lab with batch/lab no, library)
- Subjects & enrollments
- Assignments (submit/download)
- Activities & certificates
- Leaves (submit/review)
- Analytics & CSV exports

Quickstart (Backend)
1) Start PostgreSQL via Docker
   cd infra && docker compose up -d

2) Install backend deps
   cd apps/backend && npm install

3) Set environment variables (see apps/backend/.env.example) and run migrations
   cp apps/backend/.env.example apps/backend/.env
   cd apps/backend && npx prisma migrate dev --name init

4) Seed initial admin user
   cd apps/backend && npm run seed

5) Start API
   cd apps/backend && npm run dev

Mobile app setup is tracked separately in apps/mobile.

# flutter-agent
