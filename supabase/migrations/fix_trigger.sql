-- Fix for the handle_new_user trigger with better error handling
-- Run this in Supabase SQL Editor if you're getting 500 errors on signup

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Create improved function with error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Try to insert profile, but handle errors gracefully
  BEGIN
    INSERT INTO profiles (id, full_name, phone, role)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
      COALESCE(NEW.raw_user_meta_data->>'phone', NULL),
      COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'patient'::user_role)
    )
    ON CONFLICT (id) DO NOTHING; -- Prevent duplicate key errors
  EXCEPTION
    WHEN OTHERS THEN
      -- Log the error but don't fail the user creation
      RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
      -- Still return NEW to allow user creation to succeed
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Verify the trigger exists
SELECT
  trigger_name, 
  event_manipulation, 
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
