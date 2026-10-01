-- Run this file only once, after schema.sql, if you need sample data.
USE faculty_software;

INSERT INTO persons (full_name, person_type, department, email)
VALUES
    ('Іван Петренко', 'student', 'Комп’ютерні науки', 'ivan@example.com'),
    ('Олена Коваль', 'teacher', 'Комп’ютерні науки', 'olena@example.com');

INSERT INTO software_packages (name, description, version, created_at)
VALUES ('Faculty Manager', 'Система керування ресурсами факультету', '1.0', CURRENT_DATE());

SET @sample_package_id = LAST_INSERT_ID();

INSERT INTO package_developers (package_id, person_id, developer_role)
SELECT @sample_package_id, person_id, 'Developer'
FROM persons WHERE email = 'ivan@example.com';

INSERT INTO package_developers (package_id, person_id, developer_role)
SELECT @sample_package_id, person_id, 'Supervisor'
FROM persons WHERE email = 'olena@example.com';

INSERT INTO seminars (package_id, topic, scheduled_at, location)
VALUES (@sample_package_id, 'Знайомство з Faculty Manager', '2026-10-01 14:00:00', 'Аудиторія 101');

SET @sample_seminar_id = LAST_INSERT_ID();

INSERT INTO seminar_participants (seminar_id, person_id)
SELECT @sample_seminar_id, person_id
FROM persons WHERE email = 'ivan@example.com';

INSERT INTO demonstrations (package_id, scheduled_at, location, description)
VALUES (@sample_package_id, '2026-10-03 12:00:00', 'Аудиторія 102', 'Показ основних функцій');

INSERT INTO test_trials (package_id, scheduled_at, test_type)
VALUES (@sample_package_id, '2026-10-05 10:00:00', 'Функціональне тестування');
