# SAR Employee PWA — Design Spec

**Date:** 2026-10-21
**Status:** Approved design, pending implementation plan
**Goal:** A new standalone PWA that replicates the Flutter `sar_app` (v2.1.4+8) 100% — same screens, behavior, Arabic labels, colors, and API contract.

## Decisions (user-approved)

| Decision | Choice |
|---|---|
| Approach | Full rewrite as a web-native app (not Flutter Web) |
| Stack | Next.js 15 (App Router) + TypeScript + Tailwind CSS 4 + SWR, hand-built UI (no component library) |
| Hosting | Separate standalone project `sar_pwa` (sibling to `sar_app`); zero changes to the production backend |
| API access | Same-origin proxy: the PWA's Next.js server forwards `/api/*` to `https://sar-iq.com` (no CORS work) |
| PWA depth | Installable + basic offline shell (branded Arabic offline fallback page); online-required like the Flutter app |
| Language | Arabic only, full RTL (`dir="rtl"`), Tajawal font via `next/font` |

## 1. Architecture

```
Browser (PWA)  ──same-origin──▶  sar_pwa Next.js server  ──HTTPS──▶  https://sar-iq.com/api/mobile/*
   │                                    │
   localStorage (token + profile)       /api/[...path] catch-all proxy
```

- **Proxy** (`app/api/[...path]/route.ts`): forwards method, query string, body (including multipart streams), and the `Authorization` header to `API_BASE_URL` (env, default `https://sar-iq.com`). Returns the upstream response verbatim. Never caches. No auth logic server-side — the proxy is stateless.
- **Client API layer** (`lib/api.ts`) — direct port of `api_service.dart`:
  - `getJson / postJson / patchJson / deleteJson / uploadFile` helpers.
  - Response envelope: on 2xx, if body is an object with a `data` key, return `body.data`; else return body.
  - `ApiException { message, statusCode }`.
  - 401 on an authenticated request → fire `onSessionExpired` once (guard flag + token check against concurrent 401s): clear session, toast «انتهت الجلسة، يرجى تسجيل الدخول من جديد», redirect to `/login`. 401/403 otherwise → `body.error` or «غير مصرح». Any other non-2xx → `body.error` or «حدث خطأ في الاتصال».
- **Auth** (`lib/auth.ts`) — port of `AuthService`, localStorage keys identical: `auth_token`, `user_id`, `user_email`, `full_name`, `employee_id`, `user_roles` (JSON array). Login lowercases+trims email. Logout clears locally **first**, then best-effort `POST /api/mobile/auth/logout` (errors swallowed). `deleteAccount()` = `DELETE /api/mobile/me` + clear. `getRoles()` reads cache, falls back to `GET /api/mobile/me`.
- **Roles** (`lib/roles.ts`): `kAddCustomerRoles = {'RECEPTION'}`, case-insensitive; `extractRoles` prefers `user.roles` list, falls back to legacy `user.role` string. The only client-side gate is the «إضافة عميل» button; server RBAC remains authoritative.
- **Route protection**: authenticated pages live under an `(shell)` layout with a client auth guard — no token → replace to `/login`. Login page redirects to dashboard if already logged in.
- **Data fetching**: SWR per screen, `revalidateOnFocus: false` to match Flutter's load-once behavior; Customers list additionally exposes manual refresh (pull-to-refresh gesture on touch + refresh button).

## 2. Project structure

```
sar_pwa/
  app/
    layout.tsx                 # html dir=rtl lang=ar, Tajawal, theme, toaster, manifest link
    login/page.tsx
    (shell)/layout.tsx         # auth guard + BottomNav + fade-through tab transitions
      dashboard/page.tsx
      leaves/page.tsx
      attendance/page.tsx
      apartments/page.tsx
      customers/page.tsx
      customers/[id]/page.tsx
      customers/new/page.tsx
      profile/page.tsx
    api/[...path]/route.ts     # proxy
    offline/page.tsx           # branded Arabic offline fallback
  components/
    bottom-nav.tsx  animated-bottom-sheet.tsx  calendar-view.tsx
    staggered-column.tsx  status-chip.tsx  gradient-header.tsx
    fields/ (text, dropdown, date-picker, textarea, switch, filter-chip)
    toast.tsx
  lib/
    api.ts  auth.ts  roles.ts  format.ts  enums.ts  types.ts
  public/manifest.json, icons/ (from sar_app assets/icon/app_icon.png), logo
  sw (Serwist service worker)
```

