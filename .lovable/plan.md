# Store App — Architecture & Build Plan

A full-stack app for kiryana stores: owners manage shops, products, stock and udhar (dues); customers browse products and track what they owe.

## Stack (fixed for this project)

- Frontend + backend in one TanStack Start app (React 19, Vite, Tailwind v4). Backend logic runs as typed server functions — no separate Express folder needed, same separation of concerns.
- Lovable Cloud (Postgres + Auth + Storage) for database, email/password + Google sign-in, and product image uploads.
- Row-level security so a shop's data is never visible to another shop.

## Database schema

- `profiles` — user id, full name, phone, avatar, default role
- `user_roles` — user_id, role (`owner` | `customer`) in a separate table (security)
- `shops` — owner_id, name, slug, logo, address, phone, currency, settings
- `categories` — shop_id, name, parent_id (subcategories)
- `products` — shop_id, category_id, name, brand, description, price, discount_price, stock, unit (kg/g/l/piece/pack), image_url, sku, is_active, low_stock_threshold
- `shop_customers` — shop_id, user_id (nullable for walk-ins), name, phone, email, address, notes, tags
- `dues` — shop_id, customer_id, amount, paid_total, balance (generated), status (pending/partial/overdue/settled), due_date, notes
- `due_payments` — due_id, amount, paid_at, method, note
- `orders` + `order_items` — shop_id, customer_id, total, status, created_at
- `notifications` — user_id, type, title, body, read_at
- `activity_logs` — shop_id, actor_id, action, entity, metadata

Every table gets explicit grants + RLS: owners access rows for shops they own; customers read active products and only their own dues/orders.

## Routes / pages

Public: `/` landing, `/auth` (sign in / sign up / Google), `/reset-password`, `/browse` catalog, `/product/$id`

Owner (`/_authenticated/owner/...`): `dashboard`, `products`, `products/new`, `products/$id`, `categories`, `customers`, `customers/$id`, `dues`, `dues/$id`, `orders`, `reports`, `settings`

Customer (`/_authenticated/app/...`): `dashboard`, `dues`, `orders`, `profile`

## Server API (typed server functions)

`shops.functions.ts`, `products.functions.ts`, `categories.functions.ts`, `customers.functions.ts`, `dues.functions.ts`, `orders.functions.ts`, `reports.functions.ts` — each validated with Zod, auth-checked server-side, scoped by shop.

## Components

App shell with sidebar + top search, shop switcher, stat cards, charts (recharts), data tables with pagination/sort/filter, product card & grid, product form with image upload, due record form, payment history timeline, status badges, CSV/PDF export, invoice print view, empty/loading/error states, dark mode toggle.

## Implementation steps

1. Enable Lovable Cloud; run migrations for all tables with RLS + grants; seed a demo shop with products so the app isn't empty.
2. Design system in `src/styles.css` — warm grocery-market palette, distinctive typography, light/dark.
3. Auth: email/password + Google, role selection on signup, protected layouts, role-based redirects.
4. Owner: shop setup, product CRUD with image upload, categories, inventory + low-stock alerts.
5. Dues module: records, partial payments, statuses, totals, search/filter, payment history.
6. Customer: catalog with search/filters/sort, product detail, my-dues per shop, order history.
7. Dashboards + charts, reports, CSV/PDF export, notifications, activity log.
8. Polish: responsive passes, transitions, pagination, error handling, SEO metadata per route.

## Notes

Given the scope, I'll build in that order and keep the app usable at each stage — the first pass ships auth, shops, products, catalog, and the full dues module; reports/export/notifications follow.
