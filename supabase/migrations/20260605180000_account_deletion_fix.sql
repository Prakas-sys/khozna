-- Function to allow users to delete their own accounts from auth.users
-- This is safer than an Edge Function for simple deletion as it handles cascading automatically.

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with admin privileges to allow deleting from auth.users
SET search_path = public
AS $$
BEGIN
  -- Security check: Ensure the user is actually authenticated
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Deleting from auth.users will trigger ON DELETE CASCADE 
  -- on public.profiles and everything else linked to it.
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