## 3. Theme (replicate exactly)

- Primary `#284A63`; scaffold/surface `#F9FAFB`; cards white, radius 10, subtle elevation-2 shadow.
- Inputs: radius 10, fill `#FAFAFA`, border `#E5E7EB`, focused border `#284A63` 1.5px, padding 14px.
- Font: Tajawal (400/500/700). Dialogs radius 20. Secondary text `#353535`.
- Status palette (shared): green `#16A34A`/`#22C55E`/bg `#DCFCE7`/text `#15803D`; red `#DC2626`/`#EF4444`/bg `#FEE2E2`; orange `#EA580C`/bg `#FFF7ED`/text `#C2410C`; yellow `#EAB308`/bg `#FEF9C3`/text `#A16207`; blue `#3B82F6`/`#2563EB`/bg `#DBEAFE`/text `#1E40AF`; gray `#D9DAD9`/`#6B7280`.
- Date/time pickers: custom components themed navy (`#284A63` header, selected-day navy) — native pickers don't match the Flutter look.

## 4. Formatting (`lib/format.ts`, Arabic locale)

- API dates: `yyyy-MM-dd`. Leave cards: `d MMM`. Attendance times: `hh:mm a`; live clock `hh:mm`; header date `EEEE، d MMMM yyyy`; history rows `EEEE، d MMM`; request time `hh:mm a · d MMM`. Calendar month `MMMM yyyy`. Customer timestamps `yyyy-MM-dd HH:mm`. Money: thousands-grouped + suffix «د.ع».
- Weekday headers (calendar): الأحد، الإثنين، الثلاثاء، الأربعاء، الخميس، الجمعة، السبت.

## 5. App shell

- 6 tabs, custom bottom nav: height 64, white, top border `#E5E7EB`; active `#284A63` / inactive `#353535`; active item scale 1.0 vs 0.95, icon scale 1.15, outline↔filled icon swap, label weight 600 when active. Fade-through transition (~300ms) between tabs.
- Tab order: الرئيسية (home) · الإجازات (description) · الحضور (calendar_today) · الشقق (apartment) · العملاء (people) · الملف (person) — Material Symbols outline/filled pairs.
- Tabs are client-side route segments; tab state preserved per Flutter behavior (screens keep loaded data when switching).

## 6. Shared components

- **AnimatedBottomSheet**: modal sheet, drag-snap points 0.9 initial / 0.4 min / 0.95 max, white, top radius 20, 40×4 drag handle, close button (tooltip «إغلاق»), optional title (bold 20) + subtitle (14, `#353535`); children staggered fade+slide-up (interval index×0.08, total 400ms + 50ms/child).
- **CalendarView**: month grid per inventory; status colors present `#22C55E`, half-day `#EAB308`, leave `#3B82F6`, absent `#EF4444`, empty `#E5E7EB`/`#F3F4F6`; today = navy 2px border; legend «حاضر / نصف يوم / إجازة / غائب»; RTL chevrons (left = next month); fade on month change; dates matched by `yyyy-MM-dd`.
- **StaggeredColumn**: children fade + 16px slide-up on mount, interval index×0.1 (cap 0.6), ease-out-cubic.
- **StatusChip**: pill with bg/text per status maps below.
- **Toasts**: bottom toast matching Fluttertoast look.

## 7. Screens (1:1 parity)

### Login
Centered column: 80×80 navy logo tile (radius 20, white-tinted logo), «SAR Employee» 28px bold navy, «تسجيل الدخول إلى حسابك»; red error box (`#FEE2E2`, `#DC2626`); email field «البريد الإلكتروني» (email keyboard), password «كلمة المرور» with visibility toggle; 52px navy button «تسجيل الدخول» with spinner. Empty → «يرجى إدخال اسم المستخدم وكلمة المرور\nPlease enter your email and password»; 401/403 → «البريد الإلكتروني أو كلمة المرور غير صحيحة\nWrong email or password»; network/server errors bilingual. Enter in password submits. Success → replace to dashboard.

