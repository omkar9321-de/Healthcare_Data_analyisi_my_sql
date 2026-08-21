USE Healthcare_Analytics_DB;

-- =====================================================
-- 02_EXPLORATORY_ANALYSIS.SQL
-- Purpose: Initial exploration and data quality checks
-- =====================================================


-- =====================================================
-- 1. VIEW ALL TABLES
-- =====================================================

SHOW TABLES;


-- =====================================================
-- 2. CHECK TABLE STRUCTURES
-- =====================================================

DESCRIBE departments;
DESCRIBE doctors;
DESCRIBE patients;
DESCRIBE appointments;
DESCRIBE bills;
DESCRIBE medications;


-- =====================================================
-- 3. COUNT RECORDS IN EACH TABLE
-- =====================================================

SELECT COUNT(*) AS total_departments
FROM departments;

SELECT COUNT(*) AS total_doctors
FROM doctors;

SELECT COUNT(*) AS total_patients
FROM patients;

SELECT COUNT(*) AS total_appointments
FROM appointments;

SELECT COUNT(*) AS total_bills
FROM bills;

SELECT COUNT(*) AS total_medications
FROM medications;


-- =====================================================
-- 4. PREVIEW SAMPLE RECORDS
-- =====================================================

SELECT *
FROM departments
LIMIT 10;

SELECT *
FROM doctors
LIMIT 10;

SELECT *
FROM patients
LIMIT 10;

SELECT *
FROM appointments
LIMIT 10;

SELECT *
FROM bills
LIMIT 10;

SELECT *
FROM medications
LIMIT 10;


-- =====================================================
-- 5. CHECK NULL VALUES
-- =====================================================

-- Departments
SELECT
    COUNT(*) AS total_records,
    SUM(head_doctor_id IS NULL) AS null_head_doctor_id
FROM departments;

-- Doctors
SELECT
    COUNT(*) AS total_records,
    SUM(first_name IS NULL) AS null_first_name,
    SUM(last_name IS NULL) AS null_last_name,
    SUM(department_id IS NULL) AS null_department_id,
    SUM(joining_date IS NULL) AS null_joining_date
FROM doctors;

-- Patients
SELECT
    COUNT(*) AS total_records,
    SUM(admission_date IS NULL) AS null_admission_date,
    SUM(discharge_date IS NULL) AS null_discharge_date,
    SUM(doctor_id IS NULL) AS null_doctor_id,
    SUM(insurance_provider IS NULL) AS null_insurance_provider
FROM patients;

-- Appointments
SELECT
    COUNT(*) AS total_records,
    SUM(diagnosis IS NULL) AS null_diagnosis,
    SUM(follow_up_date IS NULL) AS null_follow_up_date
FROM appointments;

-- Bills
SELECT
    COUNT(*) AS total_records,
    SUM(insurance_amount IS NULL) AS null_insurance_amount
FROM bills;

-- Medications
SELECT
    COUNT(*) AS total_records,
    SUM(end_date IS NULL) AS null_end_date,
    SUM(notes IS NULL) AS null_notes
FROM medications;


-- =====================================================
-- 6. CHECK DUPLICATE RECORDS
-- =====================================================

-- Check duplicate doctors
SELECT
    first_name,
    last_name,
    COUNT(*) AS duplicate_count
FROM doctors
GROUP BY first_name, last_name
HAVING COUNT(*) > 1;

-- Check duplicate patients
SELECT
    first_name,
    last_name,
    date_of_birth,
    COUNT(*) AS duplicate_count
FROM patients
GROUP BY first_name, last_name, date_of_birth
HAVING COUNT(*) > 1;

-- Check duplicate appointments
SELECT
    patient_id,
    doctor_id,
    appointment_date,
    appointment_time,
    COUNT(*) AS duplicate_count
FROM appointments
GROUP BY patient_id, doctor_id, appointment_date, appointment_time
HAVING COUNT(*) > 1;


-- =====================================================
-- 7. EXPLORE CATEGORICAL COLUMNS
-- =====================================================

-- Doctor gender distribution
SELECT
    gender,
    COUNT(*) AS doctor_count
FROM doctors
GROUP BY gender
ORDER BY doctor_count DESC;

