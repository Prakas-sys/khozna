-- Update file size limit for 'reels' bucket to 50MB (50 * 1024 * 1024 bytes)
UPDATE storage.buckets 
SET file_size_limit = 52428800 
WHERE id = 'reels';