### Dashboard — `GET /api/mobile/dashboard`
Gradient header `#284A63→#3B6E71`: logo, «مرحباً بعودتك،», full name (28 bold), «رقم الموظف: {employee_id}». StaggeredColumn: 2-col stat grid — «رصيد الإجازات» `{n} يوم` navy; «ساعات هذا الشهر» `{n} ساعة` `#16A34A`; «الطلبات المعلقة» `{n}` `#EA580C`; «معدل الحضور» `%{n}` `#9333EA` — then «النشاطات الأخيرة» card (`recent_activities[{action,type}]`, checkin→login icon else description icon; empty → «لا توجد نشاطات حديثة»). Load once; errors fail silent.

### Leaves — `GET /leaves`, `GET /leaves/balance`, `GET /leaves/types` (parallel); `POST /leaves`
Navy header, «إدارة الإجازات», white «تقديم طلب» button → sheet. Balance cards with progress bars `{remaining}/{total} يوم`. «سجل الإجازات» list (empty → «لا توجد إجازات»): type label, range `d MMM - d MMM`, `({n} أيام/يوم)`, optional description, status chip.
Sheet «تقديم طلب إجازة» / «املأ النموذج أدناه لتقديم طلب الإجازة»: dropdown «نوع الإجازة» (hint «اختر النوع»), «من تاريخ» + «إلى تاريخ» pickers («اختر التاريخ»), textarea «السبب» («أدخل السبب...»), navy «تقديم الطلب». Required: type + both dates. Body `{leave_type, from_date, to_date, reason}`. Success toast «تم تقديم طلب الإجازة بنجاح!» + reload; failure «خطأ: ...».
Type labels: Annual=إجازة سنوية, Sick=إجازة مرضية, Personal=إجازة شخصية, Maternity=إجازة أمومة, Paternity=إجازة أبوة, Unpaid=إجازة بدون راتب (unknown → raw). Status: Approved→«موافق عليها» (check_circle, `#16A34A`/`#DCFCE7`/`#15803D`), Rejected→«مرفوضة» (cancel, `#DC2626`/`#FEE2E2`), else «قيد الانتظار» (access_time, `#EA580C`/`#FFF7ED`/`#C2410C`).

### Attendance — `GET /attendance?month&year`, `GET /attendance/today`, `GET /attendance/checkin-requests` (parallel, requests failure→empty); `POST /attendance/checkin|checkout|requests`
Gradient header `#3B6E71→#284A63`, «الحضور والانصراف», live clock (hh:mm 48px) + date. State from today's logs (`IN` sets checked-in+time, `OUT` clears). Big 96px button: «تسجيل الحضور» green `#22C55E` / «تسجيل الانصراف» red `#EF4444`, scale+fade swap; outlined «طلب تسوية» beside it. Line «وقت الحضور: {time | لم يتم التسجيل}».
GPS flow: toast «جاري تحديد الموقع...» → browser Geolocation (high accuracy, 15s timeout) → POST `{latitude, longitude, requestId?}` → toast «تم تسجيل الحضور في {time}» / «تم تسجيل الانصراف في {time}». Double-submit guard. Geo errors: disabled → «يرجى تفعيل خدمة الموقع لتسجيل الحضور»; denied → «تم رفض إذن الوصول إلى الموقع»; denied-forever equivalent → «إذن الموقع مرفوض دائماً، يرجى تفعيله من إعدادات التطبيق». API error containing `DoesNotExist` → «لا يوجد سجل موظف مرتبط بحسابك», else «خطأ: ...».
Admin request banners (when not checked in): orange banner (`#FFF7ED` bg, `#FB923C` border, notifications icon), «تنبيه: مطلوب تسجيل الحضور», «طلب من: {requestedBy}» or «طلب تسجيل حضور من الإدارة», optional «الموقع: {location}», «الوقت: {hh:mm a · d MMM}», note box, button «تأكيد تسجيل الحضور الآن» (`#EA580C`) → check-in with `requestId`.
Tabs «عرض التقويم» (CalendarView) / «السجل» (rows: `EEEE، d MMM`, «{hours} ساعة عمل» or «لا يوجد حضور», status chip). Adjustment sheet «طلب تسوية الحضور» / «قدم طلب لتسوية سجل الحضور الخاص بك»: dropdown «نوع الطلب» [نسيان تسجيل الحضور، نسيان تسجيل الانصراف، وقت خاطئ، خطأ في النظام], date «التاريخ», textarea («اشرح سبب طلبك...»); requires date+reason; body reason = `{type}: {reason}`; success «تم تقديم طلب تسوية الحضور بنجاح!».
Status: Present→«حاضر» (`#DCFCE7`/`#15803D`), Half Day→«نصف يوم» (`#FEF9C3`/`#A16207`), On Leave→«إجازة» (`#D9DAD9`/`#284A63`), Absent/default→«غائب» (`#FEE2E2`/`#DC2626`).

