-- IMPLEMENTING MODULE: Missing Database Functions for MarketPlace Pro
-- This migration adds missing database functions and improvements

-- 1. Function to increment favorites count
CREATE OR REPLACE FUNCTION public.increment_favorites_count(listing_uuid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.listings
    SET favorites_count = COALESCE(favorites_count, 0) + 1
    WHERE id = listing_uuid;
END;
$$;

-- 2. Function to decrement favorites count
CREATE OR REPLACE FUNCTION public.decrement_favorites_count(listing_uuid UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.listings
    SET favorites_count = GREATEST(COALESCE(favorites_count, 0) - 1, 0)
    WHERE id = listing_uuid;
END;
$$;

-- 3. Function to get categories with listing counts
CREATE OR REPLACE FUNCTION public.get_categories_with_counts()
RETURNS TABLE(
    id UUID,
    name TEXT,
    description TEXT,
    icon_url TEXT,
    parent_category_id UUID,
    is_active BOOLEAN,
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    listing_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    c.id,
    c.name,
    c.description,
    c.icon_url,
    c.parent_category_id,
    c.is_active,
    c.sort_order,
    c.created_at,
    COUNT(l.id) as listing_count
FROM public.categories c
LEFT JOIN public.listings l ON c.id = l.category_id AND l.status = 'active'
WHERE c.is_active = true
GROUP BY c.id, c.name, c.description, c.icon_url, c.parent_category_id, c.is_active, c.sort_order, c.created_at
ORDER BY c.sort_order, c.name;
$$;

-- 4. Function to get user favorites by category
CREATE OR REPLACE FUNCTION public.get_user_favorites_by_category(user_uuid UUID)
RETURNS TABLE(
    category_name TEXT,
    category_id UUID,
    favorites_count BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    c.name as category_name,
    c.id as category_id,
    COUNT(f.id) as favorites_count
FROM public.favorites f
JOIN public.listings l ON f.listing_id = l.id
JOIN public.categories c ON l.category_id = c.id
WHERE f.user_id = user_uuid
GROUP BY c.id, c.name
ORDER BY favorites_count DESC, c.name;
$$;

-- 5. Function to get popular listings in a time period
CREATE OR REPLACE FUNCTION public.get_popular_listings(
    days_back INTEGER DEFAULT 7,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE(
    id UUID,
    title TEXT,
    price DECIMAL(10,2),
    location TEXT,
    favorites_count INTEGER,
    views_count INTEGER,
    created_at TIMESTAMPTZ,
    seller_name TEXT,
    category_name TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    l.id,
    l.title,
    l.price,
    l.location,
    l.favorites_count,
    l.views_count,
    l.created_at,
    up.full_name as seller_name,
    c.name as category_name
FROM public.listings l
JOIN public.user_profiles up ON l.seller_id = up.id
JOIN public.categories c ON l.category_id = c.id
WHERE l.status = 'active'
    AND l.created_at >= CURRENT_TIMESTAMP - INTERVAL '1 day' * days_back
ORDER BY 
    (l.favorites_count * 2 + l.views_count) DESC,
    l.created_at DESC
LIMIT limit_count;
$$;

-- 6. Function to search listings with ranking
CREATE OR REPLACE FUNCTION public.search_listings_ranked(
    search_query TEXT,
    category_filter UUID DEFAULT NULL,
    location_filter TEXT DEFAULT NULL,
    min_price DECIMAL DEFAULT NULL,
    max_price DECIMAL DEFAULT NULL,
    limit_count INTEGER DEFAULT 20
)
RETURNS TABLE(
    id UUID,
    title TEXT,
    description TEXT,
    price DECIMAL(10,2),
    location TEXT,
    created_at TIMESTAMPTZ,
    seller_name TEXT,
    category_name TEXT,
    relevance_score REAL
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    l.id,
    l.title,
    l.description,
    l.price,
    l.location,
    l.created_at,
    up.full_name as seller_name,
    c.name as category_name,
    (
        CASE WHEN l.title ILIKE '%' || search_query || '%' THEN 3.0 ELSE 0.0 END +
        CASE WHEN l.description ILIKE '%' || search_query || '%' THEN 1.0 ELSE 0.0 END +
        CASE WHEN c.name ILIKE '%' || search_query || '%' THEN 2.0 ELSE 0.0 END +
        CASE WHEN l.is_featured THEN 0.5 ELSE 0.0 END
    ) as relevance_score
FROM public.listings l
JOIN public.user_profiles up ON l.seller_id = up.id
JOIN public.categories c ON l.category_id = c.id
WHERE l.status = 'active'
    AND (
        l.title ILIKE '%' || search_query || '%' OR
        l.description ILIKE '%' || search_query || '%' OR
        c.name ILIKE '%' || search_query || '%'
    )
    AND (category_filter IS NULL OR l.category_id = category_filter)
    AND (location_filter IS NULL OR l.location ILIKE '%' || location_filter || '%')
    AND (min_price IS NULL OR l.price >= min_price)
    AND (max_price IS NULL OR l.price <= max_price)
ORDER BY relevance_score DESC, l.created_at DESC
LIMIT limit_count;
$$;

-- 7. Function to get user statistics
CREATE OR REPLACE FUNCTION public.get_user_statistics(user_uuid UUID)
RETURNS TABLE(
    total_listings BIGINT,
    active_listings BIGINT,
    sold_listings BIGINT,
    total_favorites_received BIGINT,
    total_views_received BIGINT,
    total_conversations BIGINT,
    avg_response_time INTERVAL
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    COUNT(l.id) as total_listings,
    COUNT(CASE WHEN l.status = 'active' THEN 1 END) as active_listings,
    COUNT(CASE WHEN l.status = 'sold' THEN 1 END) as sold_listings,
    COALESCE(SUM(l.favorites_count), 0) as total_favorites_received,
    COALESCE(SUM(l.views_count), 0) as total_views_received,
    COUNT(DISTINCT c.id) as total_conversations,
    AVG(
        CASE WHEN c.seller_id = user_uuid THEN
            EXTRACT(EPOCH FROM (
                SELECT MIN(m.created_at) 
                FROM public.messages m 
                WHERE m.conversation_id = c.id 
                AND m.sender_id = user_uuid
            ) - c.created_at) * INTERVAL '1 second'
        END
    ) as avg_response_time
FROM public.listings l
LEFT JOIN public.conversations c ON l.id = c.listing_id
WHERE l.seller_id = user_uuid;
$$;

-- 8. Trigger to automatically update listing favorites count
CREATE OR REPLACE FUNCTION public.update_listing_favorites_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.listings
        SET favorites_count = COALESCE(favorites_count, 0) + 1
        WHERE id = NEW.listing_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.listings
        SET favorites_count = GREATEST(COALESCE(favorites_count, 0) - 1, 0)
        WHERE id = OLD.listing_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- Create trigger for automatic favorites count update
DROP TRIGGER IF EXISTS trigger_update_listing_favorites_count ON public.favorites;
CREATE TRIGGER trigger_update_listing_favorites_count
    AFTER INSERT OR DELETE ON public.favorites
    FOR EACH ROW
    EXECUTE FUNCTION public.update_listing_favorites_count();

-- 9. Function to get recent activity for a user
CREATE OR REPLACE FUNCTION public.get_user_recent_activity(
    user_uuid UUID,
    activity_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    activity_type TEXT,
    activity_data JSONB,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
(
    SELECT 
        'listing_created' as activity_type,
        jsonb_build_object(
            'listing_id', l.id,
            'title', l.title,
            'price', l.price,
            'category', c.name
        ) as activity_data,
        l.created_at
    FROM public.listings l
    JOIN public.categories c ON l.category_id = c.id
    WHERE l.seller_id = user_uuid
)
UNION ALL
(
    SELECT 
        'favorite_added' as activity_type,
        jsonb_build_object(
            'listing_id', l.id,
            'title', l.title,
            'price', l.price,
            'seller', up.full_name
        ) as activity_data,
        f.created_at
    FROM public.favorites f
    JOIN public.listings l ON f.listing_id = l.id
    JOIN public.user_profiles up ON l.seller_id = up.id
    WHERE f.user_id = user_uuid
)
UNION ALL
(
    SELECT 
        'conversation_started' as activity_type,
        jsonb_build_object(
            'conversation_id', c.id,
            'listing_title', l.title,
            'other_user', CASE 
                WHEN c.buyer_id = user_uuid THEN seller.full_name
                ELSE buyer.full_name
            END
        ) as activity_data,
        c.created_at
    FROM public.conversations c
    JOIN public.listings l ON c.listing_id = l.id
    JOIN public.user_profiles seller ON c.seller_id = seller.id
    JOIN public.user_profiles buyer ON c.buyer_id = buyer.id
    WHERE c.buyer_id = user_uuid OR c.seller_id = user_uuid
)
ORDER BY created_at DESC
LIMIT activity_limit;
$$;

-- 10. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_listings_favorites_count ON public.listings(favorites_count DESC);
CREATE INDEX IF NOT EXISTS idx_listings_status_created_at ON public.listings(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_listings_category_status ON public.listings(category_id, status);
CREATE INDEX IF NOT EXISTS idx_favorites_user_created ON public.favorites(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON public.conversations(buyer_id, seller_id);

COMMENT ON FUNCTION public.increment_favorites_count(UUID) IS 'Safely increments the favorites count for a listing';
COMMENT ON FUNCTION public.decrement_favorites_count(UUID) IS 'Safely decrements the favorites count for a listing';
COMMENT ON FUNCTION public.get_categories_with_counts() IS 'Returns categories with their active listing counts';
COMMENT ON FUNCTION public.get_user_favorites_by_category(UUID) IS 'Returns user favorites grouped by category';
COMMENT ON FUNCTION public.get_popular_listings(INTEGER, INTEGER) IS 'Returns popular listings based on favorites and views';
COMMENT ON FUNCTION public.search_listings_ranked(TEXT, UUID, TEXT, DECIMAL, DECIMAL, INTEGER) IS 'Performs ranked search on listings';
COMMENT ON FUNCTION public.get_user_statistics(UUID) IS 'Returns comprehensive statistics for a user';
COMMENT ON FUNCTION public.get_user_recent_activity(UUID, INTEGER) IS 'Returns recent activity timeline for a user';