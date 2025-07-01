-- Fix Row Level Security policies for ParentGuidance app

-- First, let's check current policies (you can run this to see what exists)
-- SELECT * FROM pg_policies WHERE tablename IN ('profiles', 'children');

-- Enable RLS on profiles table (if not already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid()::text = id);

-- Allow users to read their own profile
CREATE POLICY "Users can read their own profile" ON profiles
    FOR SELECT USING (auth.uid()::text = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid()::text = id);

-- Enable RLS on children table (if not already enabled)
ALTER TABLE children ENABLE ROW LEVEL SECURITY;

-- Allow users to insert children for their family
CREATE POLICY "Users can insert children for their family" ON children
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.family_id = children.family_id 
            AND profiles.id = auth.uid()::text
        )
    );

-- Allow users to read children from their family
CREATE POLICY "Users can read their family children" ON children
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.family_id = children.family_id 
            AND profiles.id = auth.uid()::text
        )
    );

-- Allow users to update children from their family
CREATE POLICY "Users can update their family children" ON children
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.family_id = children.family_id 
            AND profiles.id = auth.uid()::text
        )
    );

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON TABLE profiles TO authenticated;
GRANT ALL ON TABLE children TO authenticated;