### Customers — `GET /customers?search`, `GET /customers/{id}`, `POST /customers`, `POST /customers/{id}/status`
List: gradient header `#284A63→#0D9488`, «العملاء», «عملاء مُسنَدون إليك», «إضافة عميل» button **only for RECEPTION**. Search «ابحث بالاسم، البريد، أو الهاتف» — client-side filter on name/email/phone (lowercased), matching Flutter behavior (typing filters locally; reload supports `?search=`). Pull-to-refresh. Empty → «لا يوجد عملاء مُسنَدون إليك»; error → «خطأ: {error}».
Card: avatar (first char), name, type chip (individual=فرد, company=شركة), chevron → detail, phone/email rows, status chip button («تحديد الحالة» if unset; flag+edit icons) → status sheet, mini-stats «{n} يمتلك» (green) / «{n} يستأجر» (blue).
Status sheet «تغيير الحالة»: radio of «مهتم» `#16A34A` / «غير مهتم» `#DC2626` / «قام بالشراء» `#2563EB` (default color `#6B7280`), optional «ملاحظة (اختياري)» max 500, «حفظ» disabled until chosen. Body `{status, description?}`. Success «تم تحديث الحالة» + refresh; failure «فشل تحديث الحالة: {e}».
Detail page «تفاصيل العميل»: gradient header card (avatar, name, type, status chip); sections «معلومات الاتصال» (الهاتف/البريد), «معلومات عامة» (نوع العميل، المصدر، التصنيف، الميزانية `{money} د.ع`، تاريخ الإضافة `yyyy-MM-dd HH:mm`), «العقارات المملوكة (n)» / «العقارات المستأجرة (n)» (tile: number • code, compound - city, status chip, owner→`cashPrice` «{money} د.ع سعر», tenant→`monthlyRent` «{money} د.ع/شهر»), «عناوين مفضلة» (join country/city/district/streetAddress with «، », label territory or «عنوان»), «تغيير الحالة» button, «سجل الحالات» (status + timestamp + note), green «اتصل بـ {phone}» (toast «الهاتف: {phone}» — same as Flutter today).
New-customer page «إضافة عميل»: «اسم العميل *» (required → «اسم العميل مطلوب»), «الهاتف», «البريد الإلكتروني» (if non-empty must contain `@` → «بريد إلكتروني غير صالح»), dropdown «نوع العميل» (فرد/شركة), «الميزانية» (number), «حفظ». Omit empty optional keys. Success «تمت إضافة العميل بنجاح» + back + reload; failure «فشل إضافة العميل: {e}».

