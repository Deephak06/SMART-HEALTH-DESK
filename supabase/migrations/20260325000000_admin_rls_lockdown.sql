-- Admin lockdown for medical data visibility
-- Removes `admin` from RLS role checks on medical tables so admins cannot read/update medical details.

-- Patients table includes medical_history, so admins must not be able to SELECT other users' patient rows.
DROP POLICY IF EXISTS "Patients can view own data" ON public.patients;
CREATE POLICY "Patients can view own data"
  ON public.patients FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  );

-- Health records policies
DROP POLICY IF EXISTS "Patients can view own health records" ON public.health_records;
CREATE POLICY "Patients can view own health records"
  ON public.health_records FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  );

DROP POLICY IF EXISTS "Patients and doctors can insert health records" ON public.health_records;
CREATE POLICY "Patients and doctors can insert health records"
  ON public.health_records FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  );

DROP POLICY IF EXISTS "Patients and doctors can update health records" ON public.health_records;
CREATE POLICY "Patients and doctors can update health records"
  ON public.health_records FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  );

-- Prescriptions policies
DROP POLICY IF EXISTS "Patients can view own prescriptions" ON public.prescriptions;
CREATE POLICY "Patients can view own prescriptions"
  ON public.prescriptions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.doctors
      WHERE id = doctor_id AND user_id = auth.uid()
    )
  );

-- Medication schedules policies
DROP POLICY IF EXISTS "Patients can view own medication schedules" ON public.medication_schedules;
CREATE POLICY "Patients can view own medication schedules"
  ON public.medication_schedules FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.prescriptions p
      JOIN public.patients pt ON p.patient_id = pt.id
      WHERE p.id = medication_schedules.prescription_id AND pt.user_id = auth.uid()
    )
  );

-- Visits policies
DROP POLICY IF EXISTS "Patients and doctors can view visits" ON public.visits;
CREATE POLICY "Patients and doctors can view visits"
  ON public.visits FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.doctors
      WHERE id = doctor_id AND user_id = auth.uid()
    )
  );

-- Device data policies
DROP POLICY IF EXISTS "Patients can view own device data" ON public.device_data;
CREATE POLICY "Patients can view own device data"
  ON public.device_data FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  );

DROP POLICY IF EXISTS "Patients and doctors can insert device data" ON public.device_data;
CREATE POLICY "Patients and doctors can insert device data"
  ON public.device_data FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.patients
      WHERE id = patient_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  );

-- Health records delete policy (separate migration previously allowed admins)
DROP POLICY IF EXISTS "Patients and doctors can delete health records" ON public.health_records;
CREATE POLICY "Patients and doctors can delete health records"
  ON public.health_records FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.patients p
      WHERE p.id = health_records.patient_id
        AND p.user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'doctor'
    )
  );

