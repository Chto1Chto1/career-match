-- =====================================================================
-- Запросы для показа базы данных.
-- Как использовать: в db-fiddle сначала вставьте 1_database.sql в ЛЕВОЕ окно
-- (Schema SQL), затем копируйте ПО ОДНОМУ запросу ниже в ПРАВОЕ окно
-- (Query SQL) и нажимайте Run. Если вставить несколько запросов сразу,
-- сайт может показать результат только последнего.
-- =====================================================================

-- 1. Справочник профессий
SELECT prof_id, title, category, avg_sal FROM PROFESSIONS;

-- 2. Справочник навыков и синонимы
SELECT skl_id, name, type, aliases FROM SKILLS;

-- 3. Пользователи и их профили
SELECT u.usr_id, u.email, p.exp_years, p.edu_level, p.skills
FROM USERS u JOIN PROFILES p ON p.usr_id = u.usr_id;

-- 4. Карьерные цели пользователей
SELECT u.email, g.sal_min, g.sal_max, g.w_format, g.w_hours, g.location
FROM GOALS g JOIN USERS u ON u.usr_id = g.usr_id;

-- 5. Требования профессий к навыкам (связь «многие ко многим»)
SELECT pr.title AS profession, s.name AS skill, r.weight, r.is_req
FROM REQUIREMENTS r
JOIN PROFESSIONS pr ON pr.prof_id = r.prof_id
JOIN SKILLS s ON s.skl_id = r.skl_id
ORDER BY pr.title, r.weight DESC;

-- 6. Сколько навыков и сколько обязательных у каждой профессии
SELECT pr.title, COUNT(*) AS skills_total, SUM(r.is_req) AS skills_required
FROM PROFESSIONS pr JOIN REQUIREMENTS r ON r.prof_id = pr.prof_id
GROUP BY pr.prof_id, pr.title
ORDER BY skills_total DESC;

-- 7. Правила базы знаний «ЕСЛИ → ТО»
SELECT rul_id, name, `condition`, conclusion, priority
FROM KNOWLEDGE ORDER BY priority DESC;

-- 8. Правила сравнения профиля с профессией
SELECT c.rul_id, pr.title, c.cond_type, c.operator, c.value, c.action
FROM COMPARISONS c JOIN PROFESSIONS pr ON pr.prof_id = c.prof_id;

-- 9. Правила проверки ввода
SELECT field_name, `condition`, err_msg FROM VALIDATIONS;

-- 10. Какие профессии подходят пользователю 1 по зарплате (средняя зарплата не ниже желаемой)
SELECT pr.title, pr.avg_sal, g.sal_min
FROM PROFESSIONS pr JOIN GOALS g ON g.usr_id = 1
WHERE pr.avg_sal >= g.sal_min
ORDER BY pr.avg_sal DESC;

-- 11. Кто из экспертов какие профессии вносил
SELECT e.name AS expert, e.role, pr.title
FROM PROFESSIONS pr JOIN EXPERTS e ON e.exp_id = pr.upd_by
ORDER BY e.name, pr.title;

-- 12. Журнал рекомендаций (до запуска базы знаний пуст)
SELECT * FROM RECOMMENDATIONS;

-- =====================================================================
-- ПРОВЕРКА ЗАЩИТЫ ДАННЫХ. Каждый запрос ниже база должна ОТКЛОНИТЬ
-- с ошибкой. Запускайте строго по одному.
-- =====================================================================

-- 13. Отрицательный опыт -> ошибка CHECK (ck_profiles_exp)
-- INSERT INTO PROFILES (usr_id, exp_years) VALUES (1, -5);

-- 14. Повторное название профессии -> ошибка UNIQUE (uq_professions_title)
-- INSERT INTO PROFESSIONS (title) VALUES ('Python Developer');

-- 15. Недопустимый формат работы -> ошибка CHECK (ck_goals_fmt)
-- INSERT INTO GOALS (usr_id, w_format) VALUES (1, 'на луне');

-- 16. Профиль несуществующего пользователя -> ошибка внешнего ключа (fk_profiles_user)
-- INSERT INTO PROFILES (usr_id, exp_years) VALUES (999, 1);

-- 17. Правило с неверным выводом -> ошибка CHECK (ck_knowledge_concl)
-- INSERT INTO KNOWLEDGE (name, `condition`, conclusion) VALUES ('Плохое', 'exp_years > 1', 'что-то');