-- Doctor status distribution
SELECT
    status,
    COUNT(*) AS doctor_count
FROM doctors
GROUP BY status
ORDER BY doctor_count DESC;

-- Doctor specializations
SELECT
    specialization,
    COUNT(*) AS doctor_count
FROM doctors
GROUP BY specialization
ORDER BY doctor_count DESC;

-- Patient gender distribution
SELECT
    gender,
    COUNT(*) AS patient_count
FROM patients
GROUP BY gender
ORDER BY patient_count DESC;

-- Patient blood group distribution
SELECT
    blood_group,
    COUNT(*) AS patient_count
FROM patients
GROUP BY blood_group
ORDER BY patient_count DESC;

-- Appointment status
SELECT
    status,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY status
ORDER BY appointment_count DESC;

-- Payment mode
SELECT
    payment_mode,
    COUNT(*) AS bill_count
FROM bills
GROUP BY payment_mode
ORDER BY bill_count DESC;

-- Payment status
SELECT
    payment_status,
    COUNT(*) AS bill_count
FROM bills
GROUP BY payment_status
ORDER BY bill_count DESC;

-- Medication status
SELECT
    status,
    COUNT(*) AS medication_count
FROM medications
GROUP BY status
ORDER BY medication_count DESC;


-- =====================================================
-- 8. CHECK DATE RANGES
-- =====================================================

-- Doctor joining date
SELECT
    MIN(joining_date) AS earliest_joining_date,
    MAX(joining_date) AS latest_joining_date
FROM doctors;

-- Patient date of birth
SELECT
    MIN(date_of_birth) AS oldest_date_of_birth,
    MAX(date_of_birth) AS latest_date_of_birth
FROM patients;

-- Patient admission dates
SELECT
    MIN(admission_date) AS earliest_admission,
    MAX(admission_date) AS latest_admission
FROM patients;

-- Appointment dates
SELECT
    MIN(appointment_date) AS earliest_appointment,
    MAX(appointment_date) AS latest_appointment
FROM appointments;

-- Billing dates
SELECT
    MIN(billing_date) AS earliest_billing_date,
    MAX(billing_date) AS latest_billing_date
FROM bills;

-- Medication prescription dates
SELECT
    MIN(prescribed_date) AS earliest_prescription,
    MAX(prescribed_date) AS latest_prescription
FROM medications;


-- =====================================================
-- 9. BASIC NUMERICAL STATISTICS
-- =====================================================

-- Doctor experience
SELECT
    MIN(experience_years) AS minimum_experience,
    MAX(experience_years) AS maximum_experience,
    ROUND(AVG(experience_years), 2) AS average_experience
FROM doctors;

-- Doctor consultation fee
SELECT
    MIN(consultation_fee) AS minimum_fee,
    MAX(consultation_fee) AS maximum_fee,
    ROUND(AVG(consultation_fee), 2) AS average_fee
FROM doctors;

-- Department staff
SELECT
    MIN(total_staff) AS minimum_staff,
    MAX(total_staff) AS maximum_staff,
    ROUND(AVG(total_staff), 2) AS average_staff
FROM departments;

-- Department budget
SELECT
    MIN(budget_allocation) AS minimum_budget,
    MAX(budget_allocation) AS maximum_budget,
    ROUND(AVG(budget_allocation), 2) AS average_budget
FROM departments;

-- Bill amounts
SELECT
    MIN(total_amount) AS minimum_bill,
    MAX(total_amount) AS maximum_bill,
    ROUND(AVG(total_amount), 2) AS average_bill,
    SUM(total_amount) AS total_billed_amount
FROM bills;

-- Discounts
SELECT
    MIN(discount) AS minimum_discount,
    MAX(discount) AS maximum_discount,
    ROUND(AVG(discount), 2) AS average_discount,
    SUM(discount) AS total_discount
FROM bills;

-- Net revenue
SELECT
    MIN(net_amount) AS minimum_net_amount,
    MAX(net_amount) AS maximum_net_amount,
    ROUND(AVG(net_amount), 2) AS average_net_amount,
    SUM(net_amount) AS total_net_revenue
FROM bills;