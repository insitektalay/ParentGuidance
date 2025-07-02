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

-- Enable RLS on families table (if not already enabled)
ALTER TABLE families ENABLE ROW LEVEL SECURITY;

-- Allow users to create their own family
CREATE POLICY "Users can create families" ON families
    FOR INSERT WITH CHECK (true);

-- Allow users to read families they are members of
CREATE POLICY "Users can read their family" ON families
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.family_id = families.id 
            AND profiles.id = auth.uid()::text
        )
    );

-- Allow users to update their family
CREATE POLICY "Users can update their family" ON families
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.family_id = families.id 
            AND profiles.id = auth.uid()::text
        )
    );

-- Enable RLS on situations table (if not already enabled)
ALTER TABLE situations ENABLE ROW LEVEL SECURITY;

-- Allow users to insert situations for their family
CREATE POLICY "Users can insert situations for their family" ON situations
    FOR INSERT WITH CHECK (
        family_id IS NULL OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.family_id = situations.family_id 
            AND profiles.id = auth.uid()::text
        )
    );

-- Allow users to read situations from their family
CREATE POLICY "Users can read their family situations" ON situations
    FOR SELECT USING (
        family_id IS NULL OR EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.family_id = situations.family_id 
            AND profiles.id = auth.uid()::text
        )
    );

-- Enable RLS on guidance table (if not already enabled)
ALTER TABLE guidance ENABLE ROW LEVEL SECURITY;

-- Allow users to insert guidance for situations they have access to
CREATE POLICY "Users can insert guidance for their situations" ON guidance
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM situations s
            JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
            WHERE s.id = guidance.situation_id 
            AND p.id = auth.uid()::text
        )
    );

-- Allow users to read guidance for situations they have access to
CREATE POLICY "Users can read guidance for their situations" ON guidance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM situations s
            JOIN profiles p ON (s.family_id = p.family_id OR s.family_id IS NULL)
            WHERE s.id = guidance.situation_id 
            AND p.id = auth.uid()::text
        )
    );

-- Grant necessary permissions to authenticated users
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON TABLE profiles TO authenticated;
GRANT ALL ON TABLE children TO authenticated;
GRANT ALL ON TABLE families TO authenticated;
GRANT ALL ON TABLE situations TO authenticated;
GRANT ALL ON TABLE guidance TO authenticated;