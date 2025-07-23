create database projectdb;
use projectdb;

-- Table 1: Job Department
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);

-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table 3: Employee
CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
        REFERENCES JobDepartment(Job_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Table 4: Qualification
CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    Emp_ID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
        REFERENCES Employee(emp_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Table 5: Leaves
CREATE TABLE Leaves (
    leave_ID INT PRIMARY KEY,
    emp_ID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table 6: Payroll
CREATE TABLE Payroll (
    payroll_ID INT PRIMARY KEY,
    emp_ID INT,
    job_ID INT,
    salary_ID INT,
    leave_ID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Analysis Questions
-- 1. EMPLOYEE INSIGHTS
-- How many unique employees are currently in the system?
SELECT COUNT(DISTINCT emp_ID) AS unique_employee_count
FROM Employee;

-- Which departments have the highest number of employees?
SELECT 
    jd.jobdept AS department,
    COUNT(e.emp_ID) AS employee_count
FROM 
    Employee e
JOIN 
    JobDepartment jd ON e.Job_ID = jd.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    employee_count DESC;
    
-- What is the average salary per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(sb.amount), 2) AS average_salary
FROM 
    Employee e
JOIN 
    JobDepartment jd ON e.Job_ID = jd.Job_ID
JOIN 
    SalaryBonus sb ON e.Job_ID = sb.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    average_salary DESC;
    
-- Who are the top 5 highest-paid employees?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS full_name,
    jd.jobdept AS department,
    sb.amount AS salary
FROM 
    Employee e
JOIN 
    JobDepartment jd ON e.Job_ID = jd.Job_ID
JOIN 
    SalaryBonus sb ON e.Job_ID = sb.Job_ID
ORDER BY 
    sb.amount DESC
LIMIT 5;

-- What is the total salary expenditure across the company?
SELECT 
    SUM(sb.amount) AS total_salary_expenditure
FROM 
    Employee e
JOIN 
    SalaryBonus sb ON e.Job_ID = sb.Job_ID;
    
-- 2. JOB ROLE AND DEPARTMENT ANALYSIS
-- How many different job roles exist in each department?
SELECT 
    jobdept AS department,
    COUNT(DISTINCT name) AS job_roles_count
FROM 
    JobDepartment
GROUP BY 
    jobdept
ORDER BY 
    job_roles_count DESC;

-- What is the average salary range per department?
SELECT 
    jobdept AS Department,
    ROUND(AVG(
        (CAST(REPLACE(REPLACE(TRIM(SUBSTRING_INDEX(salaryrange, '-', 1)), '$', ''), ',', '') AS DECIMAL(10,2)) + 
         CAST(REPLACE(REPLACE(TRIM(SUBSTRING_INDEX(salaryrange, '-', -1)), '$', ''), ',', '') AS DECIMAL(10,2))
        ) / 2
    ), 2) AS Average_Salary_Range
FROM jobdepartment
WHERE salaryrange LIKE '%-%'
GROUP BY jobdept;

-- Which job roles offer the highest salary?
SELECT 
    jd.name AS job_role,
    jd.jobdept AS department,
    MAX(sb.amount) AS highest_salary
FROM 
    JobDepartment jd
JOIN 
    SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY 
    jd.name, jd.jobdept
ORDER BY 
    highest_salary DESC
LIMIT 5;

-- Which departments have the highest total salary allocation?
SELECT 
    jd.jobdept AS department,
    SUM(sb.amount) AS total_salary_allocation
FROM 
    Employee e
JOIN 
    JobDepartment jd ON e.Job_ID = jd.Job_ID
JOIN 
    SalaryBonus sb ON e.Job_ID = sb.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    total_salary_allocation DESC;
    
-- QUALIFICATION AND SKILLS ANALYSIS
-- How many employees have at least one qualification listed?
SELECT 
    COUNT(DISTINCT q.Emp_ID) AS employees_with_qualifications
FROM 
    Qualification q
WHERE 
    TRIM(q.Requirements) != ''
    AND LENGTH(q.Requirements) - LENGTH(REPLACE(q.Requirements, ' ', '')) + 1 > 0;
    
-- Which positions require the most qualifications?
SELECT 
    Position,
    LENGTH(Requirements) - LENGTH(REPLACE(Requirements, ' ', '')) + 1 AS qualification_count
FROM 
    Qualification
ORDER BY 
    qualification_count DESC
LIMIT 5;

-- What is the average number of qualifications per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(word_count), 2) AS avg_qualifications_per_employee
FROM (
    SELECT 
        e.emp_ID,
        e.Job_ID,
        COALESCE(SUM(LENGTH(q.Requirements) - LENGTH(REPLACE(q.Requirements, ' ', '')) + 1), 0) AS word_count
    FROM 
        Employee e
    LEFT JOIN 
        Qualification q ON e.emp_ID = q.Emp_ID
    GROUP BY 
        e.emp_ID, e.Job_ID
) AS emp_qual_counts
JOIN JobDepartment jd ON emp_qual_counts.Job_ID = jd.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    avg_qualifications_per_employee DESC;
    
-- LEAVE AND ABSENCE PATTERNS
-- Which year had the most employees taking leaves?
SELECT 
    YEAR(date) AS leave_year,
    COUNT(DISTINCT emp_ID) AS employees_on_leave
FROM 
    Leaves
GROUP BY 
    leave_year
ORDER BY 
    employees_on_leave DESC
LIMIT 2;

-- What is the average number of leave days taken by its employees per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(emp_leave_count.total_leaves), 2) AS avg_leave_days_per_employee
FROM (
    SELECT 
        e.emp_ID,
        e.Job_ID,
        COUNT(l.leave_ID) AS total_leaves
    FROM 
        Employee e
    LEFT JOIN Leaves l ON e.emp_ID = l.emp_ID
    GROUP BY 
        e.emp_ID, e.Job_ID
) AS emp_leave_count
JOIN JobDepartment jd ON emp_leave_count.Job_ID = jd.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    avg_leave_days_per_employee DESC;
    
-- Which employees have taken the most leaves?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
    COUNT(l.leave_ID) AS total_leaves
FROM 
    Employee e
JOIN 
    Leaves l ON e.emp_ID = l.emp_ID
GROUP BY 
    e.emp_ID
ORDER BY 
    total_leaves DESC;
    
-- What is the total number of leave days taken company-wide?
SELECT 
    COUNT(*) AS total_leave_days
FROM 
    Leaves;
    
-- How do leave days correlate with payroll amounts?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS Employee_Name,
    sb.amount AS Base_Salary,
    SUM(p.total_amount) AS Total_Paid,
    (sb.amount - SUM(p.total_amount)) AS Total_Deduction
FROM 
    Employee e
JOIN 
    Payroll p ON e.emp_ID = p.emp_ID
JOIN 
    SalaryBonus sb ON p.salary_ID = sb.salary_ID
GROUP BY 
    e.emp_ID, Employee_Name, sb.amount
ORDER BY 
    e.emp_ID;
    
-- PAYROLL AND COMPENSATION ANALYSIS
-- What is the total monthly payroll processed?
SELECT 
    pm.payroll_month,
    pm.total_monthly_payroll,
    COALESCE(lv.total_leave_days, 0) AS total_leave_days
FROM
    (
        SELECT 
            DATE_FORMAT(date, '%Y-%m') AS payroll_month,
            SUM(total_amount) AS total_monthly_payroll
        FROM 
            Payroll
        GROUP BY 
            payroll_month
    ) pm
LEFT JOIN
    (
        SELECT 
            DATE_FORMAT(date, '%Y-%m') AS leave_month,
            COUNT(*) AS total_leave_days
        FROM 
            Leaves
        GROUP BY 
            leave_month
    ) lv ON pm.payroll_month = lv.leave_month
ORDER BY 
    pm.payroll_month;
    
-- What is the average bonus given per department?
SELECT 
    jd.jobdept AS department,
    ROUND(AVG(sb.bonus), 2) AS average_bonus
FROM 
    SalaryBonus sb
JOIN 
    JobDepartment jd ON sb.Job_ID = jd.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    average_bonus DESC;
    
-- Which department receives the highest total bonuses?
SELECT 
    jd.jobdept AS department,
    SUM(sb.bonus) AS total_bonus
FROM 
    SalaryBonus sb
JOIN 
    JobDepartment jd ON sb.Job_ID = jd.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    total_bonus DESC
LIMIT 5;

-- What is the average net salary after all deductions?
SELECT 
    ROUND(AVG(total_amount), 2) AS average_net_salary
FROM 
    Payroll;
    
-- EMPLOYEE PERFORMANCE AND GROWTH
-- Which year had the highest number of employee promotions?
SELECT 
    YEAR(Date_In) AS promotion_year,
    COUNT(*) AS total_promotions
FROM 
    Qualification
GROUP BY 
    promotion_year
ORDER BY 
    total_promotions DESC
LIMIT 5;
