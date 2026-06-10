
# Rename app to "MyROF Report"

Replace all user-visible occurrences of "Chiro Patient Ed Suite" with **MyROF Report**.

## Files to update

- `index.html` — `<title>` → `MyROF Report` (plus add a meta description while we're here)
- `src/components/layout/Navbar.tsx` — header brand text
- `src/pages/Index.tsx` — hero `<h1>`, About section heading + body copy, footer copyright

## Questions before I build

1. **Exact branding** — should it render as **"MyROF Report"** or **"MyROF Report App"**? (Your message said "app" but that often reads as a description, not part of the name. I'd recommend "MyROF Report".)
2. **Tagline / about copy** — the About section currently describes a "comprehensive chiropractic suite for patient reports". Keep that wording (just swapping the name), or do you want new copy?
3. **package.json `name` field** (`chiro-report-craft`) — leave it alone (internal only, doesn't affect users) or change it too?

Tell me 1 and 2 and I'll ship it.
