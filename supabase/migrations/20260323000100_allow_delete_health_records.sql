-- Allow deleting health records via Supabase RLS
-- Matches the existing "update" policy approach: patients can delete their own
-- records; doctors/admins can delete records for any patient (based on role).

DROP POLICY IF EXISTS "Patients and doctors can delete health records" ON health_records;

CREATE POLICY "Patients and doctors can delete health records"
  ON health_records FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM patients p
      WHERE p.id = health_records.patient_id
        AND p.user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE id = auth.uid()
        AND role IN ('doctor', 'admin')
    )
  );

