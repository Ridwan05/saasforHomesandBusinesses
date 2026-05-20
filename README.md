# SaaS for Homes and Businesses

Static React dashboard for managing DREEF SaaS for Homes and Businesses pipeline projects, team members, issues, and deployment sites.

## Local Run

First, create your local Supabase config (gitignored — never commit real keys):

```powershell
Copy-Item public\config.example.js public\config.js
# Edit public\config.js with your SUPABASE_URL and SUPABASE_ANON_KEY
# OR run the helper script:
.\connect-supabase.ps1 -SupabaseUrl "https://<ref>.supabase.co" -AnonKey "<anon-key>"
```

Then start the dev server:

```powershell
.\start.ps1
```

Open the URL printed in the terminal, usually `http://localhost:3000/`.

## Supabase

1. Run `supabase-setup-img.sql` in Supabase Dashboard > SQL Editor.
2. For Vercel, add these project environment variables:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. The Vercel build writes these into `dist/config.js`.

## Vercel

Use these settings:

- Framework Preset: `Other`
- Build Command: `npm run build`
- Output Directory: `dist`
- Install Command: `npm install`
