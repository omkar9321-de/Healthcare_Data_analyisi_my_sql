-- =====================================================
-- 02_PATIENT_ANALYSIS.SQL
-- Healthcare Data Analytics Project
-- =====================================================

USE Healthcare_Analytics_DB;


-- =====================================================
-- Q: Patients from Bengaluru
-- Objective: Identify patients located in Bengaluru
-- =====================================================

SELECT 
    patient_id,
    CONCAT(first_name, ' ', last_name) AS Full_name,
    city,
    blood_group
FROM
    patients
WHERE
    city = 'Bengaluru'
LIMIT 10;




-- =====================================================
-- Q: Top 5 Highest-Paying Patients
-- Objective: Identify the top 5 patients based on
-- total amount paid
-- =====================================================

SELECT 
    CONCAT(p.first_name, ' ', p.last_name) AS `Patient name`,
    SUM(net_amount) AS `Total amount paid`
FROM
    patients AS p
        JOIN
    bills AS b USING (patient_id)
GROUP BY p.patient_id , p.first_name , p.last_name
ORDER BY `Total amount paid` DESC
LIMIT 5;



-- =====================================================
-- Q: Top 3 Earning Patients Per City
-- Objective: Identify the top 3 patients with the
-- highest spending in each city
-- =====================================================

SELECT city, patient_name, total_paid, city_rank
FROM (
    SELECT 
        p.city AS city,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        SUM(b.net_amount) AS total_paid,
        DENSE_RANK() OVER (
            PARTITION BY p.city 
            ORDER BY SUM(b.net_amount) DESC
        ) AS city_rank
    FROM patients p
    INNER JOIN bills b 
        ON p.patient_id = b.patient_id
    GROUP BY p.city, p.patient_id, p.first_name, p.last_name
) t
WHERE t.city_rank <= 3
ORDER BY city, city_rank;
