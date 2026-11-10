# Система подбора профессий (CareerMatch)

Лабораторные работы: модель БД, БД, модель БЗ, БЗ.

## Структура
| Папка | Что внутри |
|---|---|
| `models/` | Модель БД (`career_match.dbml`, `er_diagram.mmd`, `er_diagram.png`) и модель БЗ (`kb_scheme.mmd`, `kb_scheme.png`) |
| `db/1_database.sql` | База данных: 12 таблиц MySQL 8, ограничения, тестовые данные |
| `db/2_queries_demo.sql` | Готовые запросы для показа БД (вставлять по одному в правое окно db-fiddle) и проверка защиты данных |
| `kb/js/2_knowledge_base.js` | База знаний на JavaScript: правила «ЕСЛИ → ТО» K1–K6 и движок вывода |
| `kb/js/kb_visual.html` | Визуализация БЗ: страница с формой, рейтингом, схемой вывода «правила → профессии» и таблицей правил. Открывается двойным щелчком, интернет не нужен |
| `docs/` | Word-документ с описанием БД и БЗ |

## Запуск
- **БД:** db-fiddle.com → MySQL 8.0 → вставить `db/1_database.sql` в Schema SQL → Run. Или phpMyAdmin → вкладка SQL (раскомментировать `CREATE DATABASE` и `USE` в начале файла).
- **Показ БД:** запросы из `db/2_queries_demo.sql` вставлять по одному в правое окно Query SQL → Run.
- **БЗ:** `node kb/js/2_knowledge_base.js` либо F12 → Console в браузере → вставить файл → Enter.
- **Визуализация БЗ:** открыть `kb/js/kb_visual.html` в браузере (двойной щелчок), нажать «Подобрать профессии».
- **Модели:** `models/career_match.dbml` → dbdiagram.io; `models/*.mmd` → mermaid.live.

## Результат БЗ
Пользователь 1: Python Developer - 93,3. Пользователь 2: Junior Python Developer - 100, Data Analyst - 98,3.
