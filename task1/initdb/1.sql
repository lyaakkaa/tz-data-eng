-- Creating tables 
CREATE TABLE departments (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE positions (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE employees (
    id INT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    age INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    position_id INTEGER REFERENCES positions(id),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE salaries(
    id INT PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    salary NUMERIC(10, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE TABLE employee_department(
    id INT PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    department_id INTEGER REFERENCES departments(id),
    UNIQUE (employee_id, department_id)
);


-- Inseting data 
INSERT INTO departments (id, name) VALUES 
(1, 'IT'),
(2, 'HR'),
(3, 'Finance');

INSERT INTO positions (id, name) VALUES 
(1, 'Team Lead'),
(2, 'Project Manager'),
(3, 'System Administrator'),
(4, 'QA Engineer'),
(5, 'Developer'),
(6, 'HR Manager'),
(7, 'Recruiter'),
(8, 'Payroll Specialist'),
(9, 'Accountant'),
(10, 'Financial Analyst');

INSERT INTO employees (id, first_name, last_name, age, start_date, position_id) VALUES 
(1, 'Leila', 'Bekturgan', 22, '2023-01-01', 5),
(2, 'Akmira', 'Sagatbek', 23, '2023-01-01', 3),
(3, 'Amina', 'Seidakhmetova', 24, '2023-01-01', 4),
(4, 'Darina', 'Aitbaeva', 25, '2023-01-01', 8),
(5, 'Almas', 'Orazgaliev', 26, '2023-01-01', 10),
(6, 'Aruzhan', 'Bekturgan', 27, '2023-01-01', 9),
(7, 'David', 'Manukyan', 28, '2023-01-01', 6),
(8, 'David', 'Michelangelo', 29, '2023-01-01', 7),
(9, 'Dimash', 'Bulekbaev', 30, '2023-01-01', 2);

INSERT INTO employees (id, first_name, last_name, age, start_date, position_id) VALUES 
(10, 'Jo', 'Lol', 23, '2023-01-01', 5);


INSERT INTO salaries (id, employee_id, salary, start_date, end_date) VALUES 
(1, 1, 100000.00, '2024-01-01', NULL),
(2, 2, 600000.00, '2023-06-15', NULL),
(3, 3, 500500.00, '2023-08-01', NULL),
(4, 4, 620000.00, '2023-07-10', NULL),
(5, 5, 750000.00, '2023-09-20', NULL),
(6, 6, 800000.00, '2024-05-01', NULL),
(7, 7, 550000.00, '2023-11-01', NULL),
(8, 8, 900000.00, '2024-02-01', NULL),
(9, 9, 720000.00, '2023-10-05', NULL);

INSERT INTO salaries (id, employee_id, salary, start_date, end_date) VALUES 
(10, 10, 300000.00, '2024-01-01', NULL);

INSERT INTO employee_department (id, employee_id, department_id) VALUES 
(1, 1, 1), 
(2, 2, 1),  
(3, 3, 1), 
(4, 4, 2),  
(5, 5, 2), 
(6, 6, 2),  
(7, 7, 3), 
(8, 8, 3), 
(9, 9, 1);  

-- Leila Bekturgan in IT, Developer
-- Akmira Sagatbek in IT, System Administrator
-- Amina Seidakhmetova in IT, QA Engineer
-- Darina Aitbaeva in Finance, Accountant
-- Almas Orazgaliev in Finance, Financial Analyst
-- Aruzhan Bekturgan in Finance, Payroll Specialist
-- David Manukyan in HR, HR Manager
-- David Michelangelo in HR, Recruiter
-- Dimash Bulekbaev in IT, Project Manager


INSERT INTO employee_department (id, employee_id, department_id) VALUES 
(10, 10, 1);





--------------------------------------------------------------------------------------------------------------------------------------

-- Task 1: 
-- 1)	Сделать выборку всех работников с именем “Давид” из отдела “Снабжение” с полями ФИО, заработная плата, должность

SELECT e.first_name || ' ' || e.last_name AS "ФИО", s.salary AS "Заработная плата", p.name AS "Должность"
FROM employees e
JOIN salaries s ON e.id = s.employee_id
JOIN positions p ON e.position_id = p.id
JOIN employee_department ed ON e.id = ed.employee_id
JOIN departments d ON ed.department_id = d.id
WHERE e.first_name = 'David' AND d.name = 'Finance';



-- Task 2:
-- 2)	Посчитать среднюю заработную плату работников по отделам
SELECT d.name AS "Отдел", ROUND(AVG(s.salary), 2) AS "Средняя заработная плата"
FROM employees e
JOIN salaries s ON e.id = s.employee_id
JOIN employee_department ed ON e.id = ed.employee_id
JOIN departments d ON ed.department_id = d.id
GROUP BY d.name;



-- Task 3: 
-- 3)	Сделать выборку по должностям, в результате которой отобразятся данные, больше ли средняя ЗП по должности, чем средняя ЗП по всем работникам.
SELECT p.name AS "Должность", ROUND(AVG(s.salary), 2) AS "Средняя ЗП по должности",
    CASE 
        WHEN AVG(s.salary) <= (SELECT AVG(s.salary) FROM salaries s) THEN 'Нет'
        ELSE 'Да'
    END AS "Больше ли общей средней ЗП"
FROM positions p
JOIN employees e ON p.id = e.position_id
JOIN salaries s ON s.employee_id = e.id
GROUP BY p.name;


-- Task 4:
-- 4)	Сделать представление, в котором собраны данные по должностям (Должность, в каких отделах встречается эта должность (в виде массива), 
-- список сотрудников, начавших работать в этом отделе не раньше 2021 года (Сгруппировать по отделам) (в формате JSON), 
-- средняя заработная плата по должности)

CREATE or replace VIEW all_positions_information AS
SELECT 
    p.name AS "Должность",
    ARRAY_AGG(DISTINCT d.name) AS "Отделы",
    json_object_agg(
        d.name,
        (
            SELECT json_agg(
                json_build_object(
                    'ФИО', e.first_name || ' ' || e.last_name,
                    'Дата начала', e.start_date
                )
            )
            FROM employees e
            JOIN employee_department ed ON e.id = ed.employee_id
            WHERE ed.department_id = d.id AND e.start_date >= '2021-01-01'
        )
    ) AS "Список сотрудников с начала 2021 года",
    ROUND(AVG(s.salary), 2) AS "Средняя ЗП"
FROM positions p
JOIN employees e ON p.id = e.position_id
JOIN employee_department ed ON e.id = ed.employee_id
JOIN departments d ON ed.department_id = d.id
JOIN salaries s ON e.id = s.employee_id
GROUP BY p.name;


select * from all_positions_information;