### Apartments — `GET /apartments`, `GET /apartments/compounds`, `POST /apartments`, `PATCH /apartments/{id}`, `POST /upload`
Gradient header `#16A34A→#0D9488`, «إدارة الشقق», white «إضافة شقة». Stats grid: «إجمالي الشقق», «شقق متاحة», «شقق مؤجرة», «الإيرادات الشهرية» `{money} د.ع`. «شققي ({n})»; empty → «لا توجد شقق».
Card: «شقة {number} ({code})», location (compound، district، city), status chip, optional notes, tiles «د.ع/شهر» (green) / «غرف» / «حمامات» / «م²», outlined «تعديل عدد الوحدات» → dialog («الشقة: {number}», field «عدد الوحدات المتاحة», int ≥ 0 else toast «أدخل رقمًا صحيحًا», حفظ/إلغاء, success «تم حفظ التعديل» + reload).
Card status map (normalized lowercase/underscore): vacant=«متاحة» (`#DCFCE7`/`#15803D`), occupied=«مؤجرة» (`#D9DAD9`/`#284A63`), reserved=«محجوزة» (`#DBEAFE`/`#1E40AF`), sold=«مباعة» (`#FEE2E2`/`#B91C1C`), under_maintenance=«صيانة» (`#FFF7ED`/`#C2410C`). (Form deliberately uses «مشغولة» for Occupied — keep the discrepancy, it matches the Flutter app.)
Add sheet «إضافة شقة جديدة» / «املأ البيانات لإضافة شقة جديدة» — full field list and section order per the Flutter form:
- Required: «المجمع السكني *» (compounds dropdown; errors «خطأ: {e}» / «لا توجد مجمعات»), «المبنى (Block) *» (dependent), «رقم الشقة *». Submit guard toast: «يرجى ملء المجمع، المبنى، ورقم الشقة».
- «معلومات المبنى»: رقم المبنى، رقم الطابق، عدد الطوابق، الوحدات المتاحة.
- «مواصفات الوحدة»: نوع الشقة (Studio/Apartment/Duplex/Penthouse/Loft/Townhouse/Villa, English as-is), غرف النوم، الحمامات، غرف المعيشة، المساحة (م²)، المساحة الصافية (م²); switches بلكونة/غرفة خادمة; dropdowns حالة التأثيث (Unfurnished=بدون أثاث, Semi-Furnished=مفروشة جزئياً, Fully Furnished=مفروشة بالكامل), الإطلالة (City=مدينة, Garden=حديقة, Pool=مسبح, Sea=بحر, Mountain=جبل, Street=شارع, Park=حديقة عامة), الحالة الإنشائية (Excellent=ممتازة, Good=جيدة, Fair=مقبولة, Needs Repair=تحتاج إصلاح, Under Renovation=قيد التجديد), حالة البناء (Under Construction=قيد الإنشاء, Ready to move in=جاهزة للسكن) + conditional «تاريخ انتهاء الإنشاء».
- «المرافق» (20 FilterChips, green selected): مصعد، أمن، مسبح، حديقة خاصة، ألعاب أطفال، موقف مغطى، تكييف مركزي، حيوانات أليفة، هاتف أرضي، أجهزة مطبخ، عداد ماء، عداد كهرباء، عداد غاز، مسجد، مدرسة، نادي ترفيهي، ملاعب، نادي رياضي وصحي، وحدة صحية، منزل ذكي. (19 map to `has*` keys; حيوانات أليفة maps to `petsAllowed`.)
- «الحالة والإيجار»: الحالة (Vacant=شاغرة default, Occupied=مشغولة, Reserved=محجوزة, Under Maintenance=تحت الصيانة, Not Available=غير متاحة), نوع العرض (Rent=إيجار, Sale=بيع), نوع الإشغال (Owner=مالك, Tenant=مستأجر, None=بدون), الإيجار الشهري، رسوم الصيانة، الضمان، الرصيد المستحق، dates بداية الإيجار/نهاية الإيجار/تاريخ الانتقال.
- «الدفع»: طريقة الدفع (Cash=نقدي, Both=كلاهما); switches من المالك/عبر وسيط; conditional «السعر النقدي» (Cash or Both); if Both: الدفعة الأولى، دفعة الاستلام، قسط شهري، قسط ربع سنوي، قسط نصف سنوي، قسط سنوي، تكرار الدفع (Monthly=شهري, Quarterly=ربع سنوي, Semi-Annual=نصف سنوي, Annual=سنوي)، المدة (سنوات)، السعر الإجمالي.
- Other: تاريخ آخر فحص، ملاحظات، رابط الخطة (Floor Plan URL).
- «صور الشقة»: `<input type=file multiple accept=image/*>`, 80×80 thumbnails with red remove badge, add tile «إضافة صور». Each image → `POST /api/mobile/upload` (multipart `file`) → `documents:[{documentName:'Photo', documentType:'Photo', file:url}]`.
- Submit «إضافة الشقة» (green): POST full body — all keys incl. 22 boolean flags (19 amenity `has*` keys + `petsAllowed` + `hasBalcony` + `hasMaidRoom`); `installmentFrequency` only when Both; `constructionEndDate` only when Under Construction. Success «تم إضافة الشقة بنجاح!» + reload.
No client role gate (server RBAC authoritative). No pull-to-refresh.

