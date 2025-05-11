-- COMPLETE SQL SCRIPT FOR CompanyDB


-- ============================================================================
-- ========================================
-- METADATA
-- ========================================


-- 1. List all tables
SELECT name AS TableName, create_date
FROM sys.tables
ORDER BY name;


-- 2. List all columns in all tables
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length,
    c.is_nullable
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
JOIN sys.types ty ON c.user_type_id = ty.user_type_id
ORDER BY t.name, c.column_id;


-- 3. Row count per table
SELECT 
    t.NAME AS TableName,
    SUM(p.rows) AS RowCounts
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
GROUP BY t.NAME
ORDER BY RowCounts DESC;

-- 4. Primary keys for each table
SELECT 
    t.name AS TableName,
    c.name AS PrimaryKeyColumn
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id;


-- 5. Foreign key relationships
SELECT 
    f.name AS ForeignKey,
    OBJECT_NAME(f.parent_object_id) AS ChildTable,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ChildColumn,
    OBJECT_NAME(f.referenced_object_id) AS ParentTable,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ParentColumn
FROM sys.foreign_keys f
JOIN sys.foreign_key_columns fc ON f.object_id = fc.constraint_object_id;


-- 6. Indexes on tables
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
ORDER BY t.name, i.name;


-- 7. Table sizes
EXEC sp_MSforeachtable 'EXEC sp_spaceused [?]';


-- 8. Recently modified tables
SELECT 
    name AS TableName,
    modify_date
FROM sys.tables
ORDER BY modify_date DESC;


-- 9. Identity columns
SELECT 
    t.name AS TableName,
    c.name AS IdentityColumn
FROM sys.columns c
JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.is_identity = 1;


-- 10. Current database properties
SELECT 
    name,
    state_desc,
    recovery_model_desc,
    create_date
FROM sys.databases
WHERE name = 'CompanyDB';

--11. List all views (basic)
SELECT name AS ViewName
FROM sys.views
ORDER BY name;


--12. List views with schema and creation date
SELECT 
    s.name AS SchemaName,
    v.name AS ViewName,
    v.create_date
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
ORDER BY v.name;

-- 13. View definition (see SQL code inside a view)
SELECT 
    OBJECT_NAME(object_id) AS ViewName,
    definition
FROM sys.sql_modules
WHERE OBJECTPROPERTY(object_id, 'IsView') = 1;

--14. Alternative using INFORMATION_SCHEMA
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_NAME;

--15. To See All Clustered Indexes (Including on Views)
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    o.name AS ObjectName,
    o.type_desc AS ObjectType,
    s.name AS SchemaName
FROM sys.indexes i
JOIN sys.objects o ON i.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE i.type_desc = 'CLUSTERED';



-- ========================================
-- DATABASE AND TABLES
-- ========================================
-- STEP 1: CREATE DATABASE
CREATE DATABASE CompanyDB;
GO

USE CompanyDB;
GO

-- STEP 2: TABLES
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100)
);

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100),
    DepartmentID INT,
    HireDate DATE DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1,
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

CREATE TABLE Projects (
    ProjectID INT PRIMARY KEY IDENTITY(1,1),
    ProjectName NVARCHAR(100),
    StartDate DATE,
    EndDate DATE
);

CREATE TABLE Assignments (
    AssignmentID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT,
    ProjectID INT,
    AssignedDate DATE,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (ProjectID) REFERENCES Projects(ProjectID)
);

