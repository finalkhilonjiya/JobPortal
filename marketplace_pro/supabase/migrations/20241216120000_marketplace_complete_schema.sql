-- IMPLEMENTING MODULE: Marketplace Complete System
-- This migration creates the complete database schema for marketplace_pro

-- 1. Create custom types
CREATE TYPE public.user_role AS ENUM ('admin', 'seller', 'buyer');
CREATE TYPE public.listing_status AS ENUM ('active', 'sold', 'expired', 'draft');
CREATE TYPE public.listing_condition AS ENUM ('new', 'like_new', 'good', 'fair', 'poor');
CREATE TYPE public.message_type AS ENUM ('text', 'image', 'location', 'voice');
CREATE TYPE public.verification_status AS ENUM ('pending', 'verified', 'rejected');

-- 2. Core tables
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    phone_number TEXT,
    location TEXT,
    bio TEXT,
    role public.user_role DEFAULT 'buyer'::public.user_role,
    verification_status public.verification_status DEFAULT 'pending'::public.verification_status,
    is_active BOOLEAN DEFAULT true,
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_ratings INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    parent_category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    condition public.listing_condition DEFAULT 'good'::public.listing_condition,
    status public.listing_status DEFAULT 'active'::public.listing_status,
    location TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    images JSONB DEFAULT '[]'::jsonb,
    views_count INTEGER DEFAULT 0,
    favorites_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID REFERENCES public.listings(id) ON DELETE CASCADE,
    buyer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    seller_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    last_message TEXT,
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_read_by_buyer BOOLEAN DEFAULT false,
    is_read_by_seller BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT,
    message_type public.message_type DEFAULT 'text'::public.message_type,
    image_url TEXT,
    location_data JSONB,
    voice_url TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    listing_id UUID REFERENCES public.listings(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, listing_id)
);

CREATE TABLE public.search_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    search_query TEXT NOT NULL,
    filters JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.price_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
    max_price DECIMAL(10,2) NOT NULL,
    keywords TEXT[],
    location TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_categories_parent ON public.categories(parent_category_id);
CREATE INDEX idx_listings_seller ON public.listings(seller_id);
CREATE INDEX idx_listings_category ON public.listings(category_id);
CREATE INDEX idx_listings_status ON public.listings(status);
CREATE INDEX idx_listings_location ON public.listings(location);
CREATE INDEX idx_listings_price ON public.listings(price);
CREATE INDEX idx_listings_created_at ON public.listings(created_at DESC);
CREATE INDEX idx_conversations_listing ON public.conversations(listing_id);
CREATE INDEX idx_conversations_buyer ON public.conversations(buyer_id);
CREATE INDEX idx_conversations_seller ON public.conversations(seller_id);
CREATE INDEX idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX idx_favorites_user ON public.favorites(user_id);
CREATE INDEX idx_favorites_listing ON public.favorites(listing_id);
CREATE INDEX idx_search_history_user ON public.search_history(user_id);
CREATE INDEX idx_price_alerts_user ON public.price_alerts(user_id);

-- 4. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_alerts ENABLE ROW LEVEL SECURITY;

-- 5. Helper Functions
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role = 'admin'
)
$$;

CREATE OR REPLACE FUNCTION public.owns_listing(listing_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.listings l
    WHERE l.id = listing_uuid AND l.seller_id = auth.uid()
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_conversation(conversation_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_uuid 
    AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
)
$$;

CREATE OR REPLACE FUNCTION public.can_access_message(message_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.messages m
    JOIN public.conversations c ON m.conversation_id = c.id
    WHERE m.id = message_uuid 
    AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
)
$$;

-- 6. RLS Policies
-- User profiles
CREATE POLICY "users_view_all_profiles" ON public.user_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "users_update_own_profile" ON public.user_profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "admin_full_access_profiles" ON public.user_profiles FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Categories
CREATE POLICY "categories_public_read" ON public.categories FOR SELECT TO public USING (is_active = true);
CREATE POLICY "admin_manage_categories" ON public.categories FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Listings
CREATE POLICY "listings_public_read_active" ON public.listings FOR SELECT TO public USING (status = 'active');
CREATE POLICY "sellers_manage_own_listings" ON public.listings FOR ALL TO authenticated USING (public.owns_listing(id) OR public.is_admin()) WITH CHECK (seller_id = auth.uid() OR public.is_admin());

-- Conversations
CREATE POLICY "conversation_participants_access" ON public.conversations FOR ALL TO authenticated USING (public.can_access_conversation(id)) WITH CHECK (buyer_id = auth.uid() OR seller_id = auth.uid());

-- Messages
CREATE POLICY "message_participants_access" ON public.messages FOR ALL TO authenticated USING (public.can_access_message(id)) WITH CHECK (sender_id = auth.uid());

-- Favorites
CREATE POLICY "users_manage_own_favorites" ON public.favorites FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Search history
CREATE POLICY "users_manage_own_search_history" ON public.search_history FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Price alerts
CREATE POLICY "users_manage_own_price_alerts" ON public.price_alerts FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. Functions and Triggers
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'buyer')::public.user_role
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.update_listing_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_listings_updated_at
    BEFORE UPDATE ON public.listings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_listing_updated_at();

