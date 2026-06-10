-- ============================================================
-- MyROF Report — Database Setup
-- ============================================================
-- Paste this entire file into your Supabase SQL Editor and click Run.
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE where possible.
-- ============================================================


-- ----------------------------------------------------------
-- Migration: 20250620144623-13da0cb3-7d28-4f70-82b0-f4febd6b1ff3.sql
-- ----------------------------------------------------------

-- Insert the new "Condition Specific" subcategory under Homecare
INSERT INTO public.library_subcategories (id, name, description, parent_category_id)
VALUES ('condition_specific', 'Condition Specific', 'Recommendations specific to certain conditions', 'homecare');

-- ----------------------------------------------------------
-- Migration: 20250722132132-fff4cead-8ce9-4275-957c-3e3ab11cc7cf.sql
-- ----------------------------------------------------------

-- Create patients table for posture assessment
CREATE TABLE public.patients (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT NOT NULL,
  date_of_birth DATE,
  gender TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create posture_assessments table
CREATE TABLE public.posture_assessments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id UUID REFERENCES public.patients(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  assessment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create posture_photos table
CREATE TABLE public.posture_photos (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  assessment_id UUID REFERENCES public.posture_assessments(id) ON DELETE CASCADE NOT NULL,
  photo_type TEXT NOT NULL CHECK (photo_type IN ('side', 'front', 'back')),
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create posture_measurements table
CREATE TABLE public.posture_measurements (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  assessment_id UUID REFERENCES public.posture_assessments(id) ON DELETE CASCADE NOT NULL,
  measurement_type TEXT NOT NULL,
  value DECIMAL(10, 2) NOT NULL,
  unit TEXT NOT NULL,
  severity TEXT CHECK (severity IN ('Normal', 'Mild', 'Moderate', 'Severe')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Add RLS policies for patients table
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own patients" 
  ON public.patients 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own patients" 
  ON public.patients 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own patients" 
  ON public.patients 
  FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own patients" 
  ON public.patients 
  FOR DELETE 
  USING (auth.uid() = user_id);

-- Add RLS policies for posture_assessments table
ALTER TABLE public.posture_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own assessments" 
  ON public.posture_assessments 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own assessments" 
  ON public.posture_assessments 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own assessments" 
  ON public.posture_assessments 
  FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own assessments" 
  ON public.posture_assessments 
  FOR DELETE 
  USING (auth.uid() = user_id);

-- Add RLS policies for posture_photos table
ALTER TABLE public.posture_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view photos from their assessments" 
  ON public.posture_photos 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_photos.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create photos for their assessments" 
  ON public.posture_photos 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_photos.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update photos from their assessments" 
  ON public.posture_photos 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_photos.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete photos from their assessments" 
  ON public.posture_photos 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_photos.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

-- Add RLS policies for posture_measurements table
ALTER TABLE public.posture_measurements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view measurements from their assessments" 
  ON public.posture_measurements 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_measurements.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create measurements for their assessments" 
  ON public.posture_measurements 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_measurements.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update measurements from their assessments" 
  ON public.posture_measurements 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_measurements.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete measurements from their assessments" 
  ON public.posture_measurements 
  FOR DELETE 
  USING (
    EXISTS (
      SELECT 1 FROM public.posture_assessments 
      WHERE posture_assessments.id = posture_measurements.assessment_id 
      AND posture_assessments.user_id = auth.uid()
    )
  );

-- Create storage bucket for posture photos
INSERT INTO storage.buckets (id, name, public) 
VALUES ('posture-photos', 'posture-photos', false);

-- Create storage policies for posture photos
CREATE POLICY "Users can view their posture photos" 
  ON storage.objects 
  FOR SELECT 
  USING (
    bucket_id = 'posture-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can upload their posture photos" 
  ON storage.objects 
  FOR INSERT 
  WITH CHECK (
    bucket_id = 'posture-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their posture photos" 
  ON storage.objects 
  FOR UPDATE 
  USING (
    bucket_id = 'posture-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their posture photos" 
  ON storage.objects 
  FOR DELETE 
  USING (
    bucket_id = 'posture-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Create trigger for updating updated_at timestamps
CREATE TRIGGER update_patients_updated_at
  BEFORE UPDATE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION public.update_modified_column();

CREATE TRIGGER update_posture_assessments_updated_at
  BEFORE UPDATE ON public.posture_assessments
  FOR EACH ROW EXECUTE FUNCTION public.update_modified_column();

-- ----------------------------------------------------------
-- Migration: 20260309152243_799345d3-36f1-41c5-9555-94e157ddf0ae.sql
-- ----------------------------------------------------------
ALTER TABLE public.library_items ADD COLUMN definition text;
-- ----------------------------------------------------------
-- Migration: 20260311220750_3fad8137-d2b2-428d-b54f-c17365113f92.sql
-- ----------------------------------------------------------

CREATE OR REPLACE FUNCTION public.claim_and_update_library_item(
  _item_id uuid,
  _user_id uuid,
  _name text,
  _definition text,
  _description text,
  _info_link text,
  _category_id text,
  _subcategory_id text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _owner_id uuid;
  _new_id uuid;
BEGIN
  -- Check who owns the item
  SELECT user_id INTO _owner_id FROM library_items WHERE id = _item_id;
  
  IF _owner_id IS NULL OR _owner_id = _user_id THEN
    -- User owns it (or no owner), just update directly
    UPDATE library_items SET
      name = _name,
      definition = _definition,
      description = _description,
      info_link = _info_link,
      category_id = _category_id,
      subcategory_id = _subcategory_id,
      user_id = _user_id,
      updated_at = now()
    WHERE id = _item_id;
    RETURN _item_id;
  ELSE
    -- Different owner: delete old, insert new
    DELETE FROM library_items WHERE id = _item_id;
    INSERT INTO library_items (name, definition, description, info_link, category_id, subcategory_id, user_id)
    VALUES (_name, _definition, _description, _info_link, _category_id, _subcategory_id, _user_id)
    RETURNING id INTO _new_id;
    RETURN _new_id;
  END IF;
END;
$$;

-- ----------------------------------------------------------
-- Migration: 20260323135237_719791a7-7c43-4fb6-99d2-fc88f54f510b.sql
-- ----------------------------------------------------------

-- Create the shared-reports storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('shared-reports', 'shared-reports', true);

-- Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload shared reports"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'shared-reports');

-- Allow public read access
CREATE POLICY "Public can read shared reports"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'shared-reports');

-- ----------------------------------------------------------
-- Migration: 20260423183928_47509466-d342-4070-aa8e-f0f0bf7ed295.sql
-- ----------------------------------------------------------

-- Care plans table: stores both auto-saved drafts and manually saved named plans
CREATE TABLE public.care_plans (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL,
  title text NOT NULL DEFAULT 'Untitled Care Plan',
  is_draft boolean NOT NULL DEFAULT false,
  patient_name text,
  report_date text,
  selected_item_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  additional_notes text,
  custom_treatment_goals text,
  active_category text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now()
);

-- Ensure only ONE rolling draft exists per user
CREATE UNIQUE INDEX care_plans_one_draft_per_user
  ON public.care_plans (user_id)
  WHERE is_draft = true;

CREATE INDEX care_plans_user_updated_idx ON public.care_plans (user_id, updated_at DESC);

ALTER TABLE public.care_plans ENABLE ROW LEVEL SECURITY;

-- Shared across the clinic: any authenticated user can view/load/edit/delete
CREATE POLICY "Authenticated users can view all care plans"
  ON public.care_plans FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create care plans"
  ON public.care_plans FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Authenticated users can update care plans"
  ON public.care_plans FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can delete care plans"
  ON public.care_plans FOR DELETE
  TO authenticated
  USING (true);

-- Updated_at trigger
CREATE TRIGGER care_plans_set_updated_at
  BEFORE UPDATE ON public.care_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.update_modified_column();

-- ----------------------------------------------------------
-- Migration: 20260502163134_276bdef2-37eb-43f4-8686-be4bd10edd32.sql
-- ----------------------------------------------------------
INSERT INTO library_subcategories (id, name, parent_category_id) VALUES ('general_exercises', 'General', 'exercises');
-- ----------------------------------------------------------
-- Migration: 20260521133443_f3cf629f-40bc-4603-abc1-440d240d0695.sql
-- ----------------------------------------------------------
INSERT INTO public.library_subcategories (id, name, parent_category_id, description) VALUES ('phase_of_care', 'Phase of Care', 'treatment', 'Phase of care for treatment plan');
-- ----------------------------------------------------------
-- Migration: 20260521135121_0ecd28db-2f60-4254-a450-0db23027b520.sql
-- ----------------------------------------------------------

-- 1. care_plans: scope SELECT/UPDATE/DELETE to owner
DROP POLICY IF EXISTS "Authenticated users can view all care plans" ON public.care_plans;
DROP POLICY IF EXISTS "Authenticated users can update care plans" ON public.care_plans;
DROP POLICY IF EXISTS "Authenticated users can delete care plans" ON public.care_plans;

CREATE POLICY "Users can view their own care plans"
  ON public.care_plans FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own care plans"
  ON public.care_plans FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own care plans"
  ON public.care_plans FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- 2. report_settings: restrict reads + writes to authenticated users (single-clinic app)
DROP POLICY IF EXISTS "Allow public read access" ON public.report_settings;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON public.report_settings;
DROP POLICY IF EXISTS "Allow authenticated users to update" ON public.report_settings;
DROP POLICY IF EXISTS "Allow authenticated users to delete" ON public.report_settings;

CREATE POLICY "Authenticated can read report settings"
  ON public.report_settings FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Authenticated can insert report settings"
  ON public.report_settings FOR INSERT TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated can update report settings"
  ON public.report_settings FOR UPDATE TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated can delete report settings"
  ON public.report_settings FOR DELETE TO authenticated
  USING (auth.uid() IS NOT NULL);

-- 3. clinic-assets storage: scope UPDATE/DELETE to file owner
DROP POLICY IF EXISTS "Allow authenticated users to update files" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete files" ON storage.objects;

CREATE POLICY "Users can update their own clinic-assets files"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'clinic-assets' AND owner = auth.uid())
  WITH CHECK (bucket_id = 'clinic-assets' AND owner = auth.uid());

CREATE POLICY "Users can delete their own clinic-assets files"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'clinic-assets' AND owner = auth.uid());

-- 4. shared-reports storage: add owner-scoped UPDATE/DELETE
CREATE POLICY "Users can update their own shared-reports files"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'shared-reports' AND owner = auth.uid())
  WITH CHECK (bucket_id = 'shared-reports' AND owner = auth.uid());

CREATE POLICY "Users can delete their own shared-reports files"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'shared-reports' AND owner = auth.uid());

-- 5. Lock down SECURITY DEFINER function so only authenticated users can execute it
REVOKE EXECUTE ON FUNCTION public.claim_and_update_library_item(uuid, uuid, text, text, text, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_and_update_library_item(uuid, uuid, text, text, text, text, text, text) TO authenticated;

-- 6. Fix mutable search_path on update_modified_column trigger function
CREATE OR REPLACE FUNCTION public.update_modified_column()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $function$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$function$;

-- ----------------------------------------------------------
-- Migration: 20260522131238_3bf6e17b-2d26-4651-82ed-6af9aa080564.sql
-- ----------------------------------------------------------
UPDATE public.library_subcategories SET name = 'Miscellaneous' WHERE id = 'wellness';
-- ----------------------------------------------------------
-- Migration: 20260524133747_9a06f387-42eb-4dc0-8304-01473904622d.sql
-- ----------------------------------------------------------
DELETE FROM public.library_subcategories WHERE id='estimated_cost';
-- ----------------------------------------------------------
-- Migration: 20260608131045_library_grants_and_rls.sql
-- ----------------------------------------------------------
-- Fix 403 errors from the Data API by ensuring GRANTs and RLS policies
-- exist for the library_* and care_plans tables. Safe to re-run.

-- 1. GRANTs
GRANT SELECT ON public.library_categories    TO anon, authenticated;
GRANT SELECT ON public.library_subcategories TO anon, authenticated;
GRANT ALL    ON public.library_categories    TO service_role;
GRANT ALL    ON public.library_subcategories TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.library_items TO authenticated;
GRANT ALL ON public.library_items TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.care_plans TO authenticated;
GRANT ALL ON public.care_plans TO service_role;

-- 2. Enable RLS
ALTER TABLE public.library_categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.library_subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.library_items         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_plans            ENABLE ROW LEVEL SECURITY;

-- 3. library_categories (reference data)
DROP POLICY IF EXISTS "Authenticated can read categories" ON public.library_categories;
CREATE POLICY "Authenticated can read categories"
  ON public.library_categories FOR SELECT
  TO authenticated, anon
  USING (true);

-- 4. library_subcategories (reference data)
DROP POLICY IF EXISTS "Authenticated can read subcategories" ON public.library_subcategories;
CREATE POLICY "Authenticated can read subcategories"
  ON public.library_subcategories FOR SELECT
  TO authenticated, anon
  USING (true);

-- 5. library_items (per-user; shared rows have user_id IS NULL)
DROP POLICY IF EXISTS "Users read own or shared library items" ON public.library_items;
DROP POLICY IF EXISTS "Users insert own library items"         ON public.library_items;
DROP POLICY IF EXISTS "Users update own library items"         ON public.library_items;
DROP POLICY IF EXISTS "Users delete own library items"         ON public.library_items;

CREATE POLICY "Users read own or shared library items"
  ON public.library_items FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users insert own library items"
  ON public.library_items FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users update own library items"
  ON public.library_items FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users delete own library items"
  ON public.library_items FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- 6. care_plans (strictly per-user)
DROP POLICY IF EXISTS "Users read own care plans"   ON public.care_plans;
DROP POLICY IF EXISTS "Users insert own care plans" ON public.care_plans;
DROP POLICY IF EXISTS "Users update own care plans" ON public.care_plans;
DROP POLICY IF EXISTS "Users delete own care plans" ON public.care_plans;

CREATE POLICY "Users read own care plans"
  ON public.care_plans FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users insert own care plans"
  ON public.care_plans FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users update own care plans"
  ON public.care_plans FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users delete own care plans"
  ON public.care_plans FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- Storage: shared-reports bucket (public)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('shared-reports', 'shared-reports', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "shared_reports_public_read" ON storage.objects;
CREATE POLICY "shared_reports_public_read"
  ON storage.objects FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'shared-reports');

DROP POLICY IF EXISTS "shared_reports_auth_insert" ON storage.objects;
CREATE POLICY "shared_reports_auth_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'shared-reports');

DROP POLICY IF EXISTS "shared_reports_auth_update" ON storage.objects;
CREATE POLICY "shared_reports_auth_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'shared-reports');

DROP POLICY IF EXISTS "shared_reports_auth_delete" ON storage.objects;
CREATE POLICY "shared_reports_auth_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'shared-reports');

SELECT 'Setup complete' AS status;
