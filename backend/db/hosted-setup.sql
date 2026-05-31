-- TeamUp hosted DB setup (import via phpMyAdmin into an existing database).
-- Tables + categorized skills/interests catalog. No demo data.

-- TeamUp database schema (MariaDB 10.4+)
-- Idempotent: re-running the script does not error.




-- ---------------------------------------------------------------------------
-- Users
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name     VARCHAR(120) NOT NULL,
  role          VARCHAR(20) NOT NULL DEFAULT 'user',  -- user | moderator | admin
  email_verified       TINYINT(1) NOT NULL DEFAULT 0,
  verification_code    VARCHAR(9) NULL,
  verification_expires DATETIME NULL,
  pending_change_type    VARCHAR(10) NULL,
  pending_email          VARCHAR(255) NULL,
  pending_password_hash  VARCHAR(255) NULL,
  pending_change_code    VARCHAR(9) NULL,
  pending_change_expires DATETIME NULL,
  bio           TEXT,
  avatar_url    MEDIUMTEXT,
  phone         VARCHAR(40),
  school        VARCHAR(120),
  department    VARCHAR(120),
  study_year    VARCHAR(40),
  location      VARCHAR(120),
  github        VARCHAR(120),
  linkedin      VARCHAR(120),
  twitter       VARCHAR(120),
  website       VARCHAR(200),
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Skill catalog + user proficiencies
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS skills (
  id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name      VARCHAR(80) NOT NULL UNIQUE,
  category  VARCHAR(60)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_skills (
  user_id   INT UNSIGNED NOT NULL,
  skill_id  INT UNSIGNED NOT NULL,
  level     TINYINT UNSIGNED NOT NULL DEFAULT 3,
  PRIMARY KEY (user_id, skill_id),
  FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE,
  FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
  CHECK (level BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Interest catalog + user interests
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS interests (
  id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name      VARCHAR(80) NOT NULL UNIQUE,
  category  VARCHAR(60)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_interests (
  user_id     INT UNSIGNED NOT NULL,
  interest_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, interest_id),
  FOREIGN KEY (user_id)     REFERENCES users(id)     ON DELETE CASCADE,
  FOREIGN KEY (interest_id) REFERENCES interests(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Projects (posts where students recruit teammates)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS projects (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id    INT UNSIGNED NOT NULL,
  title       VARCHAR(160) NOT NULL,
  description TEXT NOT NULL,
  category    VARCHAR(40) NULL,
  team_size   TINYINT UNSIGNED NULL,
  timeline    VARCHAR(20) NULL,
  status      ENUM('open','in_progress','closed') NOT NULL DEFAULT 'open',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_projects_status (status),
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS project_required_skills (
  project_id INT UNSIGNED NOT NULL,
  skill_id   INT UNSIGNED NOT NULL,
  weight     TINYINT UNSIGNED NOT NULL DEFAULT 3,
  PRIMARY KEY (project_id, skill_id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (skill_id)   REFERENCES skills(id)   ON DELETE CASCADE,
  CHECK (weight BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS project_interests (
  project_id  INT UNSIGNED NOT NULL,
  interest_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (project_id, interest_id),
  FOREIGN KEY (project_id)  REFERENCES projects(id)  ON DELETE CASCADE,
  FOREIGN KEY (interest_id) REFERENCES interests(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS project_members (
  project_id INT UNSIGNED NOT NULL,
  user_id    INT UNSIGNED NOT NULL,
  role       VARCHAR(60) DEFAULT 'member',
  joined_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS project_applications (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  project_id INT UNSIGNED NOT NULL,
  user_id    INT UNSIGNED NOT NULL,
  message    TEXT,
  status     ENUM('pending','accepted','rejected') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_project_user (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Conversations (direct OR project team chat)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS conversations (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  type       ENUM('direct','project') NOT NULL,
  project_id INT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS conversation_members (
  conversation_id INT UNSIGNED NOT NULL,
  user_id         INT UNSIGNED NOT NULL,
  joined_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (conversation_id, user_id),
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)         REFERENCES users(id)         ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS messages (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id INT UNSIGNED NOT NULL,
  sender_id       INT UNSIGNED NOT NULL,
  content         TEXT NOT NULL,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_messages_conv_created (conversation_id, created_at),
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id)       REFERENCES users(id)         ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Social feed: posts + likes
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS posts (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  author_id     INT UNSIGNED NOT NULL,
  type          ENUM('project_launch','team_update','looking_for','milestone','general')
                  NOT NULL DEFAULT 'general',
  content       TEXT NOT NULL,
  project_id    INT UNSIGNED NULL,
  comment_count INT UNSIGNED NOT NULL DEFAULT 0,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_posts_created (created_at),
  FOREIGN KEY (author_id)  REFERENCES users(id)    ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS post_likes (
  post_id    INT UNSIGNED NOT NULL,
  user_id    INT UNSIGNED NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (post_id, user_id),
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS post_comments (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  post_id    INT UNSIGNED NOT NULL,
  author_id  INT UNSIGNED NOT NULL,
  content    VARCHAR(2000) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_post_comments_post (post_id, created_at),
  FOREIGN KEY (post_id)   REFERENCES posts(id) ON DELETE CASCADE,
  FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  type       ENUM('team_invite','message','project_update','mention',
                  'team_join','project_complete','application') NOT NULL,
  title      VARCHAR(160) NOT NULL,
  body       VARCHAR(500),
  link_type  VARCHAR(40),
  link_id    INT UNSIGNED NULL,
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_notif_user_created (user_id, created_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Key/value user preferences (privacy, notifications, theme, language)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_settings (
  user_id       INT UNSIGNED NOT NULL,
  setting_key   VARCHAR(60)  NOT NULL,
  setting_value VARCHAR(255) NOT NULL,
  PRIMARY KEY (user_id, setting_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- Catalog: skills + interests
-- ---------------------------------------------------------------------------
INSERT INTO skills (name, category) VALUES
  ('HTML', 'Frontend'),
  ('CSS', 'Frontend'),
  ('Sass', 'Frontend'),
  ('JavaScript', 'Frontend'),
  ('TypeScript', 'Frontend'),
  ('React', 'Frontend'),
  ('Vue.js', 'Frontend'),
  ('Angular', 'Frontend'),
  ('Next.js', 'Frontend'),
  ('Tailwind CSS', 'Frontend'),
  ('Node.js', 'Backend'),
  ('Express', 'Backend'),
  ('Python', 'Backend'),
  ('Django', 'Backend'),
  ('Flask', 'Backend'),
  ('Java', 'Backend'),
  ('Spring', 'Backend'),
  ('C#', 'Backend'),
  ('.NET', 'Backend'),
  ('Go', 'Backend'),
  ('Ruby on Rails', 'Backend'),
  ('PHP', 'Backend'),
  ('Laravel', 'Backend'),
  ('GraphQL', 'Backend'),
  ('REST APIs', 'Backend'),
  ('Flutter', 'Mobile'),
  ('Dart', 'Mobile'),
  ('Swift', 'Mobile'),
  ('SwiftUI', 'Mobile'),
  ('Kotlin', 'Mobile'),
  ('Jetpack Compose', 'Mobile'),
  ('React Native', 'Mobile'),
  ('SQL', 'Database'),
  ('PostgreSQL', 'Database'),
  ('MySQL', 'Database'),
  ('MariaDB', 'Database'),
  ('MongoDB', 'Database'),
  ('Redis', 'Database'),
  ('SQLite', 'Database'),
  ('Firebase', 'Database'),
  ('Git', 'DevOps'),
  ('Docker', 'DevOps'),
  ('Kubernetes', 'DevOps'),
  ('CI/CD', 'DevOps'),
  ('AWS', 'DevOps'),
  ('Azure', 'DevOps'),
  ('Google Cloud', 'DevOps'),
  ('Linux', 'DevOps'),
  ('Machine Learning', 'AI & Data'),
  ('Deep Learning', 'AI & Data'),
  ('NLP', 'AI & Data'),
  ('Computer Vision', 'AI & Data'),
  ('Data Science', 'AI & Data'),
  ('Pandas', 'AI & Data'),
  ('TensorFlow', 'AI & Data'),
  ('PyTorch', 'AI & Data'),
  ('UI/UX Design', 'Design'),
  ('Figma', 'Design'),
  ('Adobe XD', 'Design'),
  ('Photoshop', 'Design'),
  ('Illustrator', 'Design'),
  ('Prototyping', 'Design'),
  ('Unity', 'Game Dev'),
  ('Unreal Engine', 'Game Dev'),
  ('C++', 'Game Dev'),
  ('Godot', 'Game Dev'),
  ('Blender', 'Game Dev'),
  ('Cybersecurity', 'Security'),
  ('Cryptography', 'Security'),
  ('Penetration Testing', 'Security'),
  ('Network Security', 'Security'),
  ('Project Management', 'Soft Skills'),
  ('Agile', 'Soft Skills'),
  ('Scrum', 'Soft Skills'),
  ('Communication', 'Soft Skills'),
  ('Leadership', 'Soft Skills'),
  ('Teamwork', 'Soft Skills'),
  ('Public Speaking', 'Soft Skills');

INSERT INTO interests (name, category) VALUES
  ('Web Development', 'Tech'),
  ('Mobile Apps', 'Tech'),
  ('AI', 'Tech'),
  ('Cybersecurity', 'Tech'),
  ('Cloud', 'Tech'),
  ('Blockchain', 'Tech'),
  ('IoT', 'Tech'),
  ('Data Science', 'Tech'),
  ('AR / VR', 'Tech'),
  ('DevOps', 'Tech'),
  ('Design', 'Creative'),
  ('Game Dev', 'Creative'),
  ('Music', 'Creative'),
  ('Photography', 'Creative'),
  ('Video', 'Creative'),
  ('Writing', 'Creative'),
  ('Startups', 'Business'),
  ('Entrepreneurship', 'Business'),
  ('Marketing', 'Business'),
  ('Finance', 'Business'),
  ('Product Management', 'Business'),
  ('Social Impact', 'Impact'),
  ('EdTech', 'Impact'),
  ('HealthTech', 'Impact'),
  ('Sustainability', 'Impact'),
  ('Open Source', 'Impact');
