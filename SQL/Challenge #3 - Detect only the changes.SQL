/*
 What's changed?
Assume we have 2 tables one Source and Target , find the new records and updated records from source to target . 
Give 2 different solutions using below methods:
1. LEFT JOIN
2. HASHING

*/


/*
-- Data preparation

-- Create SourceEmployee table
CREATE TABLE IF NOT EXISTS 
MyDataset.Challenge_3_SourceEmployee (
    EmployeeID INT,
    Name STRING(100),
    Department STRING(50),
    Salary DECIMAL(10,2),
    EffectiveStartDate DATE
);
-- Create TargetEmployee table
CREATE TABLE IF NOT EXISTS 
MyDataset.Challenge_3_TargetEmployee (
    EmployeeID INT,
    Name STRING(100),
    Department STRING(50),
    Salary DECIMAL(10,2),
    EffectiveStartDate DATE,
    EffectiveEndDate DATE,
    IsCurrent BOOL
);

-- Insert data into SourceEmployee
INSERT INTO MyDataset.Challenge_3_SourceEmployee (EmployeeID, Name, Department, Salary, EffectiveStartDate)
VALUES 
(1, 'Mighty Mike', 'IT', 75000.00,'2023-11-01'),
(2, 'Shawn the Sheep', 'HR', 65000.00, '2023-06-01'),
(3, 'Sheriff Lambrador', 'Sales', 70000.00, '2024-07-01'),
(4, 'Ricky Zoom', 'Marketing', 70000.00,'2024-10-05'),
(5, 'Paw Patrol', 'Finance', 85000.00,'2024-10-01');

-- Insert data into TargetEmployee
INSERT INTO MyDataset.Challenge_3_TargetEmployee (EmployeeID, Name, Department, Salary, EffectiveStartDate, EffectiveEndDate, IsCurrent)
VALUES 
(1, 'Might Mike', 'IT', 70000.00, '2024-11-01', NULL, TRUE),
(2, 'Shawn the Sheep', 'HR', 65000.00, '2023-06-01', NULL, TRUE),
(3, 'Sheriff Lamrador', 'Marketing', 75000.00, '2023-07-01', NULL, TRUE),
(4, 'Ricky Zoom', 'Marketing', 78000.00, '2023-10-05', NULL, TRUE);

*/

/*

-- ------------------
-- LEFT JOIN SOLUTION
-- ------------------

SELECT 
    SourceEmployee.EmployeeID AS SourceEmployeeID
    ,CASE 
        WHEN TargetEmployee.EmployeeID IS NULL THEN "The source record is a NEW one"
        ELSE "The source record is an UPDATED one"
    END                       AS SourceRecordStatus
from 
MyDataset.Challenge_3_SourceEmployee SourceEmployee 
LEFT OUTER JOIN MyDataset.Challenge_3_TargetEmployee TargetEmployee ON (TargetEmployee.EmployeeID = SourceEmployee.EmployeeID AND TargetEmployee.IsCurrent)
WHERE 
    NOT (                                                      --> UPDATED Records
        SourceEmployee.Name       = TargetEmployee.Name
    AND SourceEmployee.Department = TargetEmployee.Department
    AND SourceEmployee.Salary     = TargetEmployee.Salary
    AND SourceEmployee.EffectiveStartDate     = TargetEmployee.EffectiveStartDate
    )
OR
    (TargetEmployee.EmployeeID IS NULL)                        -- > NEW RECORDS

*/


-- ----------------
-- HASHING SOLUTION
-- ----------------
/*
I use the BigQuery hashing function FARM_FINGERPRINT that computes a fingerproint starting from a string

Any collision issues and Why FARM_FINGERPRINT?
- It's highly efficient for general-purpose hashing.
- It produces 64-bit hashes, offering good distribution.
- It's ideal for comparing the equality of entire rows.
- It doesn't require cryptographic security, making it faster than SHA256.

This approach enables you to efficiently identify different records between your BigQuery tables."

:-) Explanation extracted by By GEMINI
*/

SELECT 
    SourceEmployee.EmployeeID AS SourceEmployeeID
    ,CASE 
        WHEN TargetEmployee.EmployeeID IS NULL THEN "The source record is a NEW one"
        ELSE "The source record is an UPDATED one"
    END                       AS SourceRecordStatus
from 
MyDataset.Challenge_3_SourceEmployee SourceEmployee 
LEFT OUTER JOIN MyDataset.Challenge_3_TargetEmployee TargetEmployee ON (TargetEmployee.EmployeeID = SourceEmployee.EmployeeID AND TargetEmployee.IsCurrent)
WHERE 
    FARM_FINGERPRINT(
       COALESCE(SourceEmployee.Name,'-') || COALESCE(SourceEmployee.Department,'-')
    || COALESCE(CAST(SourceEmployee.Salary AS STRING), '-') 
    || COALESCE(CAST(SourceEmployee.EffectiveStartDate AS STRING), '-')
    )
    <>  -- > the source record's fingerprint is different from the target record's fingerprint.
        -- > Note that using the COALESCE also the target "all null" record has a fingerprint: 
        -- >    it means that the <OR TargetEmployee.EmployeeID IS NULL> condition is not needed  
    FARM_FINGERPRINT(  
       COALESCE(TargetEmployee.Name,'-') || COALESCE(TargetEmployee.Department,'-')
    || COALESCE(CAST(TargetEmployee.Salary AS STRING), '-') 
    || COALESCE(CAST(TargetEmployee.EffectiveStartDate AS STRING), '-')
    )

