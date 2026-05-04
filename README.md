# TeamUp

A student social network for forming project teams.

> Mid-Project Follow-Up presentation — Team 28 — 2026-05-05.

## What is TeamUp?

A platform where students publish project ideas (academic or personal),
declare their skills, interests and goals, and get matched with complementary
teammates through a smart ranking algorithm.

## Repository structure

```
TeamUp/
├── backend/    # Node.js + Express 5 + MariaDB API — see backend/README.md
└── (frontend)  # Flutter app — currently in design phase (Figma mockup)
```

## Status (2026-05-04)

| Component         | State              | Notes                                                                |
|-------------------|--------------------|----------------------------------------------------------------------|
| Database design   | ✅ Done             | 13 tables, foreign keys, composite indexes — `backend/db/schema.sql` |
| Backend API       | ✅ Done             | Auth, profiles, projects, applications, matching, REST chat          |
| Matching algo     | ✅ Done (v0)        | Weighted skill score + Jaccard interest similarity                   |
| Frontend (Flutter)| 🚧 Mockup phase    | Workload underestimation acknowledged — Figma mockup only            |
| Real-time chat    | ⏳ Planned (v1)    | WebSocket layer, deferred                                             |

## Quick start

See [`backend/README.md`](backend/README.md) for environment setup, database
schema, full API reference and the matching algorithm formula.

Demo accounts created by `npm run db:seed`:

| Email             | Password   | Profile                          |
|-------------------|------------|----------------------------------|
| alice@school.fr   | `password` | Frontend + Design                |
| bob@school.fr     | `password` | Backend + Database               |
| chloe@school.fr   | `password` | Designer learning Flutter        |
| diane@school.fr   | `password` | Machine Learning student         |
| erwan@school.fr   | `password` | Mobile dev (Flutter, Kotlin)     |
| farah@school.fr   | `password` | Project management generalist    |

## Team 28

- Abdelkarim MAKHLAS
- Mahad MOUMINE ALI
- Iyed MARAHGNI

## License

[MIT](LICENSE)