CREATE TABLE Salaries (
    EmployeeID INT PRIMARY KEY,
    BaseSalary DECIMAL(10,2),
    Bonus DECIMAL(10,2),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE Promotions (
    PromotionID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT,
    PromotionDate DATE,
    NewTitle NVARCHAR(100),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

CREATE TABLE Skills (
    SkillID INT PRIMARY KEY IDENTITY(1,1),
    SkillName NVARCHAR(100)
);

CREATE TABLE EmployeeSkills (
    EmployeeID INT,
    SkillID INT,
    PRIMARY KEY (EmployeeID, SkillID),
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (SkillID) REFERENCES Skills(SkillID)
);

CREATE TABLE Offices (
    OfficeID INT PRIMARY KEY IDENTITY(1,1),
    OfficeLocation NVARCHAR(100),
    Capacity INT
);

CREATE TABLE Attendance (
    AttendanceID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT,
    CheckIn DATETIME,
    CheckOut DATETIME,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

-- STEP 3: INSERT SAMPLE DATA
-- Departments
INSERT INTO Departments (DepartmentName) VALUES ('IT'), ('HR'), ('Finance'),('Marketing'),('Operations'),('Legal'),('Logistics'),('Procurement'),('Customer Service'),('R&D');

-- Employees
INSERT INTO Employees (Name, DepartmentID) VALUES 
('Alice Johnson', 1),
('Bob Smith', 2),
('Charlie Brown', 1),
('Diana Prince', 3),
('Evan Stone', 1),
('Fiona Adams', 2),
('George Hall', 3),
('Hannah Lee', 4),
('Isaac Grant', 5),
('Julia Knight', 6);

-- Projects
INSERT INTO Projects (ProjectName) VALUES 
('Migration Project'),
('ERP Implementation'),
('Security Upgrade'),
('Cloud Migration'),
('Mobile App Dev'),
('Compliance Review'),
('Customer Portal'),
('Website Redesign'),
('Data Warehouse Build'),
('AI Integration');

-- Assignments
INSERT INTO Assignments (EmployeeID, ProjectID, AssignedDate) VALUES 
(1, 1, '2024-06-01'),
(1, 2, '2024-06-15'),
(2, 3, '2024-06-10'),
(3, 1, '2024-06-05'),
(4, 2, '2024-06-20'),
(5, 4, '2024-06-25'),
(6, 5, '2024-06-30'),
(7, 6, '2024-07-02'),
(8, 7, '2024-07-05'),
(9, 8, '2024-07-10');

-- Salaries
INSERT INTO Salaries (EmployeeID, BaseSalary, Bonus) VALUES 
(1, 60000, 5000),
(2, 50000, 3000),
(3, 55000, 4000),
(4, 65000, 6000);

--MOre data in Salaries
MERGE Salaries AS Target
USING (VALUES
(5, 48000, 2500),
(6, 52000, 2700),
(7, 58000, 3200),
(8, 61000, 3500),
(9, 57000, 3100),
(10, 53000, 2900)
) AS Source(EmployeeID, BaseSalary, Bonus)
ON Target.EmployeeID = Source.EmployeeID
WHEN MATCHED THEN
    UPDATE SET BaseSalary = Source.BaseSalary, Bonus = Source.Bonus
WHEN NOT MATCHED THEN
    INSERT (EmployeeID, BaseSalary, Bonus)
    VALUES (Source.EmployeeID, Source.BaseSalary, Source.Bonus);


INSERT INTO Salaries (EmployeeID, BaseSalary, Bonus)
SELECT * FROM (VALUES
(5, 48000, 2500),
(6, 52000, 2700),
(7, 58000, 3200),
(8, 61000, 3500),
(9, 57000, 3100),
(10, 53000, 2900)
) AS NewS(EmployeeID, BaseSalary, Bonus)
WHERE NOT EXISTS (
    SELECT 1 FROM Salaries S WHERE S.EmployeeID = NewS.EmployeeID
);


-- Promotions
INSERT INTO Promotions (EmployeeID, PromotionDate, NewTitle) VALUES 
(1, '2024-12-01', 'Senior Analyst'),
(3, '2025-01-15', 'Team Lead'),
(2, '2025-03-01', 'HR Specialist'),
(4, '2025-04-01', 'Finance Manager'),
(5, '2025-04-15', 'IT Coordinator');

-- Skills
INSERT INTO Skills (SkillName) VALUES ('SQL'), ('C#'), ('Excel'), ('Power BI'), ('Python'), ('Java'), ('PowerShell'), ('Communication'), ('Scrum'), ('SQL Server');

-- EmployeeSkills
INSERT INTO EmployeeSkills (EmployeeID, SkillID) VALUES 
(1, 1), (1, 2), (2, 3), (3, 1), (3, 5), (4, 3),(5, 1),(6, 4),(7, 2),(8, 5),(9, 6),(10, 7);

-- Offices
INSERT INTO Offices (OfficeLocation, Capacity) VALUES 
('New York', 100), 
('London', 80), 
('Berlin', 60),
('Paris', 75),
('Tokyo', 95),
('Madrid', 50),
('Chicago', 85),
('Toronto', 70),
('Rome', 60),
('Dubai', 90);

-- Attendance
INSERT INTO Attendance (EmployeeID, CheckIn, CheckOut) VALUES 
(1, '2025-05-01 09:00:00', '2025-05-01 17:00:00'),
(2, '2025-05-01 08:45:00', '2025-05-01 16:45:00'),
(3, '2025-05-02 09:00:00', '2025-05-02 17:00:00'),
(4, '2025-05-02 08:45:00', '2025-05-02 16:45:00'),
(5, '2025-05-02 09:15:00', '2025-05-02 17:15:00'),
(6, '2025-05-03 09:00:00', '2025-05-03 17:00:00'),
(7, '2025-05-03 08:45:00', '2025-05-03 16:45:00'),
(8, '2025-05-04 09:00:00', '2025-05-04 17:00:00'),
(9, '2025-05-04 08:45:00', '2025-05-04 16:45:00'),
(10, '2025-05-05 09:00:00', '2025-05-05 17:00:00');




-- ========================================
-- Q and A
-- ========================================

-- 1. List all employees with their department names
SELECT E.Name, D.DepartmentName
FROM Employees E
JOIN Departments D ON E.DepartmentID = D.DepartmentID;


-- 2. Find employees hired in the last 30 days
SELECT * 
FROM Employees
WHERE HireDate >= DATEADD(DAY, -30, GETDATE());


-- 3. Show each employee's total compensation (salary + bonus)
SELECT E.Name, S.BaseSalary + S.Bonus AS TotalCompensation
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- 4. List departments with more than 1 employee
SELECT D.DepartmentName, COUNT(E.EmployeeID) AS NumEmployees
FROM Departments D
JOIN Employees E ON D.DepartmentID = E.DepartmentID
GROUP BY D.DepartmentName
HAVING COUNT(E.EmployeeID) > 1;


-- 5. Employees assigned to more than one project
SELECT E.Name, COUNT(A.ProjectID) AS ProjectCount
FROM Employees E
JOIN Assignments A ON E.EmployeeID = A.EmployeeID
GROUP BY E.Name
HAVING COUNT(A.ProjectID) > 1;


-- 6. List projects that have not ended yet
SELECT ProjectName
FROM Projects
WHERE EndDate IS NULL OR EndDate > GETDATE();


-- 7. Find employees who are not assigned to any project
SELECT Name
FROM Employees
WHERE EmployeeID NOT IN (
    SELECT DISTINCT EmployeeID FROM Assignments
);

-- 8. Average bonus by department
SELECT D.DepartmentName, AVG(S.Bonus) AS AvgBonus
FROM Salaries S
JOIN Employees E ON S.EmployeeID = E.EmployeeID
JOIN Departments D ON E.DepartmentID = D.DepartmentID
GROUP BY D.DepartmentName;


-- 9. Total number of employees per project
SELECT P.ProjectName, COUNT(A.EmployeeID) AS TotalEmployees
FROM Projects P
LEFT JOIN Assignments A ON P.ProjectID = A.ProjectID
GROUP BY P.ProjectName;


-- 10. Show all projects and the names of employees assigned
SELECT P.ProjectName, E.Name AS AssignedEmployee
FROM Projects P
JOIN Assignments A ON P.ProjectID = A.ProjectID
JOIN Employees E ON A.EmployeeID = E.EmployeeID;


-- 11. List employees with a bonus greater than 10% of base salary
SELECT E.Name, S.BaseSalary, S.Bonus
FROM Salaries S
JOIN Employees E ON S.EmployeeID = E.EmployeeID
WHERE S.Bonus > 0.1 * S.BaseSalary;


-- 12. Rank employees by total compensation
SELECT 
    E.Name, 
    S.BaseSalary + S.Bonus AS TotalComp,
    RANK() OVER (ORDER BY S.BaseSalary + S.Bonus DESC) AS CompensationRank
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;

--  Each row shows the cumulative sum so far.
SELECT 
    BaseSalary,
    SUM(BaseSalary) OVER (ORDER BY BaseSalary) AS RunningTotal
FROM Salaries;



--
SELECT 
    Name,
    HireDate,
    RANK() OVER (ORDER BY HireDate ASC) AS HireRank
FROM Employees;

--
SELECT 
    BaseSalary,
    AVG(BaseSalary) OVER () AS CompanyAvgSalary
FROM Salaries;


--
SELECT 
    BaseSalary,
    SUM(BaseSalary) OVER (ORDER BY BaseSalary) AS RunningTotal
FROM Salaries;

-- Shows the salary from the previous and next row.
SELECT 
    BaseSalary,
    LAG(BaseSalary) OVER (ORDER BY BaseSalary) AS PrevSalary,
    LEAD(BaseSalary) OVER (ORDER BY BaseSalary) AS NextSalary
FROM Salaries;

--


-- 13. Find departments that have no employees
SELECT DepartmentName
FROM Departments
WHERE DepartmentID NOT IN (
    SELECT DISTINCT DepartmentID FROM Employees
);


-- 14. Most recent hire in each department
SELECT D.DepartmentName, E.Name, E.HireDate
FROM Employees E
JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE E.HireDate = (
    SELECT MAX(E2.HireDate)
    FROM Employees E2
    WHERE E2.DepartmentID = E.DepartmentID
);


-- 15. Duration of each project in days (if ended)
SELECT ProjectName, DATEDIFF(DAY, StartDate, EndDate) AS DurationDays
FROM Projects
WHERE EndDate IS NOT NULL;


-- 16. CTE: Employees earning above dept avg
WITH DeptAvg AS (
    SELECT D.DepartmentID, AVG(S.BaseSalary) AS AvgSalary
    FROM Employees E
    JOIN Salaries S ON E.EmployeeID = S.EmployeeID
    JOIN Departments D ON E.DepartmentID = D.DepartmentID
    GROUP BY D.DepartmentID
)
SELECT E.Name, D.DepartmentName, S.BaseSalary, DA.AvgSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
JOIN Departments D ON E.DepartmentID = D.DepartmentID
JOIN DeptAvg DA ON D.DepartmentID = DA.DepartmentID
WHERE S.BaseSalary > DA.AvgSalary;


-- 17. Running total of bonuses by department
SELECT 
    D.DepartmentName,
    E.Name,
    S.Bonus,
    SUM(S.Bonus) OVER (PARTITION BY D.DepartmentID ORDER BY E.Name) AS RunningBonus
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
JOIN Departments D ON E.DepartmentID = D.DepartmentID;


-- 18. Recursive CTE: Calendar dates for next 10 days
WITH Dates AS (
    SELECT CAST(GETDATE() AS DATE) AS TheDate
    UNION ALL
    SELECT DATEADD(DAY, 1, TheDate)
    FROM Dates
    WHERE TheDate < DATEADD(DAY, 9, CAST(GETDATE() AS DATE))
)
SELECT * FROM Dates;

--Simpler CTE: List employees hired after 2024
WITH RecentHires AS (
    SELECT Name, HireDate
    FROM Employees
    WHERE HireDate > '2025-01-01'
)
SELECT * FROM RecentHires;



-- 19. Employee(s) with the highest bonus
SELECT Name, Bonus
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
WHERE S.Bonus = (
    SELECT MAX(Bonus) FROM Salaries
);


-- 20. Count of higher-paid colleagues in same department
SELECT E1.Name, D.DepartmentName,
       COUNT(E2.EmployeeID) AS ColleaguesWithHigherPay
FROM Employees E1
JOIN Salaries S1 ON E1.EmployeeID = S1.EmployeeID
JOIN Departments D ON E1.DepartmentID = D.DepartmentID
JOIN Employees E2 ON E1.DepartmentID = E2.DepartmentID
JOIN Salaries S2 ON E2.EmployeeID = S2.EmployeeID
WHERE S2.BaseSalary > S1.BaseSalary
GROUP BY E1.Name, D.DepartmentName;


-- 21. Top 3 earners per department
SELECT *
FROM (
    SELECT E.Name, D.DepartmentName, S.BaseSalary,
           RANK() OVER (PARTITION BY D.DepartmentID ORDER BY S.BaseSalary DESC) AS RankInDept
    FROM Employees E
    JOIN Salaries S ON E.EmployeeID = S.EmployeeID
    JOIN Departments D ON E.DepartmentID = D.DepartmentID
) Ranked
WHERE RankInDept <= 3;


-- 22. Projects longer than average
SELECT ProjectName, StartDate, EndDate,
       DATEDIFF(DAY, StartDate, EndDate) AS Duration
FROM Projects
WHERE EndDate IS NOT NULL AND
      DATEDIFF(DAY, StartDate, EndDate) > (
          SELECT AVG(DATEDIFF(DAY, StartDate, EndDate))
          FROM Projects WHERE EndDate IS NOT NULL
      );


-- 23. Employees who worked on all projects
SELECT E.Name
FROM Employees E
JOIN Assignments A ON E.EmployeeID = A.EmployeeID
GROUP BY E.EmployeeID, E.Name
HAVING COUNT(DISTINCT A.ProjectID) = (SELECT COUNT(*) FROM Projects);


-- 24. Department with highest salary payout
SELECT TOP 1 D.DepartmentName, SUM(S.BaseSalary + S.Bonus) AS TotalPayout
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
JOIN Departments D ON E.DepartmentID = D.DepartmentID
GROUP BY D.DepartmentName
ORDER BY TotalPayout DESC;


-- 25. Employees whose name starts and ends with same letter
SELECT Name
FROM Employees
WHERE LEFT(Name,1) = RIGHT(Name,1);


-- 26. Employee working on most projects
SELECT TOP 1 E.Name, COUNT(A.ProjectID) AS ProjectCount
FROM Employees E
JOIN Assignments A ON E.EmployeeID = A.EmployeeID
GROUP BY E.Name
ORDER BY ProjectCount DESC;


-- 27. Employees hired in leap year
SELECT * 
FROM Employees
WHERE YEAR(HireDate) % 4 = 0 AND 
      (YEAR(HireDate) % 100 != 0 OR YEAR(HireDate) % 400 = 0);

-- 28. Departments where all employees are active
SELECT D.DepartmentName
FROM Departments D
WHERE NOT EXISTS (
    SELECT 1
    FROM Employees E
    WHERE E.DepartmentID = D.DepartmentID AND E.IsActive = 0
);


-- 29. Average number of projects per employee
SELECT AVG(ProjectCount * 1.0) AS AvgProjects
FROM (
    SELECT EmployeeID, COUNT(ProjectID) AS ProjectCount
    FROM Assignments
    GROUP BY EmployeeID
) AS Sub;


-- 30. Employee-projects summary: comma-separated project names
SELECT E.Name,
       STRING_AGG(P.ProjectName, ', ') AS Projects
FROM Employees E
JOIN Assignments A ON E.EmployeeID = A.EmployeeID
JOIN Projects P ON A.ProjectID = P.ProjectID
GROUP BY E.Name;


-- ================30 Q=======================
--1–10: Data Exploration & Cleansing
-- 1. View distinct values for data validation
SELECT DISTINCT DepartmentName FROM Departments;


-- 2. Null check and cleanup
SELECT * FROM Employees WHERE DepartmentID IS NULL;


-- 3. Remove duplicates
SELECT Name, COUNT(*) FROM Employees GROUP BY Name HAVING COUNT(*) > 1;


-- 4. Format dates for Qlik use
SELECT CONVERT(VARCHAR, HireDate, 23) AS FormattedDate FROM Employees;


-- 5. Join for reporting tables (employee-department)
SELECT E.Name, D.DepartmentName
FROM Employees E
JOIN Departments D ON E.DepartmentID = D.DepartmentID;


-- 6. Left join to find unmatched rows (data quality)
SELECT E.Name, D.DepartmentName
FROM Employees E
LEFT JOIN Departments D ON E.DepartmentID = D.DepartmentID
WHERE D.DepartmentID IS NULL;


-- 7. Convert nulls for Qlik (prevent empty cells)
SELECT ISNULL(Bonus, 0) AS Bonus FROM Salaries;


-- 8. Extract year/month for time-based reporting
SELECT YEAR(HireDate) AS HireYear, MONTH(HireDate) AS HireMonth FROM Employees;


-- 9. Lookup total rows for dashboard count
SELECT COUNT(*) AS TotalEmployees FROM Employees;


-- 10. Use COALESCE for multi-level fallback
SELECT COALESCE(NewTitle, 'Not Promoted') AS Title FROM Promotions;


--11–20: Aggregation, GROUP BY, HAVING

-- 11. Count employees per department
SELECT DepartmentID, COUNT(*) AS EmpCount FROM Employees GROUP BY DepartmentID;


-- 12. Total compensation (Base + Bonus)
SELECT EmployeeID, BaseSalary + Bonus AS TotalPay FROM Salaries;


-- 13. Average salary per department
SELECT E.DepartmentID, AVG(S.BaseSalary) AS AvgSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
GROUP BY E.DepartmentID;


-- 14. Group and filter with HAVING
SELECT ProjectID, COUNT(*) AS Assignments
FROM Assignments
GROUP BY ProjectID
HAVING COUNT(*) > 2;


-- 15. Top N departments by employee count
SELECT TOP 5 DepartmentID, COUNT(*) AS EmpCount
FROM Employees
GROUP BY DepartmentID
ORDER BY EmpCount DESC;


-- 16. Number of employees by HireYear
SELECT YEAR(HireDate) AS HireYear, COUNT(*) AS TotalHires
FROM Employees
GROUP BY YEAR(HireDate);


-- 17. Sum of bonus per department
SELECT E.DepartmentID, SUM(S.Bonus)
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
GROUP BY E.DepartmentID;


-- 18. Detect departments without employees
SELECT DepartmentName
FROM Departments
WHERE DepartmentID NOT IN (SELECT DISTINCT DepartmentID FROM Employees);


-- 19. Compare department salary to average
WITH DeptAvg AS (
  SELECT DepartmentID, AVG(BaseSalary) AS AvgSalary
  FROM Employees E
  JOIN Salaries S ON E.EmployeeID = S.EmployeeID
  GROUP BY DepartmentID
)
SELECT E.Name, S.BaseSalary, DA.AvgSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
JOIN DeptAvg DA ON E.DepartmentID = DA.DepartmentID
WHERE S.BaseSalary > DA.AvgSalary;


-- 20. List all departments with zero or more employees
SELECT D.DepartmentName, COUNT(E.EmployeeID) AS EmpCount
FROM Departments D
LEFT JOIN Employees E ON D.DepartmentID = E.DepartmentID
GROUP BY D.DepartmentName;


---21–30: Window Functions & Reporting Logic
-- 21. Rank employees by salary
SELECT Name, BaseSalary, RANK() OVER (ORDER BY BaseSalary DESC) AS SalaryRank
FROM Salaries S
JOIN Employees E ON E.EmployeeID = S.EmployeeID;


-- 22. Calculate percent of total salary
SELECT 
  E.Name,
  S.BaseSalary,
  S.BaseSalary * 1.0 / SUM(S.BaseSalary) OVER () AS SalaryPct
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- 23. Running total of bonuses
SELECT 
  E.Name, S.Bonus,
  SUM(S.Bonus) OVER (ORDER BY E.Name) AS RunningTotalBonus
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- 24. Flag employees earning above department average
SELECT E.Name, S.BaseSalary,
       CASE 
         WHEN S.BaseSalary > AVG(S.BaseSalary) OVER (PARTITION BY E.DepartmentID)
         THEN 'Above Avg' ELSE 'Below Avg'
       END AS SalaryLevel
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- 25. Get latest promotion per employee
SELECT E.Name, P.NewTitle, P.PromotionDate
FROM Employees E
JOIN Promotions P ON E.EmployeeID = P.EmployeeID
WHERE P.PromotionDate = (
    SELECT MAX(P2.PromotionDate)
    FROM Promotions P2
    WHERE P2.EmployeeID = P.EmployeeID
);


-- 26. Duration of projects (days)
SELECT ProjectName, DATEDIFF(DAY, StartDate, EndDate) AS Duration
FROM Projects
WHERE EndDate IS NOT NULL;


-- 27. List employees assigned to all projects
SELECT E.Name
FROM Employees E
JOIN Assignments A ON E.EmployeeID = A.EmployeeID
GROUP BY E.EmployeeID, E.Name
HAVING COUNT(DISTINCT A.ProjectID) = (SELECT COUNT(*) FROM Projects);


-- 28. Create derived table for Qlik drill-down
SELECT D.DepartmentName, AVG(S.BaseSalary) AS AvgDeptSalary
FROM Departments D
JOIN Employees E ON D.DepartmentID = E.DepartmentID
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
GROUP BY D.DepartmentName;


-- 29. Count employees per bonus range
SELECT 
  CASE 
    WHEN Bonus < 1000 THEN 'Low'
    WHEN Bonus BETWEEN 1000 AND 5000 THEN 'Medium'
    ELSE 'High'
  END AS BonusBand,
  COUNT(*) AS CountEmployees
FROM Salaries
GROUP BY 
  CASE 
    WHEN Bonus < 1000 THEN 'Low'
    WHEN Bonus BETWEEN 1000 AND 5000 THEN 'Medium'
    ELSE 'High'
  END;


-- 30. Validate salary gaps between colleagues
SELECT A.Name, B.Name, A.BaseSalary - B.BaseSalary AS SalaryGap
FROM Employees E1
JOIN Salaries A ON E1.EmployeeID = A.EmployeeID
JOIN Employees E2 ON E1.DepartmentID = E2.DepartmentID AND E1.EmployeeID <> E2.EmployeeID
JOIN Salaries B ON E2.EmployeeID = B.EmployeeID;


-- ================

--INTERVIU
-- ✅ 1. INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL JOIN

-- 1.1 INNER JOIN: Get employees with matching departments

SELECT E.Name, D.DepartmentName
FROM Employees E
INNER JOIN Departments D ON E.DepartmentID = D.DepartmentID;


-- 1.2 LEFT JOIN: Get all employees, even those without a department

SELECT E.Name, D.DepartmentName
FROM Employees E
LEFT JOIN Departments D ON E.DepartmentID = D.DepartmentID;


-- ✅ 2. GROUP BY with COUNT(), SUM(), AVG(), etc.

-- 2.1 Count of employees per department
SELECT DepartmentID, COUNT(*) AS TotalEmployees
FROM Employees
GROUP BY DepartmentID;

-- 2.2 Average salary per department
SELECT E.DepartmentID, AVG(S.BaseSalary) AS AvgSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
GROUP BY E.DepartmentID;


-- ✅ 3. HAVING clause

-- 3.1 Departments with more than 1 employee
SELECT DepartmentID, COUNT(*) AS EmpCount
FROM Employees
GROUP BY DepartmentID
HAVING COUNT(*) > 1;


-- 3.2 Projects with at least 2 assignments
SELECT ProjectID, COUNT(*) AS AssignmentCount
FROM Assignments
GROUP BY ProjectID
HAVING COUNT(*) >= 2;


-- ✅ 4. DISTINCT vs GROUP BY

-- 4.1 DISTINCT: Unique departments from Employees table
SELECT DISTINCT DepartmentID FROM Employees;


-- 4.2 GROUP BY with COUNT: Number of employees per department
SELECT DepartmentID, COUNT(*) FROM Employees GROUP BY DepartmentID;


-- ✅ 5. Subqueries

-- 5.1 Subquery in SELECT: Show company-wide average salary next to each name
SELECT Name,
    (SELECT AVG(BaseSalary) FROM Salaries) AS AvgCompanySalary
FROM Employees;


-- 5.2 Subquery in WHERE: Employees with bonuses over 4000
SELECT Name FROM Employees
WHERE EmployeeID IN (SELECT EmployeeID FROM Salaries WHERE Bonus > 4000)


-- ✅ 6. Correlated subqueries

-- 6.1 Employees with salary above their department average
SELECT E.Name
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
WHERE S.BaseSalary > (
    SELECT AVG(S2.BaseSalary)
    FROM Employees E2
    JOIN Salaries S2 ON E2.EmployeeID = S2.EmployeeID
    WHERE E2.DepartmentID = E.DepartmentID
);


-- 6.2 Employees with the highest salary in their department
SELECT E.Name, S.BaseSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
WHERE S.BaseSalary >= ALL (
    SELECT S2.BaseSalary
    FROM Employees E2
    JOIN Salaries S2 ON E2.EmployeeID = S2.EmployeeID
    WHERE E2.DepartmentID = E.DepartmentID
);


-- ✅ 7. CASE expressions

-- 7.1 Categorize salaries as High or Low
SELECT E.Name,
    CASE WHEN S.BaseSalary > 55000 THEN 'High' ELSE 'Low' END AS SalaryLevel
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- 7.2 Mark attendance as full or half day
SELECT A.EmployeeID,
    CASE 
        WHEN DATEDIFF(HOUR, A.CheckIn, A.CheckOut) >= 8 THEN 'Full Day'
        ELSE 'Half Day'
    END AS AttendanceType
FROM Attendance A;


-- ✅ 8. TOP and OFFSET-FETCH (pagination)

-- 8.1 Top 2 highest-paid employees
SELECT TOP 2 E.Name, S.BaseSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
ORDER BY S.BaseSalary DESC;


-- 8.2 Skip 2 rows and fetch next 2 (pagination)
SELECT E.Name, S.BaseSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
ORDER BY S.BaseSalary DESC
OFFSET 2 ROWS FETCH NEXT 2 ROWS ONLY;


-- ✅ 9. UNION vs UNION ALL

-- 9.1 UNION: Combine and remove duplicates
SELECT DepartmentID FROM Employees
UNION
SELECT DepartmentID FROM Departments;


-- 9.2 UNION ALL: Combine and keep duplicates
SELECT DepartmentID FROM Employees
UNION ALL
SELECT DepartmentID FROM Departments;


-- ✅ 10. EXISTS vs NOT EXISTS

-- 10.1 EXISTS: Employees with promotions
SELECT Name FROM Employees E
WHERE EXISTS (
    SELECT 1 FROM Promotions P WHERE P.EmployeeID = E.EmployeeID
);


-- 10.2 NOT EXISTS: Employees with no attendance records
SELECT Name FROM Employees E
WHERE NOT EXISTS (
    SELECT 1 FROM Attendance A WHERE A.EmployeeID = E.EmployeeID
);


-- ✅ 11. CTEs (Common Table Expressions)

-- 11.1 Simple CTE for employee counts per department
WITH DeptCounts AS (
    SELECT DepartmentID, COUNT(*) AS EmpCount
    FROM Employees
    GROUP BY DepartmentID
)
SELECT * FROM DeptCounts WHERE EmpCount > 1;


-- 11.2 CTE to calculate average salary per department
WITH DeptAvg AS (
    SELECT E.DepartmentID, AVG(S.BaseSalary) AS AvgSalary
    FROM Employees E
    JOIN Salaries S ON E.EmployeeID = S.EmployeeID
    GROUP BY E.DepartmentID
)
SELECT * FROM DeptAvg;


-- ✅ 12. Window functions

-- 12.1 Rank employees by salary
SELECT E.Name, S.BaseSalary,
       ROW_NUMBER() OVER (ORDER BY S.BaseSalary DESC) AS RowNum
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- 12.2 LEAD and LAG to get previous/next salaries
SELECT E.Name, S.BaseSalary,
       LAG(S.BaseSalary) OVER (ORDER BY S.BaseSalary) AS PrevSalary,
       LEAD(S.BaseSalary) OVER (ORDER BY S.BaseSalary) AS NextSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- ✅ 13. Date and time functions

-- 13.1 Add 30 days to today's date
SELECT GETDATE() AS Today, DATEADD(DAY, 30, GETDATE()) AS In30Days;


-- 13.2 Calculate hours worked from CheckIn/CheckOut
SELECT EmployeeID, DATEDIFF(HOUR, CheckIn, CheckOut) AS HoursWorked
FROM Attendance;

-- ✅ 14. String functions

-- 14.1 Extract first name using CHARINDEX
SELECT Name, LEFT(Name, CHARINDEX(' ', Name)-1) AS FirstName
FROM Employees;


-- 14.2 Replace job title text
SELECT NewTitle, REPLACE(NewTitle, 'Analyst', 'Consultant') AS UpdatedTitle
FROM Promotions;


-- ✅ 15. Data type conversion

-- 15.1 Convert date to string
SELECT CONVERT(VARCHAR, HireDate, 103) AS HireDateString
FROM Employees;


-- 15.2 Cast decimal to integer
SELECT BaseSalary, CAST(BaseSalary AS INT) AS SalaryRounded
FROM Salaries;


-- ✅ 16. ISNULL() vs COALESCE()

-- 16.1 ISNULL to default bonus value
SELECT EmployeeID, ISNULL(Bonus, 0) AS SafeBonus
FROM Salaries;


-- 16.2 COALESCE to default promotion title
SELECT EmployeeID, COALESCE(NewTitle, 'Not Promoted') AS Title
FROM Promotions;


-- ✅ 17. STRING_AGG()

-- 17.1 Concatenate all skills
SELECT STRING_AGG(SkillName, ', ') AS AllSkills
FROM Skills;


-- 17.2 List skills per employee
SELECT E.Name, STRING_AGG(S.SkillName, ', ') AS Skills
FROM Employees E
JOIN EmployeeSkills ES ON E.EmployeeID = ES.EmployeeID
JOIN Skills S ON ES.SkillID = S.SkillID
GROUP BY E.Name


-- ✅ 18. Temporary tables

-- 18.1 Create temp table for employees from Dept 1
SELECT * INTO #TempEmployees
FROM Employees
WHERE DepartmentID = 1;


-- 18.2 Query from temp table
SELECT * FROM #TempEmployees;


-- ✅ 19. Table variables

-- 19.1 Declare and populate a table variable
DECLARE @TopSalaries TABLE (Name NVARCHAR(100), Salary DECIMAL(10,2));

INSERT INTO @TopSalaries
SELECT E.Name, S.BaseSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
WHERE S.BaseSalary > 55000;


-- 19.2 Query from table variable
SELECT * FROM @TopSalaries;


-- ✅ 20. Derived tables

-- 20.1 Use subquery to get avg salary
SELECT DeptAvg.DepartmentID, DeptAvg.AvgSalary
FROM (
    SELECT E.DepartmentID, AVG(S.BaseSalary) AS AvgSalary
    FROM Employees E
    JOIN Salaries S ON E.EmployeeID = S.EmployeeID
    GROUP BY E.DepartmentID
) AS DeptAvg;


-- 20.2 Filter top earners (above avg)
SELECT E.Name, E.DepartmentID, S.BaseSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID
WHERE S.BaseSalary > (
    SELECT AVG(S2.BaseSalary)
    FROM Salaries S2
);


-- ✅ Remaining topics 21–30 would continue here

-- ✅ 21. Self-joins

-- 21.1 Employees in the same department as 'Alice Johnson'
SELECT E1.Name, E2.Name AS Colleague
FROM Employees E1
JOIN Employees E2 ON E1.DepartmentID = E2.DepartmentID
WHERE E1.Name = 'Alice Johnson' AND E2.Name <> 'Alice Johnson';


-- 21.2 Compare salaries between employees in same department
SELECT A.Name AS Emp1, B.Name AS Emp2,
       A.BaseSalary - B.BaseSalary AS SalaryDifference
FROM Employees E1
JOIN Salaries A ON E1.EmployeeID = A.EmployeeID
JOIN Employees E2 ON E1.DepartmentID = E2.DepartmentID AND E1.EmployeeID <> E2.EmployeeID
JOIN Salaries B ON E2.EmployeeID = B.EmployeeID;


-- ✅ 22. Aggregate filtering (“Top N per group”)

-- 22.1 Top 1 highest-paid employee per department
SELECT * FROM (
    SELECT E.Name, E.DepartmentID, S.BaseSalary,
           RANK() OVER (PARTITION BY E.DepartmentID ORDER BY S.BaseSalary DESC) AS rnk
    FROM Employees E
    JOIN Salaries S ON E.EmployeeID = S.EmployeeID
) Ranked
WHERE rnk = 1;


-- 22.2 Top 2 recently promoted employees per department
SELECT * FROM (
    SELECT E.Name, P.NewTitle, P.PromotionDate, E.DepartmentID,
           ROW_NUMBER() OVER (PARTITION BY E.DepartmentID ORDER BY P.PromotionDate DESC) AS RowNum
    FROM Employees E
    JOIN Promotions P ON E.EmployeeID = P.EmployeeID
) AS Sub
WHERE RowNum <= 2;


-- ✅ 23. CROSS APPLY and OUTER APPLY

-- 23.1 CROSS APPLY – latest attendance per employee
SELECT E.Name, A.CheckIn, A.CheckOut
FROM Employees E
CROSS APPLY (
    SELECT TOP 1 A.CheckIn, A.CheckOut
    FROM Attendance A
    WHERE A.EmployeeID = E.EmployeeID
    ORDER BY A.CheckIn DESC
) A;


-- 23.2 OUTER APPLY – include employees without attendance
SELECT E.Name, A.CheckIn, A.CheckOut
FROM Employees E
OUTER APPLY (
    SELECT TOP 1 A.CheckIn, A.CheckOut
    FROM Attendance A
    WHERE A.EmployeeID = E.EmployeeID
    ORDER BY A.CheckIn DESC
) A;


-- ✅ 24. Scalar and inline table-valued functions

-- 24.1 Scalar function to calculate 10% bonus
-- (Function must be created before running this query)
-- CREATE FUNCTION dbo.CalcBonus(@Salary DECIMAL(10,2)) RETURNS DECIMAL(10,2) AS BEGIN RETURN @Salary * 0.1 END;

SELECT Name, dbo.CalcBonus(BaseSalary) AS BonusEst
FROM Employees E JOIN Salaries S ON E.EmployeeID = S.EmployeeID;


-- 24.2 Inline table-valued function to get promotions
-- (Function must be created before running this query)
-- CREATE FUNCTION dbo.GetPromotions(@EmpID INT) RETURNS TABLE AS RETURN (SELECT NewTitle, PromotionDate FROM Promotions WHERE EmployeeID = @EmpID);

SELECT E.Name, P.NewTitle, P.PromotionDate
FROM Employees E
CROSS APPLY dbo.GetPromotions(E.EmployeeID) AS P;


-- ✅ 25. Index basics (clustered vs non-clustered)

-- 25.1 Create non-clustered index on Salary
CREATE NONCLUSTERED INDEX idx_BaseSalary ON Salaries(BaseSalary);


-- 25.2 Create clustered index on EmployeeID (if not already the PK)
CREATE CLUSTERED INDEX idx_EmpID ON Employees(EmployeeID);


-- View indexes
SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('Salaries');

-- ✅ 26. Error handling: TRY_CAST(), TRY_CONVERT(), TRY...CATCH

-- 26.1 TRY_CAST example
SELECT TRY_CAST('abc' AS INT) AS Result; -- Returns NULL instead of error

-- 26.2 TRY...CATCH block
BEGIN TRY
    SELECT 1 / 0;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS ErrorMsg;
END CATCH;


-- ✅ 27. Query performance basics: EXPLAIN, SET STATISTICS IO

-- 27.1 Execution plan (enable in SSMS)
SELECT * FROM Employees WHERE DepartmentID = 1;

-- 27.2 IO statistics
SET STATISTICS IO ON;
SELECT * FROM Employees WHERE DepartmentID = 1;
SET STATISTICS IO OFF;


-- ✅ 28. Updating with JOIN

-- 28.1 Update bonus for high earners
UPDATE S
SET S.Bonus = 6000
FROM Salaries S
JOIN Employees E ON S.EmployeeID = E.EmployeeID
WHERE S.BaseSalary > 55000;


-- 28.2 Assign department to employees with NULL DepartmentID
UPDATE E
SET DepartmentID = 1
FROM Employees E
WHERE E.DepartmentID IS NULL;


-- ✅ 29. MERGE statements (MERGE INTO)

-- 29.1 Merge salary updates
MERGE Salaries AS Target
USING (SELECT EmployeeID, 70000 AS NewSalary FROM Employees WHERE Name = 'Alice Johnson') AS Source
ON Target.EmployeeID = Source.EmployeeID
WHEN MATCHED THEN
    UPDATE SET BaseSalary = Source.NewSalary;


-- 29.2 Merge new promotions
MERGE Promotions AS Target
USING (SELECT 1 AS EmployeeID, 'Lead Analyst' AS NewTitle, GETDATE() AS PromotionDate) AS Source
ON Target.EmployeeID = Source.EmployeeID AND Target.NewTitle = Source.NewTitle
WHEN NOT MATCHED THEN
    INSERT (EmployeeID, NewTitle, PromotionDate)
    VALUES (Source.EmployeeID, Source.NewTitle, Source.PromotionDate);


-- ✅ 30. Data export/import basics

-- 30.1 BULK INSERT (ensure the file path is accessible and the server is configured)
BULK INSERT Employees
FROM 'C:\\Data\\employees.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\\n',
    FIRSTROW = 2
);

-- 30.2 Use OPENROWSET (requires configuration)
SELECT *
FROM OPENROWSET(
    BULK 'C:\\Data\\employees.csv',
    FORMAT = 'CSV',
    FIRSTROW = 2
) AS DataFile;

-- ============================================
-- ADVANCED/ OTHER
-- ============================================

-- ============================================
-- VIEW DEFINITIONS - CompanyDB
-- ============================================
-- List all views (basic)
SELECT name AS ViewName
FROM sys.views
ORDER BY name;


--List views with schema and creation date
SELECT 
    s.name AS SchemaName,
    v.name AS ViewName,
    v.create_date
FROM sys.views v
JOIN sys.schemas s ON v.schema_id = s.schema_id
ORDER BY v.name;

-- View definition (see SQL code inside a view)
SELECT 
    OBJECT_NAME(object_id) AS ViewName,
    definition
FROM sys.sql_modules
WHERE OBJECTPROPERTY(object_id, 'IsView') = 1;

--
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
ORDER BY TABLE_NAME;





-- 1. View: Employees with department names
CREATE VIEW vw_EmployeesWithDepartments AS
SELECT 
    E.EmployeeID,
    E.Name,
    D.DepartmentName,
    E.HireDate
FROM Employees E
JOIN Departments D ON E.DepartmentID = D.DepartmentID;
GO

SELECT * FROM vw_EmployeesWithDepartments

-- 2. View: Employee compensation (Base + Bonus)
CREATE VIEW vw_EmployeeCompensation AS
SELECT 
    E.Name,
    S.BaseSalary,
    S.Bonus,
    (S.BaseSalary + S.Bonus) AS TotalCompensation
FROM Employees E
JOIN Salaries S ON E.EmployeeID = S.EmployeeID;
GO


-- 3. View: Recent promotions since 2024
CREATE VIEW vw_RecentPromotions AS
SELECT 
    P.EmployeeID,
    E.Name,
    P.PromotionDate,
    P.NewTitle
FROM Promotions P
JOIN Employees E ON P.EmployeeID = E.EmployeeID
WHERE P.PromotionDate >= '2024-01-01';
GO

-- 4. View: Employee skills
CREATE VIEW vw_EmployeeSkills AS
SELECT 
    E.Name,
    S.SkillName
FROM EmployeeSkills ES
JOIN Employees E ON ES.EmployeeID = E.EmployeeID
JOIN Skills S ON ES.SkillID = S.SkillID;
GO

-- 5. View: Attendance durations in hours
CREATE VIEW vw_AttendanceHours AS
SELECT 
    A.EmployeeID,
    E.Name,
    A.CheckIn,
    A.CheckOut,
    DATEDIFF(HOUR, A.CheckIn, A.CheckOut) AS HoursWorked
FROM Attendance A
JOIN Employees E ON A.EmployeeID = E.EmployeeID;
GO
SELECT * FROM vw_AttendanceHours

--Indexed View for Department Salary Totals
-- Step 1: Create the view (must be in its own batch)
GO
CREATE VIEW vw_DepartmentSalaryTotals
WITH SCHEMABINDING
AS
SELECT 
    E.DepartmentID,
    COUNT_BIG(*) AS EmpCount,
    SUM(ISNULL(S.BaseSalary, 0)) AS TotalSalary
FROM dbo.Employees E
JOIN dbo.Salaries S ON E.EmployeeID = S.EmployeeID
GROUP BY E.DepartmentID;
GO


CREATE UNIQUE CLUSTERED INDEX IX_DepartmentSalaryTotals
ON vw_DepartmentSalaryTotals (DepartmentID);
GO


-- ==============================================
-- SQL Server Indexes - Explanation and Examples
-- For CompanyDB
-- ==============================================

-- ==============================================
-- What is an Index?
-- ----------------------------------------------
-- An index is a database object that improves the speed 
-- of data retrieval operations on a table at the cost of 
-- additional space and write performance.
-- ==============================================

-- ==============================================
-- 1. Create a NONCLUSTERED index on BaseSalary
-- Improves performance when filtering or ordering by BaseSalary
-- ==============================================
CREATE NONCLUSTERED INDEX IX_Salaries_BaseSalary
ON Salaries (BaseSalary);
GO

-- ==============================================
-- 2. Create a CLUSTERED index on Employees.EmployeeID
-- Clustered indexes define the physical order of rows
-- (usually already exists as PRIMARY KEY)
-- ==============================================
-- Only run if not already clustered:
-- CREATE CLUSTERED INDEX IX_Employees_EmployeeID
-- ON Employees (EmployeeID);
-- GO

-- ==============================================
-- 3. Composite index on Assignments (EmployeeID, ProjectID)
-- Useful for joins and multi-column searches
-- ==============================================
CREATE NONCLUSTERED INDEX IX_Assignments_Emp_Proj
ON Assignments (EmployeeID, ProjectID);
GO

-- ==============================================
-- 4. Index with INCLUDE (covering index for queries)
-- Improves SELECTs that need bonus and total comp without touching table rows
-- ==============================================
CREATE NONCLUSTERED INDEX IX_Salaries_Comp
ON Salaries (EmployeeID)
INCLUDE (BaseSalary, Bonus);
GO

-- ==============================================
-- 5. Indexed view example (materialized summary)
-- ==============================================

-- Step 1: Create the view with SCHEMABINDING
CREATE VIEW vw_DepartmentSalaryTotals
WITH SCHEMABINDING
AS
SELECT 
    E.DepartmentID,
    COUNT_BIG(*) AS EmpCount,
    SUM(ISNULL(S.BaseSalary, 0)) AS TotalSalary
FROM dbo.Employees E
JOIN dbo.Salaries S ON E.EmployeeID = S.EmployeeID
GROUP BY E.DepartmentID;
GO

-- Step 2: Add a UNIQUE CLUSTERED INDEX to the view
CREATE UNIQUE CLUSTERED INDEX IX_DepartmentSalaryTotals
ON vw_DepartmentSalaryTotals (DepartmentID);
GO

-- ==============================================
-- 6. Check existing indexes
-- ==============================================
-- Lists all indexes on all user tables
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
ORDER BY t.name, i.name;
GO

-- Check if a table has a clustered index

SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    t.name AS TableName,
    s.name AS SchemaName
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.type_desc = 'CLUSTERED'
  AND t.name = 'Offices';  -- Replace with your actual table name

  -- Show index columns too
  SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.type_desc = 'CLUSTERED'
  AND t.name = 'Offices'; -- Replace as needed


  ---Check for Nonclustered Indexes on a Specific Table
  SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    t.name AS TableName,
    s.name AS SchemaName
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.type_desc = 'NONCLUSTERED'
  AND t.name = 'Salaries';  -- Replace with your table name


  --
  SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    c.name AS ColumnName
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.type_desc = 'NONCLUSTERED'
  AND t.name = 'Salaries';

  -- ==============================================
-- Simple Stored Procedure Examples - CompanyDB
-- ==============================================

-- 1. Procedure without parameters: List all departments
CREATE PROCEDURE ListAllDepartments
AS
BEGIN
    SELECT * FROM Departments;
END;
GO

-- 2. Procedure with one input parameter: Get employees by department
CREATE PROCEDURE GetEmployeesInDepartment
    @DeptID INT
AS
BEGIN
    SELECT Name, HireDate
    FROM Employees
    WHERE DepartmentID = @DeptID;
END;
GO

-- 3. Procedure to insert a new project
CREATE PROCEDURE AddProject
    @ProjectName NVARCHAR(100)
AS
BEGIN
    INSERT INTO Projects (ProjectName)
    VALUES (@ProjectName);
END;
GO

-- 4. Procedure with multiple parameters: Assign employee to project
CREATE PROCEDURE AssignEmployeeToProject
    @EmpID INT,
    @ProjID INT,
    @DateAssigned DATE
AS
BEGIN
    INSERT INTO Assignments (EmployeeID, ProjectID, AssignedDate)
    VALUES (@EmpID, @ProjID, @DateAssigned);
END;
GO

-- 5. Procedure with default parameter: Get attendance after a given date
CREATE PROCEDURE GetRecentAttendance
    @StartDate DATE = '2025-01-01'
AS
BEGIN
    SELECT * FROM Attendance
    WHERE CheckIn >= @StartDate;
END;
GO

-- ============================================
-- STORED PROCEDURES EXAMPLES - CompanyDB
-- ============================================
--SIMPLE EX

CREATE PROCEDURE TEST_Salaries
AS SELECT * FROM Salaries

EXEC TEST -- CREATED

EXEC TEST_Salaries


-- 1. Simple Procedure: List all employees
-- Usage: EXEC GetAllEmployees;
CREATE PROCEDURE GetAllEmployees
AS
BEGIN
    SELECT * FROM Employees;
END;
GO

-- 2. Procedure with Input Parameter: Get employees by department
-- Usage: EXEC GetEmployeesByDepartment @DeptID = 1;
CREATE PROCEDURE GetEmployeesByDepartment
    @DeptID INT
AS
BEGIN
    SELECT Name, HireDate
    FROM Employees
    WHERE DepartmentID = @DeptID;
END;
GO

-- 3. Procedure with Logic: Give bonus to all employees in a department
-- Usage: EXEC AddBonusToDepartment @DeptID = 2, @BonusAmount = 1000;
CREATE PROCEDURE AddBonusToDepartment
    @DeptID INT,
    @BonusAmount DECIMAL(10,2)
AS
BEGIN
    UPDATE S
    SET Bonus = Bonus + @BonusAmount
    FROM Salaries S
    JOIN Employees E ON S.EmployeeID = E.EmployeeID
    WHERE E.DepartmentID = @DeptID;
END;
GO

-- 4. Procedure with Output Parameter: Get total number of employees
-- Usage:
-- DECLARE @Total INT;
-- EXEC GetEmployeeCount @Count = @Total OUTPUT;
-- SELECT @Total AS TotalEmployees;
CREATE PROCEDURE GetEmployeeCount
    @Count INT OUTPUT
AS
BEGIN
    SELECT @Count = COUNT(*) FROM Employees;
END;
GO

-- 5. Procedure with INSERT: Add a new employee
-- Usage: EXEC AddNewEmployee @Name = 'Lena Parks', @DeptID = 3;
CREATE PROCEDURE AddNewEmployee
    @Name NVARCHAR(100),
    @DeptID INT
AS
BEGIN
    INSERT INTO Employees (Name, DepartmentID)
    VALUES (@Name, @DeptID);
END;
GO

  
-- ==============================================
-- SQL Server Triggers - Explanation and Examples
-- For CompanyDB
-- ==============================================

-- ==============================================
-- What is a Trigger?
-- ----------------------------------------------
-- A trigger is a special kind of stored procedure that 
-- automatically runs when a data modification event 
-- (INSERT, UPDATE, DELETE) occurs on a table.
-- ==============================================

-- ==============================================
-- 1. AFTER INSERT Trigger
-- Logs new employees added to Employees_Log table
-- ==============================================

-- Create log table
IF OBJECT_ID('dbo.Employees_Log', 'U') IS NULL
CREATE TABLE Employees_Log (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    Name NVARCHAR(100),
    DepartmentID INT,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Create trigger
CREATE TRIGGER trg_AfterInsert_Employees
ON Employees
AFTER INSERT
AS
BEGIN
    INSERT INTO Employees_Log (EmployeeID, Name, DepartmentID)
    SELECT EmployeeID, Name, DepartmentID FROM inserted;
END;
GO

-- ==============================================
-- 2. AFTER UPDATE Trigger
-- Log salary changes in a Salary_Audit table
-- ==============================================

-- Create audit table
IF OBJECT_ID('dbo.Salary_Audit', 'U') IS NULL
CREATE TABLE Salary_Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    OldSalary DECIMAL(10,2),
    NewSalary DECIMAL(10,2),
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO

-- Create trigger
CREATE TRIGGER trg_AfterUpdate_Salaries
ON Salaries
AFTER UPDATE
AS
BEGIN
    INSERT INTO Salary_Audit (EmployeeID, OldSalary, NewSalary)
    SELECT 
        d.EmployeeID, 
        d.BaseSalary AS OldSalary, 
        i.BaseSalary AS NewSalary
    FROM deleted d
    JOIN inserted i ON d.EmployeeID = i.EmployeeID
    WHERE d.BaseSalary <> i.BaseSalary;
END;
GO

-- ==============================================
-- 3. INSTEAD OF DELETE Trigger
-- Prevent deletion of employees with salary records
-- ==============================================

CREATE TRIGGER trg_InsteadOfDelete_Employees
ON Employees
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM Salaries S 
        JOIN deleted d ON S.EmployeeID = d.EmployeeID
    )
    BEGIN
        RAISERROR('Cannot delete employee with a salary record.', 16, 1);
        RETURN;
    END

    -- If no salary, allow deletion
    DELETE FROM Employees
    WHERE EmployeeID IN (SELECT EmployeeID FROM deleted);
END;
GO

-- ==============================================
-- 4. View Triggers
-- Show triggers on Employees table
-- ==============================================
SELECT name AS TriggerName, object_definition(object_id) AS TriggerCode
FROM sys.triggers
WHERE parent_id = OBJECT_ID('Employees');
GO
