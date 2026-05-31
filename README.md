# TeamUp

**A mobile social network that helps students form project teams.**

Students publish project ideas, declare their skills, interests and goals, and
get matched with complementary teammates through a smart ranking algorithm -
then plan, recruit and chat, all in one native app.

> Engineering-school project - Team 28.

---

## 📲 Télécharger l'app (Android)

[![Télécharger l'APK](https://img.shields.io/badge/T%C3%A9l%C3%A9charger-APK%20Android-6366F1?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Uncher1/TeamUp/releases/latest)

Récupère le dernier **APK** depuis la page **[Releases](https://github.com/Uncher1/TeamUp/releases/latest)**,
transfère-le sur ton téléphone Android et installe-le (autorise « Installer
depuis des sources inconnues » si Android le demande). L'application se connecte
directement à l'API en ligne - aucune configuration nécessaire.

---

## ✨ Features

- **Authentication** - email + password with **email verification** (one-time
  `XXXX-XXXX` code), **Google Sign-In** (native), and confirm-by-email for
  sensitive changes (email / password).
- **Profiles** - bio, school, skills (with proficiency level), interests,
  avatar, and social links.
- **Smart matching** - weighted skill score + Jaccard interest similarity to
  rank the most complementary teammates and projects.
- **Projects** - create and manage projects (category, required skills, team
  size, timeline, status), apply, and build teams.
- **Social feed** - posts (launch / looking-for / milestone / update / general),
  likes and comments.
- **Real-time chat** - direct and team conversations over WebSockets (Socket.IO),
  messages delivered instantly.
- **Notifications** - in-app notification center with an unread badge.
- **Moderation & admin** - roles (user / moderator / admin), shield badges,
  content moderation, and an admin account-management panel.
- **Internationalization** - full **French + English** UI (English by default,
  live switch) and bilingual transactional emails.
- **Theming** - light / **dark mode** and a customizable accent color.

---

## 🧱 Tech stack

| Layer        | Technologies                                                                 |
|--------------|------------------------------------------------------------------------------|
| **Mobile**   | Flutter (Dart), Provider, Dio, socket_io_client, google_sign_in, secure_storage |
| **Backend**  | Node.js, Express 5, Socket.IO, JWT, bcrypt, Nodemailer, google-auth-library  |
| **Database** | MySQL / MariaDB                                                              |
| **Security** | Helmet, CORS, rate limiting, hashed passwords, env-based secrets             |
| **Hosting**  | API + MySQL on [Alwaysdata](https://www.alwaysdata.com)                      |

---

## 📁 Repository structure

```
TeamUp/
├── backend/    # Node.js + Express 5 + MySQL API + Socket.IO  - see backend/README.md
└── frontend/   # Flutter mobile app (Android / iOS / web)
```

---

## 🚀 Quick start (local development)

### Backend

```bash
cd backend
cp .env.example .env        # then fill in DB + JWT + SMTP + Google values
npm install
node scripts/load-schema.js # create the tables
node scripts/seed-catalog.js# load the skills / interests catalog
npm start                   # API on http://localhost:3000
```

Optional demo data for local testing: `npm run db:seed` (creates sample users -
password `password`). The production database contains no demo data.

See [`backend/README.md`](backend/README.md) for the full API reference and the
matching algorithm formula.

### Frontend

```bash
cd frontend
flutter pub get
flutter run                 # device or emulator
```

The API base URL is configured in `frontend/lib/core/config.dart`.

---

## 👥 Team 28

- Abdelkarim MAKHLAS
- Mahad MOUMINE ALI
- Iyed MARAHGNI

## License

[MIT](LICENSE)
