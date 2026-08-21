-- =====================================================
-- 05_REVENUE_ANALYSIS.SQL
-- Healthcare Data Analytics Project
-- =====================================================

USE Healthcare_Analytics_DB;


-- =====================================================
-- Q: Paid Bill Summary by Payment Mode
-- Objective: Aggregate the total count of 'Paid' status bills and calculate their combined net amount, grouped by each payment mode.
-- =====================================================

SELECT 
    payment_mode,
    COUNT(*) AS `Paid`,
    SUM(net_amount) AS net_amount
FROM
    bills
WHERE
    payment_status = 'Paid'
GROUP BY payment_mode;


-- =====================================================
-- Q: Top 5 Departments by Total Revenue
-- Objective: Identify and rank the top 5 departments based on the total net revenue generated from paid patient bills.
-- =====================================================

SELECT 
    d.department_name, SUM(b.net_amount) AS `Revenue`
FROM
    departments AS d
        JOIN
    doctors AS doc USING (department_id)
        JOIN
    bills AS b USING (doctor_id)
GROUP BY d.department_name
ORDER BY `Revenue` DESC
LIMIT 5;



-- =====================================================
-- Q:Doctor Revenue Analysis View
-- Objective: Create a view named 'vw_doctor_revenue' to aggregate total revenue from paid bills per doctor, and query it to filter doctors generating more than ₹1,000 in net revenue.
-- =====================================================

CREATE VIEW vw_doctor_revenue AS
    (SELECT 
        d.doctor_id,
        CONCAT(d.first_name, ' ', d.last_name) AS `Full name`,
        COALESCE(SUM(net_amount), 0) AS `Total Revenue`
    FROM
        doctors AS d
            LEFT JOIN
        bills AS b ON d.doctor_id = b.doctor_id
            AND b.payment_status = 'Paid'
    GROUP BY d.doctor_id , d.first_name , d.last_name
    ORDER BY `Total Revenue` DESC);

SELECT 
    *
FROM
    vw_doctor_revenue
WHERE
    `Total Revenue` > 1000
ORDER BY `Total Revenue` DESC;



-- =====================================================
-- Q: Top 5 Patients by Total Amount Paid
-- Objective: Retrieve and rank the top 5 patients who have generated the highest total expenditure from settled ('Paid') bills, displaying full patient names and total amounts paid.
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
-- Q: City-Wise Patient Payment Ranking
-- Objective: Rank patients within each city based on their total net expenditure from paid bills using window functions.
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