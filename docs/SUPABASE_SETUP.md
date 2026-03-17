# Supabase setup (My Farm)

## 1. Create project

In [Supabase Dashboard](https://supabase.com/dashboard), create a project. Copy **Project URL** and **anon public** key (Settings → API).

## 2. Run SQL

Open **SQL Editor** → New query, paste the full contents of:

`supabase/migrations/001_profiles_user_type.sql`

Run it. This creates:

- Table **`public.profiles`**: `id` (same as `auth.users.id`), `email`, **`user_type`** (`'admin'` | `'user'`).
- Trigger: new sign-ups get a profile with `user_type = 'user'` (unless you set metadata—see below).

## 3. Create users

- **Authentication → Users → Add user** (or enable Email sign-up and register from the app).
- Every user gets a row in `profiles` with `user_type = 'user'`.

## 4. Make an admin

In **Table Editor → profiles**, set `user_type` to `admin` for that user’s row.

Or run:

```sql
update public.profiles
set user_type = 'admin'
where email = 'your-admin@email.com';
```

## 5. Run the Flutter app with keys

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbG...
```

Or put real values in `lib/core/supabase_config.dart` as `defaultValue` (not recommended for production).

## Flow

| `profiles.user_type` | Screen after login   |
|----------------------|----------------------|
| `admin`              | Admin dashboard      |
| `user`               | User dashboard       |

Missing profile row defaults to **user** dashboard; ensure every auth user has a profile (migration backfill + trigger handles this).
