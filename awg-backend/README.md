# AWG Backend API

Backend API for AWG Wallpaper App built with Node.js, Express, TypeScript, and MongoDB.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

3. Set up MongoDB (local or Atlas)

4. Configure Cloudinary for image uploads

5. Start development server:
```bash
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/admin/login` - Admin login
- `POST /api/auth/firebase/verify` - Verify Firebase user
- `GET /api/auth/me` - Get current user profile
- `POST /api/auth/setup-admin` - Create initial admin

### Wallpapers
- `GET /api/wallpapers` - List wallpapers (paginated)
- `GET /api/wallpapers/search?q=` - Search wallpapers
- `GET /api/wallpapers/:id` - Get single wallpaper
- `POST /api/wallpapers` - Create wallpaper (admin)
- `PUT /api/wallpapers/:id` - Update wallpaper (admin)
- `DELETE /api/wallpapers/:id` - Delete wallpaper (admin)

### Categories
- `GET /api/categories` - List categories
- `POST /api/categories` - Create category (admin)
- `PUT /api/categories/:id` - Update category (admin)
- `DELETE /api/categories/:id` - Delete category (admin)

### Users
- `GET /api/users` - List users (admin)
- `GET /api/users/:id` - Get user (admin)
- `PUT /api/users/:id` - Update user (admin)
- `DELETE /api/users/:id` - Delete user (admin)
- `GET /api/users/stats/overview` - User statistics (admin)

### Subscriptions
- `POST /api/subscriptions/verify` - Verify purchase
- `GET /api/subscriptions/status` - Get subscription status
- `POST /api/subscriptions/restore` - Restore purchases
