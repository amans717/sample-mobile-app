-- ==============================================================================
-- CRM Call Sample - Supabase Database Schema & Storage Setup
-- ==============================================================================

-- 1. Create call_recordings table
CREATE TABLE IF NOT EXISTS public.call_recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contact_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    file_url TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 2. Create index on phone and created_at for fast queries
CREATE INDEX IF NOT EXISTS idx_call_recordings_phone ON public.call_recordings(phone);
CREATE INDEX IF NOT EXISTS idx_call_recordings_created_at ON public.call_recordings(created_at DESC);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.call_recordings ENABLE ROW LEVEL SECURITY;

-- Allow public read access to call recordings (for development/demo)
CREATE POLICY "Allow public read access on call_recordings"
ON public.call_recordings
FOR SELECT
TO public
USING (true);

-- Allow public insert access on call_recordings
CREATE POLICY "Allow public insert access on call_recordings"
ON public.call_recordings
FOR INSERT
TO public
WITH CHECK (true);

-- Allow public delete access on call_recordings
CREATE POLICY "Allow public delete access on call_recordings"
ON public.call_recordings
FOR DELETE
TO public
USING (true);

-- 4. Storage Bucket Setup
-- Note: You can also create the bucket named 'call-recordings' via Supabase Studio UI
INSERT INTO storage.buckets (id, name, public)
VALUES ('call-recordings', 'call-recordings', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage Policy: Allow public read access to audio recordings
CREATE POLICY "Allow public read access to call-recordings bucket"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'call-recordings');

-- Storage Policy: Allow public upload to call-recordings bucket
CREATE POLICY "Allow public upload to call-recordings bucket"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'call-recordings');

-- Storage Policy: Allow public delete from call-recordings bucket
CREATE POLICY "Allow public delete from call-recordings bucket"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'call-recordings');
