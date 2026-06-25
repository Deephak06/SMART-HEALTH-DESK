/*
  # Smart Health Desk - Medical Application Schema
  
  ## Overview
  Complete database schema for a healthcare management system supporting patients, doctors, and administrators.
  
  ## New Tables
  
  ### 1. profiles
  - Extends auth.users with role and profile information
  - Fields: id (uuid, FK to auth.users), role (enum: patient, doctor, admin), full_name, phone, created_at, updated_at
  
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
  
  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Policies for role-based access control
  - Patients can only access their own data
  - Doctors can access their patients' data
  - Admins have full access
*/

-- Create enum for user roles
DO $$ BEGIN
CREATE TYPE user_role AS ENUM ('patient', 'doctor', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create enum for gender
DO $$ BEGIN
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create enum for notification channels
DO $$ BEGIN
CREATE TYPE notification_channel AS ENUM ('sms', 'whatsapp', 'in_app');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create enum for prescription status
DO $$ BEGIN
CREATE TYPE prescription_status AS ENUM ('active', 'completed', 'discontinued');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 1. Profiles table (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'patient',
  full_name text NOT NULL,
  phone text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. Patients table
CREATE TABLE IF NOT EXISTS patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date_of_birth date,
  gender gender_type,
  blood_group text,
  address text,
  emergency_contact text,
  medical_history text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 3. Doctors table
CREATE TABLE IF NOT EXISTS doctors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  specialization text NOT NULL,
  hospital_name text,
  license_number text UNIQUE NOT NULL,
  years_of_experience integer DEFAULT 0,
  consultation_fee numeric(10, 2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- In case the doctors table already existed before hospital_name was added
ALTER TABLE doctors ADD COLUMN IF NOT EXISTS hospital_name text;

-- 4. Health Records table
CREATE TABLE IF NOT EXISTS health_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  recorded_date date NOT NULL DEFAULT CURRENT_DATE,
  systolic_bp integer,
  diastolic_bp integer,
  glucose_pre_meal numeric(5, 2),
  glucose_post_meal numeric(5, 2),
  wbc_count numeric(10, 2),
  notes text,
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(patient_id, recorded_date)
);

-- 5. Medications table
CREATE TABLE IF NOT EXISTS medications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  generic_name text,
  dosage_form text,
  strength text,
  manufacturer text,
  created_at timestamptz DEFAULT now()
);

-- 6. Prescriptions table
CREATE TABLE IF NOT EXISTS prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  medication_id uuid NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  dosage text NOT NULL,
  frequency text NOT NULL,
  duration_days integer NOT NULL,
  instructions text,
  prescribed_date date NOT NULL DEFAULT CURRENT_DATE,
  status prescription_status DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 7. Medication Schedules table
CREATE TABLE IF NOT EXISTS medication_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prescription_id uuid NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
  scheduled_date date NOT NULL,
  scheduled_time time NOT NULL,
  taken boolean DEFAULT false,
  taken_at timestamptz,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- 8. Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  channel notification_channel DEFAULT 'in_app',
  sent_at timestamptz DEFAULT now(),
  read_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 9. Visits table
CREATE TABLE IF NOT EXISTS visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  visit_date timestamptz NOT NULL DEFAULT now(),
  symptoms text,
  diagnosis text,
  observations text,
  follow_up_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 10. Device Data table
CREATE TABLE IF NOT EXISTS device_data (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  device_type text NOT NULL,
  device_name text,
  data_json jsonb NOT NULL,
  uploaded_at timestamptz DEFAULT now(),
  uploaded_by uuid REFERENCES profiles(id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_health_records_patient_date ON health_records(patient_id, recorded_date DESC);
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_prescriptions_doctor ON prescriptions(doctor_id);
CREATE INDEX IF NOT EXISTS idx_medication_schedules_date ON medication_schedules(scheduled_date, scheduled_time);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_visits_patient ON visits(patient_id, visit_date DESC);
CREATE INDEX IF NOT EXISTS idx_visits_doctor ON visits(doctor_id, visit_date DESC);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_data ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Doctors/admins must be able to read patient profiles for doctor dashboard joins
CREATE OR REPLACE FUNCTION public.is_doctor_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role IN ('doctor', 'admin')
  );
$$;

CREATE POLICY "Doctors and admins can view all profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (public.is_doctor_or_admin());

-- Allow patients to see doctor names (for prescriptions) without exposing other patient profiles
CREATE POLICY "All authenticated users can view doctor profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (role = 'doctor');

-- ============================================================================
-- 11. Patient-Doctor Access Links (who is allowed to see whose data)
-- ============================================================================

-- Enum for link status
DO $$ BEGIN
  CREATE TYPE doctor_link_status AS ENUM ('approved', 'revoked');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS patient_doctor_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id uuid NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  status doctor_link_status NOT NULL DEFAULT 'approved',
  created_at timestamptz DEFAULT now(),
  UNIQUE (patient_id, doctor_id)
);

ALTER TABLE patient_doctor_links ENABLE ROW LEVEL SECURITY;

-- Patients: manage their own doctor links (create/see/change)
CREATE POLICY "Patients can manage their doctor links"
  ON patient_doctor_links
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_id AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_id AND p.user_id = auth.uid()
    )
  );