### Profile — `GET /me`; `DELETE /me`; `POST /auth/logout`
Gradient header `#284A63→#3B6E71`, «الملف الشخصي». Profile card overlapping header (−64): initials avatar (2 chars), name (`employee.fullName`||`user.name`), designation (`employee.position`), employeeId chip. Info card, non-empty rows only: البريد الإلكتروني، الهاتف، القسم، المسمى الوظيفي، تاريخ الانضمام (hireDate before `T`)، الشركة. Links card: «سياسة الخصوصية» → https://sar-iq.com/privacy, «شروط الاستخدام» → https://sar-iq.com/terms, «التواصل مع الدعم» → mailto:support@sar-realestate.com (new tab; failure «تعذر فتح الرابط»). Outlined red «تسجيل الخروج» → logout → login. Red text «حذف الحساب» → dialog requiring typed «حذف» to enable «حذف نهائي»; blocking spinner → delete → login + «تم حذف الحساب بنجاح»; failure «فشل حذف الحساب: {e}»; footer «حذف الحساب عملية دائمة ولا يمكن التراجع عنها».

## 8. API endpoint contract (consolidated)

| Method | Path | Body / params |
|---|---|---|
| POST | /api/mobile/auth/login | `{email, password}` |
| POST | /api/mobile/auth/logout | — |
| GET / DELETE | /api/mobile/me | — |
| GET | /api/mobile/dashboard | — |
| GET | /api/mobile/leaves, /leaves/balance, /leaves/types | — |
| POST | /api/mobile/leaves | `{leave_type, from_date, to_date, reason}` |
| GET | /api/mobile/attendance | `?month&year` |
| GET | /api/mobile/attendance/today, /attendance/checkin-requests | — |
| POST | /api/mobile/attendance/checkin | `{latitude, longitude, requestId?}` |
| POST | /api/mobile/attendance/checkout | `{latitude, longitude}` |
| POST | /api/mobile/attendance/requests | `{reason, attendance_date}` |
| GET | /api/mobile/customers | `?search` |
| GET | /api/mobile/customers/{id} | — |
| POST | /api/mobile/customers | `{customerName, phone?, email?, customerType?, budget?}` |
| POST | /api/mobile/customers/{id}/status | `{status, description?}` |
| GET | /api/mobile/apartments, /apartments/compounds | — |
| POST | /api/mobile/apartments | full apartment body |
| PATCH | /api/mobile/apartments/{id} | `{availableUnits}` |
| POST | /api/mobile/upload | multipart `file` → `{url}` |

## 9. PWA layer

- `manifest.json`: name «SAR Employee», short_name «SAR», `dir: rtl`, `lang: ar`, `display: standalone`, theme `#284A63`, background `#F9FAFB`, icons generated from `sar_app/assets/icon/app_icon.png` (192/512 + maskable).
- Service worker via **Serwist**: precache app shell + static assets; network-first for navigations with `/offline` fallback; **never cache `/api/*`**.
- Installability on Android/iOS/desktop; viewport + apple-touch-icon meta for iOS.

## 10. Error handling

Direct port of Flutter behavior: `ApiException.message` surfaced in toasts with the exact Arabic strings above; global 401 session-expiry (once); login errors bilingual; attendance checkin-requests failure degrades to empty list; dashboard errors fail silent.

## 11. Testing

- **Vitest** unit tests for `lib/`: envelope unwrapping, error mapping, 401 hook single-fire, `extractRoles`/`canAddCustomer`, enum label maps, date/money formatters (mirrors `sar_app/test`).
- **Playwright** smoke tests against a mocked API: login success/failure, each tab renders, leave request submit, customer status change, apartment units edit, logout.
- Manual checks: install prompt, offline fallback page, geolocation prompt flow.

## 12. Out of scope

- Any backend change. Offline data/queueing. Push notifications. Non-Arabic locales. New features beyond the Flutter app (including fixing its quirks — e.g., search-typing filters client-side only; «اتصل بـ» toasts instead of dialing; occupied label discrepancy «مؤجرة» vs «مشغولة»).
