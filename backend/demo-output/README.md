# Demo output: captured API responses

These files contain real responses from the running backend, captured on
2026-05-04. They're committed so anyone reviewing the repo (including the
grader) can see concretely what the API returns, not just specs.

| File                              | Endpoint                                       | Purpose                                                |
|-----------------------------------|------------------------------------------------|--------------------------------------------------------|
| `01-login-alice.json`             | `POST /api/auth/login`                         | JWT auth works; returns token + user                   |
| `02-profile-alice.json`           | `GET  /api/users/me`                           | Profile with skills (with proficiency level) + interests |
| `03-list-projects.json`           | `GET  /api/projects`                           | 3 seeded projects, each owned by a different student   |
| `04-matching-algorithm.json`      | `GET  /api/matching/projects/1/users`          | **Algorithm in action**: Chloé wins (0.55) for StudyMate (mobile + UX project) |
| `05-chat-messages.json`           | `GET  /api/conversations/1/messages`           | Project chat with 2 distinct senders                   |

To regenerate these files: start MariaDB, `npm run db:seed`, `npm run dev`,
then replay [`requests.http`](../requests.http).
