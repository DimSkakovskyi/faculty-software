CREATE DATABASE IF NOT EXISTS faculty_software
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE faculty_software;

CREATE TABLE IF NOT EXISTS persons (
    person_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    person_type ENUM('student', 'teacher') NOT NULL,
    department VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS software_packages (
    package_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    version VARCHAR(30) NOT NULL,
    created_at DATE DEFAULT NULL,
    package_status ENUM('development', 'testing', 'released', 'archived')
        NOT NULL DEFAULT 'development'
);

CREATE TABLE IF NOT EXISTS package_developers (
    package_id INT NOT NULL,
    person_id INT NOT NULL,
    developer_role VARCHAR(100),
    PRIMARY KEY (package_id, person_id),
    FOREIGN KEY (package_id) REFERENCES software_packages(package_id)
        ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES persons(person_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS seminars (
    seminar_id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT NOT NULL,
    topic VARCHAR(200) NOT NULL,
    scheduled_at DATETIME NOT NULL,
    location VARCHAR(150),
    FOREIGN KEY (package_id) REFERENCES software_packages(package_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS seminar_participants (
    seminar_id INT NOT NULL,
    person_id INT NOT NULL,
    PRIMARY KEY (seminar_id, person_id),
    FOREIGN KEY (seminar_id) REFERENCES seminars(seminar_id)
        ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES persons(person_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS demonstrations (
    demonstration_id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT NOT NULL,
    scheduled_at DATETIME NOT NULL,
    location VARCHAR(150),
    description TEXT,
    FOREIGN KEY (package_id) REFERENCES software_packages(package_id)
        ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS test_trials (
    trial_id INT AUTO_INCREMENT PRIMARY KEY,
    package_id INT NOT NULL,
    scheduled_at DATETIME NOT NULL,
    test_type VARCHAR(100) NOT NULL,
    result TEXT,
    trial_status ENUM('planned', 'in_progress', 'passed', 'failed')
        NOT NULL DEFAULT 'planned',
    FOREIGN KEY (package_id) REFERENCES software_packages(package_id)
        ON DELETE CASCADE
);
