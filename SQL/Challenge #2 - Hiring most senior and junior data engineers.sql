--
-- Challenge #2 in https://medium.com/art-of-data-engineering/can-you-crack-this-sql-query-in-30-minutes-2809c054bc52
--

/*
Problem Statement
A company has secured a $1 million budget to build a data team and develop its data platform. The hiring team is working with a dataset called “Candidate,” which contains a comprehensive list of potential hires, categorized as senior and junior data engineers, along with details about their salary expectations. All senior and junior candidates have similar skills within their respective levels and are considered eligible for hiring.

The goal of the hiring team is -

1. To hire the maximum number of seniors first.

2. After hiring the maximum number of seniors, the remaining budget should be used to hire as many juniors as possible.

*/


/*
-- Data preparation
create table if not exists 
MyDataset.Challenge_2_candidate (candidate_id int, experience String(50), salary int)


INSERT INTO MyDataset.Challenge_2_candidate (candidate_id, experience, salary) VALUES
(1, 'Senior', 200000),
(2, 'Senior', 95000),
(3, 'Senior', 110000),
(4, 'Senior', 105000),
(5, 'Senior', 120000),
(6, 'Senior', 185000),
(7, 'Senior', 190000),
(8, 'Senior', 115000),
(9, 'Senior', 180000),
(10, 'Senior', 98000),
(11, 'Junior', 70000),
(12, 'Junior', 75000),
(13, 'Junior', 60000),
(14, 'Junior', 61000),
(15, 'Junior', 55000);

*/
WITH
--
--> $1 million budget to build a data team
--
TotalBudget AS (
SELECT 1000000 AS Budget    
)
--
--> Rolling sum of salary expectations by senior and junior experience starting from the candidate asking less money
--> <CumulativeSalary> means the budget allocated up to the i-th candidate for that skill
--
,CumulativeSalaryByCandidate AS ( 
SELECT 
  candidate_id
  ,experience
  ,ROW_NUMBER() OVER (PARTITION BY experience ORDER BY salary, candidate_id  ASC ) AS CandidateSequence 
  ,salary
  ,SUM(salary) OVER (PARTITION BY experience ORDER BY salary, candidate_id  ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS CumulativeSalary
FROM MyDataset.Challenge_2_candidate candidate
)
--
-- The budget allocated for junior is the money not used to hire the senior candidates
-- The <hiring seniors> will be the candidates who have the <CumulativeSalary> less or equal the initial <TotalBudget>
-- The biggest <CumulativeSalary> of the <hiring seniors> is the maximum budget "assignable" for seniors
--
-- ==> Remaining budget for the junior is <Total budget> - <CumulativeSalary> of the "last" and biggest <hiring senior> row
-- 
, BudgetForExperience AS (
SELECT 
  'Junior'                                    AS experience 
  ,MIN(TotalBudget.Budget - CumulativeSalary) AS Budget
FROM 
  CumulativeSalaryByCandidate 
  ,TotalBudget
WHERE experience = "Senior"
AND CumulativeSalary <= TotalBudget.Budget --> <hiring seniors>
UNION ALL
SELECT
  'Senior'                                    AS experience 
  ,Budget                                     AS Budget
FROM 
  TotalBudget
)
select 
  CumulativeSalaryByCandidate.experience
  ,CumulativeSalaryByCandidate.CandidateSequence
  ,CumulativeSalaryByCandidate.candidate_id
  ,CumulativeSalaryByCandidate.Salary
  ,SUM(CumulativeSalaryByCandidate.Salary) OVER (ORDER BY CumulativeSalaryByCandidate.experience DESC, CumulativeSalaryByCandidate.Salary) AS UsedBudget 
FROM CumulativeSalaryByCandidate
INNER JOIN BudgetForExperience ON (CumulativeSalaryByCandidate.experience = BudgetForExperience.experience)
WHERE CumulativeSalaryByCandidate.CumulativeSalary <= BudgetForExperience.Budget
ORDER BY CumulativeSalaryByCandidate.experience DESC, CumulativeSalaryByCandidate.Salary

/*
The Query has been designed to facilitate the editing of a new budget value: if you have more budget you need only to change the value of TotalBudget table at the head of the CTE
*/
