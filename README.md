# Marketplace Pro

A comprehensive Flutter marketplace application with Supabase backend integration.

## 🚀 Features

- **Authentication**: Sign up, sign in, and user management
- **Marketplace**: Browse, search, and filter listings
- **Categories**: Organized product categorization
- **Messaging**: Real-time chat between buyers and sellers
- **Favorites**: Save and manage favorite listings
- **User Profiles**: Comprehensive user management
- **Real-time**: Live updates for messages and listings

## 🛠 Tech Stack

- **Frontend**: Flutter 3.16.0+, Dart 3.2.0+
- **Backend**: Supabase (PostgreSQL, Auth, Real-time, Storage)
- **State Management**: Built-in Flutter state management
- **UI**: Material Design with custom theming

## 📋 Prerequisites

Before running this application, make sure you have:

- Flutter SDK (3.16.0 or higher)
- Dart SDK (3.2.0 or higher)
- Supabase account and project

## 🔧 Setup

### 1. Supabase Configuration

1. Create a new project on [Supabase](https://supabase.com)
2. Go to Settings > API to find your project URL and anon key
3. Run the migration file located at `supabase/migrations/20241216120000_marketplace_complete_schema.sql` in your Supabase SQL editor

### 2. Environment Variables

The app requires the following environment variables to be passed during build/run:

```bash
--dart-define=SUPABASE_URL=your_supabase_project_url
--dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app with environment variables:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_anon_key
   ```

## 📱 App Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   └── app_export.dart         # Global exports
├── presentation/               # UI screens and widgets
├── routes/
│   └── app_routes.dart        # Navigation routes
├── theme/
│   └── app_theme.dart         # App theming
├── utils/                     # Supabase services
│   ├── supabase_service.dart  # Core Supabase client
│   ├── auth_service.dart      # Authentication service
│   ├── listing_service.dart   # Listing management
│   ├── category_service.dart  # Category management
│   ├── favorite_service.dart  # Favorites management
│   └── message_service.dart   # Messaging service
└── widgets/                   # Reusable widgets
```

## 🔐 Authentication

The app includes a complete authentication system:

- Email/password registration and login
- User profile management
- Role-based access (admin, seller, buyer)
- Password reset functionality

## 📊 Database Schema

The app uses a comprehensive PostgreSQL schema with:

- **User Profiles**: Extended user information
- **Categories**: Hierarchical product categories
- **Listings**: Marketplace items with images and details
- **Messages & Conversations**: Real-time messaging
- **Favorites**: User saved items
- **Search History**: User search tracking
- **Price Alerts**: Price monitoring

## 🔒 Security

- Row Level Security (RLS) enabled on all tables
- Proper authentication checks
- Secure API access patterns
- Data validation and sanitization

## 🚀 Deployment

### Development
```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

### Production Build
```bash
flutter build apk --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

## 📝 Available Test Data

The migration includes sample data for testing:

- **Users**: Admin, sellers, and buyers with different roles
- **Categories**: Electronics, Furniture, Vehicles, Clothing
- **Listings**: Sample marketplace items with images
- **Messages**: Example conversations
- **Favorites**: Sample user preferences

### Test Credentials
- Admin: `admin@marketplace.com` / `password123`
- Seller: `john.seller@example.com` / `password123`
- Buyer: `mike.buyer@example.com` / `password123`

## 🛡️ Error Handling

The app includes comprehensive error handling:

- Network connectivity checks
- Supabase operation error handling
- User-friendly error messages
- Graceful fallbacks for failed operations

## 📱 Key Features Implementation

### Real-time Messaging
- WebSocket connections via Supabase Realtime
- Instant message delivery
- Read status tracking
- Typing indicators support

### Search & Filtering
- Full-text search across listings
- Category-based filtering
- Price range filtering
- Location-based search
- Search history tracking

### Image Handling
- Supabase Storage integration ready
- Multiple image upload support
- Image optimization and caching
- Fallback image handling

## 🔄 State Management

The app uses Flutter's built-in state management with:
- StatefulWidget for local state
- FutureBuilder for async operations
- StreamBuilder for real-time updates
- Service layer for data management

## 📈 Performance Optimizations

- Efficient database queries with proper indexing
- Image caching with `cached_network_image`
- Pagination for large data sets
- Lazy loading of content
- Optimized Supabase client configuration

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions:
1. Check the existing issues
2. Create a new issue with detailed description
3. Include error logs and reproduction steps

---

**Note**: Remember to keep your Supabase credentials secure and never commit them to version control.