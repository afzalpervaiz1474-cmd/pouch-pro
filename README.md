# Shop Keeper Buddy

Store App Prompt

Build a professional, modern, full-stack web app called “Store App” for kiryana stores, market shops, and small retail businesses. The app must be production-ready, scalable, and easy to use on mobile and desktop. Use a clean separation between frontend and backend, connect both through secure APIs, and store all data in a database.

Core purpose

Let shop owners manage products, prices, stock, customers, and due/advance records.

Let customers browse products, search items, view prices, and see their own due history.

Support multiple shop owners and multiple customers in one system.

Keep each shop’s data private and properly separated.

User roles

Owner / Shopkeeper

Can sign up, sign in, and manage one or more shops.

Can add, edit, delete, and search products.

Can set product prices, stock, discounts, and descriptions.

Can manage customers and their due/advance records.

Can view reports, sales, inventory, and analytics.

Can update store settings, branding, and profile.

Customer

Can sign up, sign in, and browse products.

Can search products by name, category, or price.

Can view product details but cannot edit prices or stock.

Can see their own purchase history and due records.

Can view which shops they owe money to and how much.

Authentication

Email and password sign up/sign in.

Continue with Google sign-in.

Password reset and account verification.

Role-based access control.

Secure sessions and protected routes.

Product management

Each product should support:

Product name.

Category.

Brand.

Description.

Price.

Discount price.

Stock quantity.

Unit type like kg, gram, liter, piece, pack.

Product image.

SKU or barcode optional.

Active or inactive status.

Low stock alert.

Search, filter, and sort.

Customer-facing catalog

Beautiful product cards with image, name, short description, and price.

Search bar.

Category filters.

Sort by price, newest, and popularity.

Product detail page.

Clean, simple, and readable UI.

Prices must be read-only for customers.

Due / advance / udhar module

Create a separate due management section with its own page.

Owner side:

Add a due record with customer name, phone number, email, address, shop name, and due amount.

Save date, notes, partial payments, total paid, and remaining balance.

Mark a record as pending, partially paid, overdue, or settled.

Search and filter dues by customer, shop, amount, or date.

Show total number of people who owe money and total outstanding balance.

Keep a full payment history for every due record.

Customer side:

Show all shops where the customer has pending dues.

Show total due amount per shop.

Show payment history and settlement status.

Multi-shop support

One owner can manage multiple shops.

One customer can be linked to multiple shops.

Each shop must have its own products, customers, dues, reports, and settings.

Prevent one shop from accessing another shop’s private data.

Dashboard

Create separate dashboards for owner and customer.

Owner dashboard should include:

Sales summary.

Total products.

Low stock alerts.

Total customers.

Total due amount.

Recent activity.

Graphs and charts.

Quick action buttons.

Customer dashboard should include:

Browse products.

Search products.

View due status.

View profile and history.

Simple and easy navigation.

UI / UX requirements

Modern, premium, and professional design.

Mobile-first responsive layout.

Sidebar navigation.

Top search bar.

Smooth transitions and animations.

Light and dark mode.

Clean typography and spacing.

Dashboard cards and data tables.

Very polished grocery-store app feel.

Extra features to include

Inventory management.

Sales and order history.

Receipt or invoice printing.

Notifications for low stock and pending dues.

Export data to CSV or PDF.

Audit log of owner actions.

Pagination for long lists.

Loading states and error handling.

Image upload support.

Activity timeline.

Multiple categories and subcategories.

Favorites or wishlist optional.

Customer notes and tags.

Secure validation on frontend and backend.

Search across products, customers, and dues.

Mobile-friendly checkout or order flow if needed.

Multi-language-ready structure.

Recommended tech stack

Frontend: Next.js or React.

Backend: Node.js with Express or NestJS, or Python FastAPI.

Database: PostgreSQL or MongoDB.

Authentication: Google OAuth plus email/password.

Storage: Cloud or local file storage.

API: REST or GraphQL.

Styling: Tailwind CSS or another modern UI system.

Database entities

Create models for:

Users.

Roles.

Shops.

Products.

Categories.

Customers.

Due records.

Due payments.

Orders or sales.

Notifications.

Activity logs.

Settings.

Product images.

Build quality requirements

Clean code structure.

Separate frontend and backend folders.

Reusable components.

Secure API validation.

Proper authentication and authorization.

Fast performance.

Scalable architecture.

Production-ready code.

Final instruction

Before writing code, first generate:

complete app architecture,

folder structure,

database schema,

API routes,

page list,

component list,

and step-by-step implementation plan.

Then build the full Store App carefully with professional UI and connected backend.

This project was built with [Lovable](https://lovable.dev).

**Live app**: https://pouch-pro.lovable.app

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/e2203e2c-6403-46e8-8b1c-1c9a6a52a874).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
