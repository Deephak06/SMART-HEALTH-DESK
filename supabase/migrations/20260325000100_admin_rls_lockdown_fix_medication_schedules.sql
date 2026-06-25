-- Fix: ensure doctor can still view medication schedules after admin lockdown.

DROP POLICY IF EXISTS "Patients can view own medication schedules" ON public.medication_schedules;

CREATE POLICY "Patients can view own medication schedules"
  ON public.medication_schedules FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.prescriptions p
      JOIN public.patients pt ON p.patient_id = pt.id
      WHERE p.id = medication_schedules.prescription_id
        AND pt.user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1
      FROM public.profiles
      WHERE id = auth.uid() AND role = 'doctor'
    )
  );

