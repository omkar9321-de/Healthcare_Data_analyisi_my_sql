-- ============================================================================
-- Script: 07_database_operations.sql
-- Description: Operational objects including triggers for business rules, 
--              stored procedures, and database views.
-- Database: Healthcare_Analytics_DB (MySQL 8.0+)
-- ============================================================================

USE Healthcare_Analytics_DB;


-- ----------------------------------------------------------------------------
-- SECTION 1: BUSINESS LOGIC AUTOMATION (TRIGGERS)
-- ----------------------------------------------------------------------------

-- 1.1 Combined bill defaulting trigger — discount, net_amount, due_date.
--
-- This replaces two previously separate BEFORE INSERT triggers on `bills`
-- (trg_bills_before_insert here, and trg_update_discount in
-- 04_doctor_analysis.sql). Having two BEFORE INSERT triggers on the same
-- table/event is risky in MySQL: execution order across triggers is not
-- guaranteed unless you use FOLLOWS/PRECEDES (5.7+), so the discount step
-- could run before or after the net_amount step depending on the server.
-- The original trg_update_discount also computed the 10% discount from
-- NEW.net_amount, which is only reliable *after* net_amount has been
-- calculated — a second latent bug fixed below by deriving discount from
-- NEW.total_amount instead.
--
-- NOTE: `discount` is defined as NOT NULL DEFAULT 0. The auto-10% branch
-- below only fires if a caller explicitly inserts NULL for discount — if
-- the column is simply omitted from the INSERT list, MySQL substitutes 0
-- before this trigger runs, and the 10% default will not apply. Adjust the
-- condition to `NEW.discount IS NULL OR NEW.discount = 0` if you want the
-- default to apply whenever no explicit discount is given.
DROP TRIGGER IF EXISTS trg_update_discount;
DROP TRIGGER IF EXISTS trg_bills_before_insert;
DELIMITER //
CREATE TRIGGER trg_bills_before_insert_combined
BEFORE INSERT ON bills
FOR EACH ROW
BEGIN
    -- 1. Apply 10% discount default (derived from total_amount, not the
    --    not-yet-calculated net_amount)
    IF NEW.discount IS NULL THEN
        SET NEW.discount = NEW.total_amount * 0.10;
    END IF;

    -- 2. Recalculate net_amount to enforce financial data entry consistency
    SET NEW.net_amount = (NEW.total_amount - NEW.discount) - COALESCE(NEW.insurance_amount, 0);

    -- 3. Auto-populate due_date to 14 days out if not specified
    IF NEW.due_date IS NULL THEN
        SET NEW.due_date = DATE_ADD(NEW.billing_date, INTERVAL 14 DAY);
    END IF;
END;
//
DELIMITER ;


-- 1.2 Prevent scheduling appointments with doctors who are on leave or retired
DELIMITER //
CREATE TRIGGER trg_appointments_validate_doctor
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
    DECLARE current_doc_status VARCHAR(20);
    
    SELECT status INTO current_doc_status 
    FROM doctors 
    WHERE doctor_id = NEW.doctor_id;
    
    IF current_doc_status IN ('Retired', 'On Leave') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Booking Error: The selected doctor is currently unavailable or retired.';
    END IF;
END;
//
DELIMITER ;


-- ----------------------------------------------------------------------------
-- SECTION 2: STORED PROCEDURES
-- ----------------------------------------------------------------------------

-- 2.1 Patient Discharge Handler (Ensures all bills are settled first)
DELIMITER //
CREATE PROCEDURE sp_discharge_patient(
    IN p_patient_id INT,
    IN p_discharge_date DATE
)
BEGIN
    DECLARE open_bills_count INT DEFAULT 0;
    
    -- Exit handler: automatically rolls back if a SQL error/crash occurs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'System error: Transaction rolled back to maintain data integrity.';
    END;

    -- Begin the transaction
    START TRANSACTION;
    
    -- Count pending bills for this patient
    SELECT COUNT(*) INTO open_bills_count
    FROM bills
    WHERE patient_id = p_patient_id AND payment_status = 'Pending';
    
    IF open_bills_count > 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Discharge Error: Patient has pending unpaid bills that must be settled first.';
    ELSE
        UPDATE patients
        SET discharge_date = p_discharge_date
        WHERE patient_id = p_patient_id;

        -- Commit changes permanently
        COMMIT;
    END IF;
END;
//
DELIMITER ;


-- ----------------------------------------------------------------------------
-- SECTION 3: REUSABLE REPORTING VIEWS & INDEX OPTIMIZATION
-- ----------------------------------------------------------------------------

-- Create an independent index on payment_status for high-volume scaling
CREATE INDEX idx_payment_status ON bills(payment_status);


-- 3.1 Active Inpatient Monitor (Patients currently admitted without a discharge date)
CREATE OR REPLACE VIEW vw_active_inpatients AS
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.admission_date,
    DATEDIFF(CURRENT_DATE, p.admission_date) AS current_stay_days,
    CONCAT('Dr. ', d.first_name, ' ', d.last_name) AS attending_doctor,
    dept.department_name
FROM patients p
INNER JOIN doctors d 
    ON p.doctor_id = d.doctor_id
INNER JOIN departments dept 
    ON d.department_id = dept.department_id
WHERE p.admission_date IS NOT NULL 
  AND p.discharge_date IS NULL;


-- 3.2 Outstanding Bills / Accounts Receivable Tracker
CREATE OR REPLACE VIEW vw_outstanding_bills AS
SELECT 
    b.bill_id,
    b.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.phone AS patient_phone,
    b.net_amount,
    b.due_date,
    DATEDIFF(CURRENT_DATE, b.due_date) AS days_overdue
FROM bills b
INNER JOIN patients p 
    ON b.patient_id = p.patient_id
WHERE b.payment_status = 'Pending';


-- 3.3 Doctor Revenue Report (Optimized with LEFT JOIN & COALESCE)
CREATE OR REPLACE VIEW vw_doctor_revenue AS
SELECT 
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    COALESCE(SUM(b.net_amount), 0) AS total_revenue 
FROM doctors d
LEFT JOIN bills b 
    ON d.doctor_id = b.doctor_id 
    AND b.payment_status = 'Paid' 
GROUP BY 
    d.doctor_id, 
    d.first_name,
    d.last_name,
    d.specialization;