CREATE OR REPLACE FUNCTION public.update_user_profile_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_profile_updated_at();

-- 8. Mock Data
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    seller1_uuid UUID := gen_random_uuid();
    seller2_uuid UUID := gen_random_uuid();
    buyer1_uuid UUID := gen_random_uuid();
    buyer2_uuid UUID := gen_random_uuid();
    electronics_cat_id UUID := gen_random_uuid();
    phones_cat_id UUID := gen_random_uuid();
    furniture_cat_id UUID := gen_random_uuid();
    vehicles_cat_id UUID := gen_random_uuid();
    clothing_cat_id UUID := gen_random_uuid();
    listing1_id UUID := gen_random_uuid();
    listing2_id UUID := gen_random_uuid();
    listing3_id UUID := gen_random_uuid();
    listing4_id UUID := gen_random_uuid();
    listing5_id UUID := gen_random_uuid();
    conversation1_id UUID := gen_random_uuid();
    conversation2_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with all required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@marketplace.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (seller1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'john.seller@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "John Smith", "role": "seller"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (seller2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sarah.tech@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Johnson", "role": "seller"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (buyer1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'mike.buyer@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Mike Wilson", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (buyer2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'emma.davis@example.com', crypt('password123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Emma Davis", "role": "buyer"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Insert categories
    INSERT INTO public.categories (id, name, description, sort_order) VALUES
        (electronics_cat_id, 'Electronics', 'Electronic devices and gadgets', 1),
        (furniture_cat_id, 'Furniture', 'Home and office furniture', 2),
        (vehicles_cat_id, 'Vehicles', 'Cars, motorcycles, and other vehicles', 3),
        (clothing_cat_id, 'Clothing', 'Fashion and apparel', 4);

    INSERT INTO public.categories (id, name, description, parent_category_id, sort_order) VALUES
        (phones_cat_id, 'Smartphones', 'Mobile phones and accessories', electronics_cat_id, 1);

    -- Insert listings
    INSERT INTO public.listings (id, seller_id, category_id, title, description, price, condition, location, images) VALUES
        (listing1_id, seller1_uuid, phones_cat_id, 'iPhone 14 Pro Max 256GB', 
         'Excellent condition iPhone 14 Pro Max in Space Black. Includes original box, charger, and unused EarPods. No scratches or dents.',
         899.99, 'like_new', 'San Francisco, CA',
         '["https://images.unsplash.com/photo-1556656793-08538906a9f8?w=500", "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500"]'::jsonb),
        (listing2_id, seller2_uuid, electronics_cat_id, 'MacBook Air M2 13-inch', 
         'Brand new MacBook Air with M2 chip, 8GB RAM, 256GB SSD. Still sealed in original packaging. Perfect for students and professionals.',
         1199.99, 'new', 'Los Angeles, CA',
         '["https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=500", "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=500"]'::jsonb),
        (listing3_id, seller1_uuid, furniture_cat_id, 'Modern Dining Table Set',
         'Beautiful oak dining table with 6 chairs. Great condition, only used for special occasions. Seats up to 6 people comfortably.',
         450.00, 'good', 'New York, NY',
         '["https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=500", "https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=500"]'::jsonb),
        (listing4_id, seller2_uuid, vehicles_cat_id, '2020 Honda Civic',
         'Well-maintained Honda Civic with low mileage. Regular oil changes, clean interior, excellent fuel economy. Single owner vehicle.',
         18500.00, 'good', 'Chicago, IL',
         '["https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=500", "https://images.unsplash.com/photo-1494976688153-ca85f3fc2480?w=500"]'::jsonb),
        (listing5_id, seller1_uuid, clothing_cat_id, 'Designer Winter Jacket',
         'Premium winter jacket from a luxury brand. Size Medium, hardly worn. Perfect for cold weather with excellent insulation.',
         180.00, 'like_new', 'Seattle, WA',
         '["https://images.unsplash.com/photo-1544966503-7cc5ac882d5f?w=500", "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=500"]'::jsonb);

    -- Insert conversations
    INSERT INTO public.conversations (id, listing_id, buyer_id, seller_id, last_message, last_message_at) VALUES
        (conversation1_id, listing1_id, buyer1_uuid, seller1_uuid, 'Is the phone still available?', now() - interval '2 hours'),
        (conversation2_id, listing2_id, buyer2_uuid, seller2_uuid, 'Can you meet tomorrow for pickup?', now() - interval '30 minutes');

    -- Insert messages
    INSERT INTO public.messages (conversation_id, sender_id, content, message_type) VALUES
        (conversation1_id, buyer1_uuid, 'Hi! Is the iPhone still available?', 'text'),
        (conversation1_id, seller1_uuid, 'Yes, it is! Are you interested in seeing it?', 'text'),
        (conversation1_id, buyer1_uuid, 'Definitely! Can we meet this weekend?', 'text'),
        (conversation2_id, buyer2_uuid, 'Hello! Is the MacBook still for sale?', 'text'),
        (conversation2_id, seller2_uuid, 'Yes! It is brand new and sealed.', 'text'),
        (conversation2_id, buyer2_uuid, 'Perfect! Can you meet tomorrow for pickup?', 'text');

    -- Insert favorites
    INSERT INTO public.favorites (user_id, listing_id) VALUES
        (buyer1_uuid, listing1_id),
        (buyer1_uuid, listing3_id),
        (buyer2_uuid, listing2_id),
        (buyer2_uuid, listing5_id);

    -- Insert search history
    INSERT INTO public.search_history (user_id, search_query, filters) VALUES
        (buyer1_uuid, 'iPhone', '{"category": "Electronics", "max_price": 1000}'::jsonb),
        (buyer1_uuid, 'dining table', '{"category": "Furniture", "location": "New York"}'::jsonb),
        (buyer2_uuid, 'MacBook', '{"category": "Electronics", "condition": "new"}'::jsonb);

    -- Insert price alerts
    INSERT INTO public.price_alerts (user_id, category_id, max_price, keywords) VALUES
        (buyer1_uuid, electronics_cat_id, 500.00, ARRAY['iPhone', 'iPad', 'MacBook']),
        (buyer2_uuid, vehicles_cat_id, 20000.00, ARRAY['Honda', 'Toyota', 'Civic']);

END $$;

-- 9. Cleanup function for test data
CREATE OR REPLACE FUNCTION public.cleanup_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    auth_user_ids_to_delete UUID[];
BEGIN
    -- Get auth user IDs to delete
    SELECT ARRAY_AGG(id) INTO auth_user_ids_to_delete
    FROM auth.users
    WHERE email LIKE '%@example.com' OR email LIKE '%@marketplace.com';

    -- Delete in dependency order
    DELETE FROM public.price_alerts WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.search_history WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.favorites WHERE user_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.messages WHERE sender_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.conversations WHERE buyer_id = ANY(auth_user_ids_to_delete) OR seller_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.listings WHERE seller_id = ANY(auth_user_ids_to_delete);
    DELETE FROM public.categories WHERE name IN ('Electronics', 'Smartphones', 'Furniture', 'Vehicles', 'Clothing');
    DELETE FROM public.user_profiles WHERE id = ANY(auth_user_ids_to_delete);
    
    -- Delete auth.users last
    DELETE FROM auth.users WHERE id = ANY(auth_user_ids_to_delete);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;