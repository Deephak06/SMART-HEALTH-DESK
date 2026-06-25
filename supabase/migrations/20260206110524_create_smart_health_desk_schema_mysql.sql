/*
  # Smart Health Desk - Medical Application Schema (MySQL/MariaDB Version)
  
  ## Overview
  Complete database schema for a healthcare management system supporting patients, doctors, and administrators.
  
  ## New Tables
  
  ### 1. profiles
  - User profile information with role
  - Fields: id (char(36), UUID), role (enum: patient, doctor, admin), full_name, phone, created_at, updated_at
  
  ### 2. patients
  - Patient-specific information
  - Fields: id, user_id (FK to profiles), date_of_birth, gender, blood_group, address, emergency_contact, medical_history
  
  ### 3. doctors
  - Doctor-specific information
  - Fields: id, user_id (FK to profiles), specialization, license_number, years_of_experience, consultation_fee
  
  ### 4. health_records
  - Day-wise patient health parameters
  - Fields: id, patient_id, recorded_date, systolic_bp, diastolic_bp, glucose_pre_meal, glucose_post_meal, wbc_count, notes, created_by
  
  ### 5. medications
  - Master medication database
  - Fields: id, name, generic_name, dosage_form, strength, manufacturer
  
  ### 6. prescriptions
  - Medications prescribed by doctors to patients
  - Fields: id, patient_id, doctor_id, medication_id, dosage, frequency, duration_days, instructions, prescribed_date, status
  
  ### 7. medication_schedules
  - Daily medication schedule for patients
  - Fields: id, prescription_id, scheduled_time, taken, taken_at, notes
  
  ### 8. notifications
  - Notification and alert logs
  - Fields: id, user_id, type, title, message, channel (sms, whatsapp, in_app), sent_at, read_at
  
  ### 9. visits
  - Doctor visit records with observations
  - Fields: id, patient_id, doctor_id, visit_date, symptoms, diagnosis, observations, follow_up_date
  
  ### 10. device_data
  - Medical device uploaded data
  - Fields: id, patient_id, device_type, device_name, data_json, uploaded_at, uploaded_by
  
  ## Security Note
  - MySQL/MariaDB does not support Row Level Security (RLS) like PostgreSQL
  - Security must be handled at the application level
*/

-- Create database (if it doesn't exist)
CREATE DATABASE IF NOT EXISTS smart_health_desk CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Use the database
USE smart_health_desk;

-- 1. Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id CHAR(36) PRIMARY KEY,
  role ENUM('patient', 'doctor', 'admin') NOT NULL DEFAULT 'patient',
  full_name TEXT NOT NULL,
  phone VARCHAR(20),
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. Patients table
CREATE TABLE IF NOT EXISTS patients (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) UNIQUE NOT NULL,
  date_of_birth DATE,
  gender ENUM('male', 'female', 'other'),
  blood_group VARCHAR(10),
  address TEXT,
  emergency_contact TEXT,
  medical_history TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- 3. Doctors table
CREATE TABLE IF NOT EXISTS doctors (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) UNIQUE NOT NULL,
  specialization VARCHAR(255) NOT NULL,
  license_number VARCHAR(100) UNIQUE NOT NULL,
  years_of_experience INT DEFAULT 0,
  consultation_fee DECIMAL(10, 2),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- 4. Health Records table
CREATE TABLE IF NOT EXISTS health_records (
  id CHAR(36) PRIMARY KEY,
  patient_id CHAR(36) NOT NULL,
  recorded_date DATE NOT NULL,
  systolic_bp INT,
  diastolic_bp INT,
  glucose_pre_meal DECIMAL(5, 2),
  glucose_post_meal DECIMAL(5, 2),
  wbc_count DECIMAL(10, 2),
  notes TEXT,
  created_by CHAR(36),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_patient_date (patient_id, recorded_date),
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL
);

-- 5. Medications table
CREATE TABLE IF NOT EXISTS medications (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  generic_name VARCHAR(255),
  dosage_form VARCHAR(100),
  strength VARCHAR(50),
  manufacturer VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Prescriptions table
CREATE TABLE IF NOT EXISTS prescriptions (
  id CHAR(36) PRIMARY KEY,
  patient_id CHAR(36) NOT NULL,
  doctor_id CHAR(36) NOT NULL,
  medication_id CHAR(36) NOT NULL,
  dosage VARCHAR(100) NOT NULL,
  frequency VARCHAR(100) NOT NULL,
  duration_days INT NOT NULL,
  instructions TEXT,
  prescribed_date DATE NOT NULL,
  status ENUM('active', 'completed', 'discontinued') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
  FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
);

-- 7. Medication Schedules table
CREATE TABLE IF NOT EXISTS medication_schedules (
  id CHAR(36) PRIMARY KEY,
  prescription_id CHAR(36) NOT NULL,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME NOT NULL,
  taken TINYINT(1) DEFAULT 0,
  taken_at TIMESTAMP NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE
);

-- 8. Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  channel ENUM('sms', 'whatsapp', 'in_app') DEFAULT 'in_app',
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- 9. Visits table
CREATE TABLE IF NOT EXISTS visits (
  id CHAR(36) PRIMARY KEY,
  patient_id CHAR(36) NOT NULL,
  doctor_id CHAR(36) NOT NULL,
  visit_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  symptoms TEXT,
  diagnosis TEXT,
  observations TEXT,
  follow_up_date DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
);

-- 10. Device Data table
CREATE TABLE IF NOT EXISTS device_data (
  id CHAR(36) PRIMARY KEY,
  patient_id CHAR(36) NOT NULL,
  device_type VARCHAR(100) NOT NULL,
  device_name VARCHAR(255),
  data_json JSON NOT NULL,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  uploaded_by CHAR(36),
  FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES profiles(id) ON DELETE SET NULL
);

-- Create indexes for better query performance
CREATE INDEX idx_health_records_patient_date ON health_records(patient_id, recorded_date DESC);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_prescriptions_doctor ON prescriptions(doctor_id);
CREATE INDEX idx_medication_schedules_date ON medication_schedules(scheduled_date, scheduled_time);
CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_visits_patient ON visits(patient_id, visit_date DESC);
CREATE INDEX idx_visits_doctor ON visits(doctor_id, visit_date DESC);

-- Insert sample medications
INSERT IGNORE INTO medications (id, name, generic_name, dosage_form, strength, manufacturer) VALUES
  (UUID(), 'Aspirin', 'Acetylsalicylic Acid', 'Tablet', '75mg', 'Generic Pharma'),
  (UUID(), 'Metformin', 'Metformin HCl', 'Tablet', '500mg', 'Generic Pharma'),
  (UUID(), 'Lisinopril', 'Lisinopril', 'Tablet', '10mg', 'Generic Pharma'),
  (UUID(), 'Amlodipine', 'Amlodipine Besylate', 'Tablet', '5mg', 'Generic Pharma'),
  (UUID(), 'Atorvastatin', 'Atorvastatin Calcium', 'Tablet', '20mg', 'Generic Pharma');
