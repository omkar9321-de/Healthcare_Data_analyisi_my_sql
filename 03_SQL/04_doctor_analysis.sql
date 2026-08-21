-- =====================================================
-- 04_DOCTOR_ANALYSIS.SQL
-- Healthcare Data Analytics Project
-- =====================================================

USE Healthcare_Analytics_DB;


-- =====================================================
-- Q: Active Doctors with Over 10 Years of Experience
-- Objective: Retrieve all doctor records where the current status is 'Active' and professional experience exceeds 10 years.
-- =====================================================


SELECT 
    *
FROM
    doctors
WHERE
    status = 'Active'
        AND experience_years > 10;



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
-- Q: Prescribed Medications from 'Ology' Departments
-- Objective: Retrieve all medications prescribed by doctors affiliated with departments whose name contains 'ology' (e.g., Cardiology, Neurology).
-- =====================================================

SELECT DISTINCT
    m.generic_name,
    m.brand_name,
    CONCAT(doc.first_name, ' ', doc.last_name) AS `Prescribed by Dr`,
    d.department_name AS `Issued by Department`
FROM
    medications AS m
        JOIN
    doctors AS doc USING (doctor_id)
        JOIN
    departments AS d ON doc.department_id = d.department_id
WHERE
    d.department_name LIKE '%ology%'
ORDER BY m.generic_name ASC , m.brand_name ASC;



-- =====================================================
-- Q: Find Doctors With More Than 8 Appointments & Automatically Apply 10% Bill Discount
-- Objective: Use a CTE to identify doctors who have handled more than 8 appointments and create a trigger to automatically apply a 10% discount when a new bill
-- is inserted without a specified discount.
-- =====================================================

WITH DoctorAppointments AS (
    SELECT 
        d.doctor_id,
        CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
        COUNT(a.appointment_id) AS appointment_count
    FROM doctors d
    JOIN appointments a ON d.doctor_id = a.doctor_id
    GROUP BY d.doctor_id, d.first_name, d.last_name
)
SELECT doctor_id, doctor_name, appointment_count
FROM DoctorAppointments
WHERE appointment_count > 8
ORDER BY appointment_count DESC;

-- NOTE: trg_update_discount previously lived here. It conflicted with
-- trg_bills_before_insert (07_database_operations.sql) — both were
-- BEFORE INSERT triggers on `bills`, and MySQL does not guarantee
-- execution order between them, so the discount could be calculated
-- from a `net_amount` that hadn't been set yet.
--
-- The two triggers have been merged into a single, order-safe trigger:
-- trg_bills_before_insert_combined, defined in 07_database_operations.sql.
-- See that file for the current discount + net_amount + due_date logic.