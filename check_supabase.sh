#!/bin/bash

echo "🔍 Checking Supabase Configuration for khilonjiya.com"
echo "=================================================="

# Check if .env file exists
if [ -f ".env" ]; then
    echo "✅ .env file found"
    
    # Check if SUPABASE_URL is set
    if grep -q "SUPABASE_URL=" .env; then
        echo "✅ SUPABASE_URL is configured"
        URL=$(grep "SUPABASE_URL=" .env | cut -d'=' -f2)
        if [[ $URL == https://* ]]; then
            echo "✅ URL format looks correct"
        else
            echo "⚠️  URL format might be incorrect (should start with https://)"
        fi
    else
        echo "❌ SUPABASE_URL not found in .env"
    fi
    
    # Check if SUPABASE_ANON_KEY is set
    if grep -q "SUPABASE_ANON_KEY=" .env; then
        echo "✅ SUPABASE_ANON_KEY is configured"
        KEY=$(grep "SUPABASE_ANON_KEY=" .env | cut -d'=' -f2)
        if [[ $KEY == eyJ* ]]; then
            echo "✅ Key format looks correct"
        else
            echo "⚠️  Key format might be incorrect (should start with eyJ)"
        fi
    else
        echo "❌ SUPABASE_ANON_KEY not found in .env"
    fi
    
else
    echo "❌ .env file not found"
    echo "Please create a .env file with your Supabase credentials:"
    echo "SUPABASE_URL=https://your-project-id.supabase.co"
    echo "SUPABASE_ANON_KEY=your-anon-key-here"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Edit .env file with your actual Supabase credentials"
echo "2. Run: flutter pub get"
echo "3. Run: flutter run"
echo ""
echo "📖 For detailed setup instructions, see SUPABASE_SETUP.md"