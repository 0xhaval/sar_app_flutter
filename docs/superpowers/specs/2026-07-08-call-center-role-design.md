# Call Center Role — Design

Date: 2026-07-08
Scope: `real-estate-app` (Next.js backend) + `sar_app` (Flutter mobile app)

## Goal

Add a new `CALL_CENTER` role. A user with this role can log in to the mobile
app and has a restricted permission set: **create new customers** and **view
their own customers** — nothing else.

## Context

The backend already has a clean RBAC system:

- `Role` enum in `prisma/schema.prisma`.
- `MATRIX` in `src/lib/rbac.ts` maps `role → resource → Action[]`.
- `ROLE_LABELS` (rbac.ts) + `ROLE_VALUES` (validations.ts) drive the admin
  users new/edit checkboxes automatically.
- Mobile access is enforced per-endpoint via `requireMobilePermission(ctx,
  resource, action)` in `src/lib/mobile-guard.ts`.
- **Mobile login is not role-gated** — any valid user gets a token; access is
  controlled purely by per-endpoint permission checks.
- The mobile customers endpoint currently has only `GET` (read); there is no
  create-customer endpoint yet. Its GET filters `assignedUserId = ctx.user.id`
  ("my customers").

## Backend changes (`real-estate-app`)

1. **Enum** — `prisma/schema.prisma`: add `CALL_CENTER` to `Role`. New migration
   `prisma/migrations/<timestamp>_add_call_center_role/migration.sql` with a
   MySQL `ALTER TABLE User MODIFY role ENUM(...)` including the new value,
   matching existing migration style. Applied via `prisma migrate deploy`
   (already in the `start` script).

2. **Permissions** — `src/lib/rbac.ts`:
   - New action set `RC = ["read", "create"]`.
   - `MATRIX.CALL_CENTER = { customers: RC }` — create + view own customers
     only. No update/delete, no dashboard/apartments/complexes.
   - `ROLE_LABELS.CALL_CENTER = "Call Center"`.

3. **Role picker** — `src/lib/validations.ts`: add `Role.CALL_CENTER` to
   `ROLE_VALUES`. Admin users new/edit pages pick it up automatically.

4. **Create-customer endpoint** — add `POST` to
   `src/app/api/mobile/customers/route.ts`:
   - `requireMobileUser` → `requireMobilePermission(ctx, "customers", "create")`.
   - Validate body with existing `customerSchema`.
   - Normalize empty strings to null (mirror web `POST /api/customers`).
   - Force `assignedUserId: ctx.user.id` so the creator sees it in their list.
   - `logActivity` CREATE Customer.
   - Return created customer, 201.

5. **Return roles on login** — `src/app/api/mobile/auth/login/route.ts`: include
   `roles` (coerced from `user.roles` JSON, fallback `[user.role]`) in the
   response `user` object so the app can render role-aware UI. `/api/mobile/me`
   already returns roles.

## Flutter changes (`sar_app`)

6. **Store roles** — `lib/services/auth_service.dart`: persist `roles` from the
   login response (JSON-encoded in prefs). Add `getRoles()` and `isCallCenter()`
   helpers.

7. **Role-aware navigation** — `lib/app_shell.dart`: for a Call Center user show
   a reduced bottom nav (**Customers + Profile** only), landing on Customers.
   Other roles keep the existing full 6-tab nav. This avoids 403s on
   dashboard/apartments/leaves/attendance screens they can't access.

8. **Add-customer screen** — `lib/screens/customers.dart`: a "+" action (FAB or
   header button) opens a form (name required; phone, email, customer type,
   budget optional) that `POST`s to `/api/mobile/customers` and refreshes the
   list on success. Uses a toast for feedback, consistent with existing screens.

## Out of scope (YAGNI)

- No update/delete of customers from mobile for Call Center.
- No dashboard/apartment/complex access for Call Center.
- No change to who *can* log in — login stays open; access is permission-gated.

## Verification

- Backend: create a `CALL_CENTER` user, log in via mobile, confirm `POST
  /api/mobile/customers` (201) and `GET` returns the created customer; confirm a
  denied resource (e.g. dashboard) returns 403.
- Flutter: log in as Call Center → lands on Customers with 2-tab nav → add a
  customer → it appears in the list. A normal role still sees the full nav.