-- Doctors: can only see approved links assigned to them
CREATE POLICY "Doctors can view approved patient links"
  ON patient_doctor_links
  FOR SELECT
  TO authenticated
  USING (
    status = 'approved'
    AND EXISTS (
      SELECT 1 FROM doctors d
      WHERE d.id = doctor_id AND d.user_id = auth.uid()
    )
  );

-- ============================================================================
-- 12. Patient Prescription Files (PDF uploads)
-- ============================================================================

CREATE TABLE IF NOT EXISTS patient_prescription_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_path text NOT NULL,
  uploaded_at timestamptz DEFAULT now(),
  uploaded_by uuid REFERENCES profiles(id)
);

ALTER TABLE patient_prescription_files ENABLE ROW LEVEL SECURITY;

-- Patients can manage (insert/update/delete/select) their own files
CREATE POLICY "Patients manage own prescription files"
  ON patient_prescription_files
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_id AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM patients p
      WHERE p.id = patient_id AND p.user_id = auth.uid()
    )
  );

-- Doctors can view files for approved patients only
CREATE POLICY "Doctors view approved prescription files"
  ON patient_prescription_files
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM patient_doctor_links l
      JOIN doctors d ON l.doctor_id = d.id
      WHERE l.patient_id = patient_id
        AND l.status = 'approved'
        AND d.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Patients policies
CREATE POLICY "Patients can view own data"
  ON patients FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

CREATE POLICY "Patients can update own data"
  ON patients FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Patients can insert own data"
  ON patients FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Doctors policies
CREATE POLICY "Doctors can view doctor profiles"
  ON doctors FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('admin', 'patient'))
  );

CREATE POLICY "Doctors can update own profile"
  ON doctors FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Doctors can insert own profile"
  ON doctors FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Health Records policies
CREATE POLICY "Patients can view own health records"
  ON health_records FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

CREATE POLICY "Patients and doctors can insert health records"
  ON health_records FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

CREATE POLICY "Patients and doctors can update health records"
  ON health_records FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

-- Medications policies (readable by all authenticated users)
CREATE POLICY "All authenticated users can view medications"
  ON medications FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Doctors and admins can insert medications"
  ON medications FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

-- Prescriptions policies
CREATE POLICY "Patients can view own prescriptions"
  ON prescriptions FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Doctors can insert prescriptions"
  ON prescriptions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid())
  );

CREATE POLICY "Doctors can update own prescriptions"
  ON prescriptions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid())
  );

-- Medication Schedules policies
CREATE POLICY "Patients can view own medication schedules"
  ON medication_schedules FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM prescriptions p
      JOIN patients pt ON p.patient_id = pt.id
      WHERE p.id = prescription_id AND pt.user_id = auth.uid()
    ) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

CREATE POLICY "Patients can update own medication schedules"
  ON medication_schedules FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM prescriptions p
      JOIN patients pt ON p.patient_id = pt.id
      WHERE p.id = prescription_id AND pt.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM prescriptions p
      JOIN patients pt ON p.patient_id = pt.id
      WHERE p.id = prescription_id AND pt.user_id = auth.uid()
    )
  );

CREATE POLICY "System can insert medication schedules"
  ON medication_schedules FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Notifications policies
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Visits policies
CREATE POLICY "Patients and doctors can view visits"
  ON visits FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Doctors can insert visits"
  ON visits FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid())
  );

CREATE POLICY "Doctors can update own visits"
  ON visits FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM doctors WHERE id = doctor_id AND user_id = auth.uid())
  );

-- Device Data policies
CREATE POLICY "Patients can view own device data"
  ON device_data FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

CREATE POLICY "Patients and doctors can insert device data"
  ON device_data FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM patients WHERE id = patient_id AND user_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('doctor', 'admin'))
  );

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'patient')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Insert sample medications
INSERT INTO medications (name, generic_name, dosage_form, strength, manufacturer) VALUES
  ('Aspirin', 'Acetylsalicylic Acid', 'Tablet', '75mg', 'Generic Pharma'),
  ('Metformin', 'Metformin HCl', 'Tablet', '500mg', 'Generic Pharma'),
  ('Lisinopril', 'Lisinopril', 'Tablet', '10mg', 'Generic Pharma'),
  ('Amlodipine', 'Amlodipine Besylate', 'Tablet', '5mg', 'Generic Pharma'),
  ('Atorvastatin', 'Atorvastatin Calcium', 'Tablet', '20mg', 'Generic Pharma')
ON CONFLICT DO NOTHING;