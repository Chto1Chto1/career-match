-- =====================================================================
-- Система подбора профессий. создание базы данных
-- (12 таблиц, ограничения целостности) и тестовые данные. СУБД MySQL 8 (проверено также на MariaDB 10.11).
-- Слово condition в MySQL зарезервировано, поэтому в SQL оно пишется
-- в обратных кавычках: `condition`.
-- =====================================================================
-- phpMyAdmin / свой сервер MySQL: уберите «-- » перед двумя строками ниже.
-- Онлайн-редактор (db-fiddle.com): оставьте как есть, база уже создана.
-- CREATE DATABASE IF NOT EXISTS career_match CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE career_match;

-- ---------------------------------------------------------------------
-- USERS: пользователи системы
-- Пароль хранится только в виде хеша (его считает приложение, например bcrypt)
-- ---------------------------------------------------------------------
CREATE TABLE USERS (
  usr_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email      VARCHAR(255) NOT NULL,
  pass_hash  VARCHAR(255) NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status     VARCHAR(50)  NOT NULL DEFAULT 'active',
  PRIMARY KEY (usr_id),
  UNIQUE KEY uq_users_email (email),
  CONSTRAINT ck_users_status CHECK (status IN ('active','blocked','deleted'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- EXPERTS: эксперты, наполняющие базу знаний
-- ---------------------------------------------------------------------
CREATE TABLE EXPERTS (
  exp_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(255) NOT NULL,
  role       VARCHAR(100) NULL,
  email      VARCHAR(255) NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (exp_id),
  UNIQUE KEY uq_experts_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- SKILLS: справочник навыков (hard / soft)
-- aliases - синонимы для нормализации
-- ---------------------------------------------------------------------
CREATE TABLE SKILLS (
  skl_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name    VARCHAR(255) NOT NULL,
  type    VARCHAR(50)  NULL,
  aliases TEXT         NULL,
  PRIMARY KEY (skl_id),
  UNIQUE KEY uq_skills_name (name),
  CONSTRAINT ck_skills_type CHECK (type IN ('hard','soft'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- PROFILES: профили пользователей
-- ---------------------------------------------------------------------
CREATE TABLE PROFILES (
  prfl_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usr_id     INT UNSIGNED NOT NULL,
  exp_years  INT          NULL,
  edu_level  VARCHAR(100) NULL,
  raw_input  TEXT         NULL,
  skills     TEXT         NULL,
  interests  TEXT         NULL,
  upd_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (prfl_id),
  CONSTRAINT fk_profiles_user
    FOREIGN KEY (usr_id) REFERENCES USERS (usr_id) ON DELETE CASCADE,
  CONSTRAINT ck_profiles_exp CHECK (exp_years >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- GOALS: карьерные цели пользователей
-- ---------------------------------------------------------------------
CREATE TABLE GOALS (
  goal_id  INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  usr_id   INT UNSIGNED   NOT NULL,
  sal_min  DECIMAL(12,2)  NULL,
  sal_max  DECIMAL(12,2)  NULL,
  w_format VARCHAR(50)    NULL,
  w_hours  VARCHAR(50)    NULL,
  location VARCHAR(255)   NULL,
  PRIMARY KEY (goal_id),
  CONSTRAINT fk_goals_user
    FOREIGN KEY (usr_id) REFERENCES USERS (usr_id) ON DELETE CASCADE,
  CONSTRAINT ck_goals_sal  CHECK (sal_min >= 0 AND sal_max >= 0 AND sal_min <= sal_max),
  CONSTRAINT ck_goals_fmt  CHECK (w_format IN ('office','remote','hybrid')),
  CONSTRAINT ck_goals_hrs  CHECK (w_hours IN ('full','part'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- PROFESSIONS: справочник профессий
-- ---------------------------------------------------------------------
CREATE TABLE PROFESSIONS (
  prof_id  INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  title    VARCHAR(255)   NOT NULL,
  category VARCHAR(100)   NULL,
  descr    TEXT           NULL,
  avg_sal  DECIMAL(12,2)  NULL,
  std_src  VARCHAR(255)   NULL,
  upd_by   INT UNSIGNED   NULL,
  upd_at   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (prof_id),
  UNIQUE KEY uq_professions_title (title),
  CONSTRAINT fk_professions_expert
    FOREIGN KEY (upd_by) REFERENCES EXPERTS (exp_id) ON DELETE SET NULL,
  CONSTRAINT ck_professions_sal CHECK (avg_sal >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- REQUIREMENTS: требования профессий к навыкам (M:N)
-- ---------------------------------------------------------------------
CREATE TABLE REQUIREMENTS (
  prof_id INT UNSIGNED  NOT NULL,
  skl_id  INT UNSIGNED  NOT NULL,
  weight  DECIMAL(5,2)  NOT NULL DEFAULT 1.0,
  is_req  BOOLEAN       NOT NULL DEFAULT FALSE,
  upd_by  INT UNSIGNED  NULL,
  upd_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (prof_id, skl_id),
  CONSTRAINT fk_req_prof
    FOREIGN KEY (prof_id) REFERENCES PROFESSIONS (prof_id) ON DELETE CASCADE,
  CONSTRAINT fk_req_skl
    FOREIGN KEY (skl_id)  REFERENCES SKILLS (skl_id)       ON DELETE CASCADE,
  CONSTRAINT fk_req_expert
    FOREIGN KEY (upd_by)  REFERENCES EXPERTS (exp_id)      ON DELETE SET NULL,
  CONSTRAINT ck_req_weight CHECK (weight > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- VALIDATIONS: правила валидации ввода
-- ---------------------------------------------------------------------
CREATE TABLE VALIDATIONS (
  rul_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  field_name VARCHAR(100) NOT NULL,
  `condition` TEXT        NOT NULL,
  err_msg    TEXT         NULL,
  upd_by     INT UNSIGNED NULL,
  PRIMARY KEY (rul_id),
  CONSTRAINT fk_validations_expert
    FOREIGN KEY (upd_by) REFERENCES EXPERTS (exp_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- COMPARISONS: правила сравнения профиля с профессией
-- ---------------------------------------------------------------------
CREATE TABLE COMPARISONS (
  rul_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  prof_id   INT UNSIGNED NOT NULL,
  cond_type VARCHAR(50)  NOT NULL,
  operator  VARCHAR(20)  NOT NULL,
  value     TEXT         NOT NULL,
  action    VARCHAR(100) NOT NULL,
  upd_by    INT UNSIGNED NULL,
  PRIMARY KEY (rul_id),
  CONSTRAINT fk_comparisons_prof
    FOREIGN KEY (prof_id) REFERENCES PROFESSIONS (prof_id) ON DELETE CASCADE,
  CONSTRAINT fk_comparisons_expert
    FOREIGN KEY (upd_by)  REFERENCES EXPERTS (exp_id)      ON DELETE SET NULL,
  CONSTRAINT ck_cmp_type CHECK (cond_type IN ('exp_years','edu_level')),
  CONSTRAINT ck_cmp_op   CHECK (operator IN ('=','!=','<','<=','>','>='))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- KNOWLEDGE: база знаний, правила «ЕСЛИ → ТО»
-- ---------------------------------------------------------------------
CREATE TABLE KNOWLEDGE (
  rul_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(255) NOT NULL,
  `condition` TEXT        NOT NULL,
  conclusion TEXT         NOT NULL,
  priority   INT          NOT NULL DEFAULT 0,
  upd_by     INT UNSIGNED NULL,
  PRIMARY KEY (rul_id),
  CONSTRAINT fk_knowledge_expert
    FOREIGN KEY (upd_by) REFERENCES EXPERTS (exp_id) ON DELETE SET NULL,
  CONSTRAINT ck_knowledge_prio CHECK (priority >= 0),
  CONSTRAINT ck_knowledge_concl CHECK (conclusion REGEXP '^(recommend|exclude): *[^ ]')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- RECOMMENDATIONS: лог выданных рекомендаций
-- ---------------------------------------------------------------------
CREATE TABLE RECOMMENDATIONS (
  log_id     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  usr_id     INT UNSIGNED  NULL,
  prof_id    INT UNSIGNED  NULL,
  score      DECIMAL(10,4) NULL,
  matched    BOOLEAN       NOT NULL DEFAULT FALSE,
  filtered   BOOLEAN       NOT NULL DEFAULT FALSE,
  rank_pos   INT           NULL,
  feedback   TEXT          NULL,
  created_at DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (log_id),
  KEY idx_rec_usr_created (usr_id, created_at),
  CONSTRAINT fk_rec_user
    FOREIGN KEY (usr_id)  REFERENCES USERS (usr_id)         ON DELETE SET NULL,
  CONSTRAINT fk_rec_prof
    FOREIGN KEY (prof_id) REFERENCES PROFESSIONS (prof_id)  ON DELETE SET NULL,
  CONSTRAINT ck_rec_score CHECK (score BETWEEN 0 AND 100),
  CONSTRAINT ck_rec_rank  CHECK (rank_pos > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- REPORTS: шаблоны отчётов
-- ---------------------------------------------------------------------
CREATE TABLE REPORTS (
  tpl_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(255) NOT NULL,
  structure  TEXT         NULL,
  disp_rules TEXT         NULL,
  upd_by     INT UNSIGNED NULL,
  PRIMARY KEY (tpl_id),
  CONSTRAINT fk_reports_expert
    FOREIGN KEY (upd_by) REFERENCES EXPERTS (exp_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- =====================================================================

INSERT INTO EXPERTS (exp_id, name, role, email) VALUES
 (1, 'Иван Петров',    'HR-аналитик',           'ivan@hr.ru'),
 (2, 'Мария Соколова', 'Карьерный консультант', 'maria@hr.ru');

INSERT INTO USERS (usr_id, email, pass_hash, status) VALUES
 (1, 'ivan@mail.ru', '$2b$10$demoHashDemoHashDemoHashDemoHashDemoHashDemoHashDe', 'active'),
 (2, 'anna@mail.ru', '$2b$10$demoHashDemoHashDemoHashDemoHashDemoHashDemoHashDe', 'active');

INSERT INTO PROFILES (prfl_id, usr_id, exp_years, edu_level, raw_input, skills, interests) VALUES
 (1, 1, 5, 'master',
  'Работал Python-разработчиком 5 лет: Django, PostgreSQL, Git',
  'Python3, Django, Postgres, SQL, Git, Общение', 'ML, финтех'),
 (2, 2, 0, 'bachelor',
  'Выпускница, курсовые работы на Python и SQL, интерес к аналитике данных',
  'python, SQL, Git, Excel, Statistics, Teamwork, Figma', 'аналитика, BI');

INSERT INTO GOALS (goal_id, usr_id, sal_min, sal_max, w_format, w_hours, location) VALUES
 (1, 1, 150000.00, 250000.00, 'remote', 'full', 'Москва'),
 (2, 2,  80000.00, 130000.00, 'hybrid', 'full', 'Новосибирск');

INSERT INTO SKILLS (skl_id, name, type, aliases) VALUES
 (1,  'Python',        'hard', 'Питон, Python3, Py'),
 (2,  'Django',        'hard', NULL),
 (3,  'PostgreSQL',    'hard', 'Postgres, PgSQL'),
 (4,  'SQL',           'hard', NULL),
 (5,  'Git',           'hard', 'Гит'),
 (6,  'Docker',        'hard', 'Докер'),
 (7,  'JavaScript',    'hard', 'JS, Java Script'),
 (8,  'React',         'hard', 'ReactJS, React.js'),
 (9,  'HTML/CSS',      'hard', 'HTML, CSS'),
 (10, 'Excel',         'hard', 'Эксель, MS Excel'),
 (11, 'Statistics',    'hard', 'Статистика'),
 (12, 'Testing',       'hard', 'Тестирование, QA'),
 (13, 'Communication', 'soft', 'Общение, Коммуникабельность'),
 (14, 'Teamwork',      'soft', 'Командная работа, Работа в команде');

INSERT INTO PROFESSIONS (prof_id, title, category, descr, avg_sal, std_src, upd_by) VALUES
 (1, 'Python Developer',        'IT',         'Разработка серверной части на Python',        200000.00, 'hh.ru', 1),
 (2, 'Data Analyst',            'IT',         'Анализ данных, отчёты и визуализация',        160000.00, 'hh.ru', 1),
 (3, 'Frontend Developer',      'IT',         'Разработка клиентской части веб-приложений',  180000.00, 'hh.ru', 1),
 (4, 'Project Manager',         'Management', 'Управление проектами и командой',             190000.00, 'hh.ru', 2),
 (5, 'QA Engineer',             'IT',         'Тестирование программного обеспечения',       120000.00, 'hh.ru', 1),
 (6, 'Junior Python Developer', 'IT',         'Начальная позиция в разработке на Python',     90000.00, 'hh.ru', 1);

INSERT INTO REQUIREMENTS (prof_id, skl_id, weight, is_req, upd_by) VALUES
 (1, 1, 5, TRUE,  1), (1, 2, 4, FALSE, 1), (1, 3, 3, FALSE, 1),
 (1, 5, 2, FALSE, 1), (1, 6, 3, FALSE, 1), (1, 13, 1, FALSE, 1),
 (2, 4, 5, TRUE,  1), (2, 1, 3, FALSE, 1), (2, 11, 4, FALSE, 1),
 (2, 10, 2, FALSE, 1), (2, 13, 1, FALSE, 1),
 (3, 7, 5, TRUE,  1), (3, 8, 4, FALSE, 1), (3, 9, 4, TRUE,  1), (3, 5, 2, FALSE, 1),
 (4, 13, 5, TRUE, 2), (4, 14, 4, TRUE,  2), (4, 10, 2, FALSE, 2),
 (5, 12, 5, TRUE, 1), (5, 4, 2, FALSE, 1), (5, 1, 2, FALSE, 1), (5, 5, 1, FALSE, 1),
 (6, 1, 5, TRUE,  1), (6, 5, 2, FALSE, 1), (6, 4, 2, FALSE, 1);

-- VALIDATIONS: формат проверок в поле `condition`
--   REGEXP:<шаблон>    значение должно соответствовать регулярному выражению
--   RANGE:<min>..<max> число в диапазоне
--   IN:<a,b,c>         значение из списка
INSERT INTO VALIDATIONS (field_name, `condition`, err_msg, upd_by) VALUES
 ('email',     'REGEXP:^[^@ ]+@[^@ ]+[.][^@ ]+$',            'Некорректный email', 1),
 ('exp_years', 'RANGE:0..60',                                'Опыт должен быть от 0 до 60 лет', 1),
 ('edu_level', 'IN:school,college,bachelor,master,phd',      'Недопустимый уровень образования', 1),
 ('sal_min',   'RANGE:0..10000000',                          'Недопустимая минимальная зарплата', 1);

-- COMPARISONS: cond_type operator value -> action (изменение балла профессии)
INSERT INTO COMPARISONS (rul_id, prof_id, cond_type, operator, value, action, upd_by) VALUES
 (1, 1, 'exp_years', '>=', '3', 'score += 5',  1),
 (2, 1, 'exp_years', '<',  '1', 'score -= 10', 1),
 (3, 6, 'exp_years', '>',  '2', 'score -= 30', 1);

-- KNOWLEDGE: правила «ЕСЛИ condition ТО conclusion»; priority разрешает конфликты
INSERT INTO KNOWLEDGE (rul_id, name, `condition`, conclusion, priority, upd_by) VALUES
 (1, 'Junior Python',                'exp_years < 1 AND has_skill = Python',    'recommend: Junior Python Developer', 10, 1),
 (2, 'Опытный Python-разработчик',   'exp_years >= 3 AND has_skill = Python',   'recommend: Python Developer',        10, 1),
 (3, 'Слишком опытный для Junior',   'exp_years >= 3',                          'exclude: Junior Python Developer',   20, 1),
 (4, 'Python и SQL ведут в аналитику','has_skill = Python AND has_skill = SQL', 'recommend: Data Analyst',              8, 1),
 (5, 'Бэкенд-опыт - не аналитик',    'exp_years >= 3 AND has_skill = Django',   'exclude: Data Analyst',              12, 1),
 (6, 'Django ведёт в Python Developer','has_skill = Django',                    'recommend: Python Developer',         5, 1);

INSERT INTO REPORTS (name, structure, disp_rules, upd_by) VALUES
 ('Отчёт по топ-10 профессиям',
  '{"columns":["rank_pos","title","score"],"limit":10}',
  '{"sort":"rank_pos ASC"}', 1);
