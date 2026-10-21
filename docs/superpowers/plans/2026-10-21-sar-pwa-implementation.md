# SAR Employee PWA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the `sar_pwa` Next.js PWA so it replicates the Flutter `sar_app` (v2.1.4+8) 100% — all 8 authenticated pages, unit tests, Playwright smoke tests, and a verified production build.

**Architecture:** Client-rendered pages under `app/(shell)/` fetch through the existing same-origin proxy (`app/api/[...path]/route.ts` → `https://sar-iq.com`). Each page is a direct port of its Flutter screen in `sar_app/lib/screens/*.dart` — the Flutter file is the parity oracle for layout, copy, and behavior. All shared infrastructure (lib layer, components, theme CSS, login, shell, PWA assets) already exists and typechecks.

**Tech Stack:** Next.js 16 (App Router) + TypeScript + Tailwind CSS 4, Material Symbols icons, Vitest (lib unit tests), Playwright (smoke tests with mocked API).

## Global Constraints

- Work in `/mnt/data/relocated/Flutter/sar_pwa` (git repo, baseline = "Initial commit from Create Next App" + uncommitted scaffold).
- Parity oracle: `/mnt/data/relocated/Flutter/sar_app/lib/screens/<name>.dart` — port every element, copy string, color, and conditional 1:1. Arabic strings must be byte-identical to the Flutter source (copy-paste, never retype).
- Spec: `/mnt/data/relocated/Flutter/sar_app/docs/superpowers/specs/2026-10-21-sar-pwa-design.md`. Keep known quirks (client-side search filter, «اتصل بـ» toast instead of dialing, «مؤجرة» card label vs «مشغولة» form label).
- Primary `#284A63`; use existing CSS utilities `.card`, `.input`, `.stagger-item`; Tailwind theme colors `primary`, `primary-alt`, `surface`, `ink`, `line`, `field`.
- Existing lib API (do not change signatures): `getJson(path, query?)`, `postJson(path, body?)`, `patchJson(path, body?)`, `deleteJson(path)`, `uploadFile(file): Promise<string>`, `ApiException{message,statusCode}` from `lib/api.ts`; `login/logout/deleteAccount/clearSession/isLoggedIn/getFullName/getEmployeeId/canAddCustomer` from `lib/auth.ts`; enum maps from `lib/enums.ts`; formatters from `lib/format.ts`; `showToast(msg)` from `components/toast.tsx`.
- Existing components (do not change props): `GradientHeader{from,to,children}`, `HeaderLogo{size}`, `StaggeredColumn`, `BottomSheet{open,onClose,title,subtitle}`, `CalendarView{records: {date: Date, hours: number, status: string}[]}`, `DateField{label,value: Date|null,onChange,placeholder}`, `DatePickerModal`, `StatusChip{chip: ChipStyle}`, `TextField/TextArea/Dropdown/SwitchRow/FilterChip` from `components/fields.tsx`, `Spinner/CenteredSpinner`, `MIcon{name,filled,size,className}`.
- Pages are `'use client'` components; load data once on mount (no SWR revalidation-on-focus); loading = `CenteredSpinner`; screen-level data errors fail silent (except customers, which shows `خطأ: {message}`).
- Every money value renders via `money()` + ` د.ع`. Every API date string parses via `parseDate()`.
- Run `npx tsc --noEmit` before every commit; it must pass.
- Commits end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

---

### Task 1: Commit the existing scaffold

The scaffold (proxy, lib, components, login, offline, shell, PWA assets) is complete but uncommitted. Lock in the baseline first.

**Files:** all currently modified/untracked files in `sar_pwa` (`git status`).

- [ ] **Step 1: Typecheck** — Run `cd /mnt/data/relocated/Flutter/sar_pwa && npx tsc --noEmit`. Expected: exit 0.
- [ ] **Step 2: Lint** — Run `npm run lint`. Fix any errors (warnings acceptable only if pre-existing from create-next-app).
- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: scaffold — proxy, lib layer, shared components, login, shell, PWA assets"
```

### Task 2: Vitest setup + lib unit tests

**Files:**
- Create: `vitest.config.ts`, `tests/unit/api.test.ts`, `tests/unit/roles.test.ts`, `tests/unit/enums.test.ts`, `tests/unit/format.test.ts`
- Modify: `package.json` (add `"test": "vitest run"` script)

**Interfaces:** Consumes `lib/*` exports listed in Global Constraints. Produces nothing used later except the `npm test` command.

- [ ] **Step 1: vitest.config.ts**

```ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  test: { environment: 'jsdom' },
  resolve: { alias: { '@': path.resolve(__dirname) } },
});
```

- [ ] **Step 2: Write the tests.** Cover, with exact Arabic strings:
  - `parseBody` (api.test.ts): 2xx object with `data` key → returns `body.data`; 2xx array/no-data-key → returns body as-is; non-2xx with `{error}` → throws `ApiException` with that error; non-2xx without body → «حدث خطأ في الاتصال»; 401 unauthenticated → «غير مصرح»; 403 → `body.error` or «غير مصرح».
  - 401-authenticated single-fire: `setOnSessionExpired(spy)`; two sequential `parseBody(new Response('{}', {status:401}), true)` calls each fire the handler and throw «انتهت الجلسة، يرجى تسجيل الدخول من جديد» — and the shell's guard logic (token check) is what makes it effectively-once; assert the message and that the handler was called. Use `new Response(JSON.stringify(x), {status})` to build responses.
  - `extractRoles`: `{roles:['RECEPTION','HR']}` → both; `{role:'Sales Mobile'}` → `['Sales Mobile']`; `{}`/null → `[]`. `canAddCustomerFromRoles`: `['reception']` → true (case-insensitive); `['SALES MOBILE']` → false.
  - enums.test.ts: `leaveTypeLabel('Annual')==='إجازة سنوية'`, unknown passes through; `leaveStatusKey` Approved/Rejected/other; `attendanceStatusKey` all four; `apartmentCardStatus('Under Maintenance').label==='صيانة'`, `'vacant'→'متاحة'`, `'Occupied'→'مؤجرة'`; `customerStatusColor('مهتم')==='#16A34A'`, default `#6B7280`; `customerTypeLabel('individual')==='فرد'`; `AMENITIES.length===20` and exactly one key `petsAllowed`.
  - format.test.ts: `apiDate(new Date(2026,9,21))==='2026-10-21'`; `parseDate('2026-10-21')` round-trips; `parseDate('2026-10-21T09:30:00')` date part; `dayMonth` → `21 أكتوبر`; `time12(new Date(2026,9,21,9,5))==='09:05 ص'`, 13:30 → `01:30 م`, 0:00 → `12:00 ص`; `clock` no suffix; `longDate`/`weekdayDayMonth` weekday names; `money(1234567)==='1,234,567'`, `money(null)==='0'`, `money('750000')==='750,000'`.
- [ ] **Step 3: Run** — `npm test`. Expected: all pass.
- [ ] **Step 4: Commit** — `git add -A && git commit -m "test: vitest unit tests for api envelope, roles, enums, formatters"`

### Task 3: Playwright setup + login/shell smoke test

**Files:**
- Create: `playwright.config.ts`, `tests/e2e/mocks.ts`, `tests/e2e/login.spec.ts`
- Modify: `package.json` (add `"test:e2e": "playwright test"`, devDependency `@playwright/test`)

**Interfaces:** Produces `tests/e2e/mocks.ts` exporting `async function mockApi(page: Page, overrides?: Record<string, unknown>)` that registers `page.route('**/api/mobile/**', ...)` handlers returning canned JSON per endpoint, and `async function loginViaUi(page)` / `async function seedSession(page)` (sets localStorage keys `auth_token`, `full_name`, `employee_id`, `user_roles` before navigation via `page.addInitScript`). All later page tasks consume these.

- [ ] **Step 1: Install** — `npm i -D @playwright/test && npx playwright install chromium`
- [ ] **Step 2: playwright.config.ts** — testDir `tests/e2e`, use `{ baseURL: 'http://localhost:3100' }`, webServer `{ command: 'npm run dev -- -p 3100', url: 'http://localhost:3100', reuseExistingServer: true, timeout: 120000 }`, single chromium project with a mobile viewport (390×844).
- [ ] **Step 3: mocks.ts** — route handler keyed by `(method, pathname)`. Default dataset (field names are the backend contract — keep exactly):
  - `POST /api/mobile/auth/login` → `{token:'t1', user:{id:'u1', email:'a@b.c', name:'أحمد محمد', roles:['RECEPTION']}, employee:{employeeCode:'EMP-7'}}`
  - `GET /api/mobile/dashboard` → `{data:{leave_balance:12, monthly_hours:160, pending_requests:2, attendance_rate:95, recent_activities:[{action:'تسجيل حضور', type:'checkin'}]}}`
  - `GET /api/mobile/leaves` → `{data:{leaves:[{leave_type:'Annual', from_date:'2026-10-01', to_date:'2026-10-03', total_leave_days:3, status:'Approved', description:'سفر'}]}}`; `/leaves/balance` → `{data:[{leave_type:'Annual', balance:12, total_allocated:21}]}`; `/leaves/types` → `{data:['Annual','Sick']}`; `POST /leaves` → `{data:{ok:true}}`
  - `GET /api/mobile/attendance` → `{data:[{date:'2026-10-20', working_hours:8.5, status:'Present'}]}`; `/attendance/today` → `{data:[]}`; `/attendance/checkin-requests` → `{data:{requests:[]}}`
  - `GET /api/mobile/customers` → `{data:[{id:'c1', customerName:'سارة علي', phone:'07700000000', email:'s@x.com', customerType:'individual', status:'', _count:{ownedApartments:1, tenantApartments:0}}]}`; `GET /customers/c1` → full object incl. `budget:500000`, `createdAt:'2026-01-05T10:00:00Z'`, `source:'إعلان'`, `type:'VIP'`, `favouriteAddresses:[]`, `statusLogs:[]`, `ownedApartments:[]`, `tenantApartments:[]`; `POST /customers` and `POST /customers/c1/status` → `{data:{ok:true}}`
  - `GET /api/mobile/apartments` → `{data:{apartments:[{id:'a1', apartmentNumber:'A-101', apartmentCode:'C7', status:'Vacant', monthlyRent:750000, numberOfBedrooms:3, numberOfBathrooms:2, totalArea:150, availableUnits:4, notes:'', compound:{compoundName:'مجمع الياسمين', city:'بغداد', district:'المنصور'}}], stats:{total:5, available:3, rented:2, total_revenue:2500000}}}`; `/apartments/compounds` → `{data:[{id:'cp1', compoundName:'مجمع الياسمين', blocks:[{id:'b1', name:'Block A'}]}]}`; `POST /apartments`, `PATCH /apartments/a1` → `{data:{ok:true}}`
  - `GET /api/mobile/me` → `{data:{user:{id:'u1', email:'a@b.c', name:'أحمد محمد', roles:['RECEPTION']}, employee:{fullName:'أحمد محمد', position:'موظف استقبال', employeeCode:'EMP-7', email:'a@b.c', phone:'0770', department:'المبيعات', hireDate:'2024-01-01T00:00:00Z'}, company:'SAR'}}`; `DELETE /me`, `POST /auth/logout` → `{data:{ok:true}}`
  - `overrides` lets a spec replace any `(method pathname)` entry with a custom `{status, body}`.
- [ ] **Step 4: login.spec.ts** — (a) wrong credentials: override login route to 401; fill email/password, click «تسجيل الدخول», expect text «البريد الإلكتروني أو كلمة المرور غير صحيحة»; (b) success: mock login, submit, expect URL `/dashboard`; (c) visiting `/dashboard` without a token redirects to `/login`.
- [ ] **Step 5: Run** — `npx playwright test tests/e2e/login.spec.ts`. Expected: 3 passed.
- [ ] **Step 6: Commit** — `git commit -am "test: playwright harness with mocked mobile API + login smoke tests"` (add new files first).

### Task 4: Dashboard page

**Files:**
- Create: `app/(shell)/dashboard/page.tsx`
- Test: `tests/e2e/dashboard.spec.ts`
- Oracle: `sar_app/lib/screens/dashboard.dart`

**Interfaces:** Consumes `getJson`, `getFullName`, `getEmployeeId`, `GradientHeader`, `HeaderLogo`, `StaggeredColumn`, `CenteredSpinner`, `MIcon`. Dashboard payload fields: `leave_balance:int`, `monthly_hours:number` (render `toFixed(0)`), `pending_requests:int`, `attendance_rate:int`, `recent_activities:[{action,type}]`.

- [ ] **Step 1: Failing test** — `dashboard.spec.ts`: seedSession + mockApi, goto `/dashboard`; expect «مرحباً بعودتك،», «أحمد محمد», «رقم الموظف: EMP-7», stat values `12 يوم`, `160 ساعة`, `2`, `%95`, activity «تسجيل حضور», and heading «النشاطات الأخيرة». Run → FAIL (404).
- [ ] **Step 2: Implement.** Vertical gradient header `#284A63→#3B6E71` (`linear-gradient(180deg, …)` — this header is top-to-bottom, unlike other tabs): logo (h-8), «مرحباً بعودتك،» (22px white), full name 28px bold (fallback `...`), «رقم الموظف: {id}» 14px `#BFDBFE`. Body: `StaggeredColumn` with a 2-col grid of 4 stat cards (icon 32px colored, value 22px bold, label 13px `#353535`): calendar_today/`#284A63`/«رصيد الإجازات»/`{n} يوم`; schedule/`#16A34A`/«ساعات هذا الشهر»/`{n} ساعة`; assignment_turned_in/`#EA580C`/«الطلبات المعلقة»/`{n}`; trending_up/`#9333EA`/«معدل الحضور»/`%{n}` — then «النشاطات الأخيرة» card: rows with `action` text + icon (`type==='checkin'` → login else description, 18px `#9CA3AF`), bottom border between rows, empty → «لا توجد نشاطات حديثة» in `#9CA3AF`. Errors: silent (`catch { setLoading(false) }`).
- [ ] **Step 3: Verify** — `npx tsc --noEmit` then `npx playwright test tests/e2e/dashboard.spec.ts`. Expected: PASS.
- [ ] **Step 4: Commit** — `feat: dashboard page (1:1 port)`

### Task 5: Leaves page

**Files:**
- Create: `app/(shell)/leaves/page.tsx`
- Test: `tests/e2e/leaves.spec.ts`
- Oracle: `sar_app/lib/screens/leaves.dart`

**Interfaces:** Consumes `getJson/postJson`, `leaveTypeLabel`, `leaveStatusKey`, `LEAVE_STATUS_CHIPS`, `parseDate/dayMonth`, `BottomSheet`, `Dropdown`, `DateField`, `TextArea`, `StaggeredColumn`, `MIcon`, `showToast`. Data: leaves list from `GET /leaves` → `{leaves:[{leave_type, from_date, to_date, total_leave_days, status, description?}]}`; balance from `GET /leaves/balance` → `[{leave_type, balance, total_allocated}]`; types `GET /leaves/types` → `string[]` (fetch all three in `Promise.all`).

- [ ] **Step 1: Failing test** — seedSession+mock, goto `/leaves`; expect «إدارة الإجازات», balance row «إجازة سنوية» + `12/21 يوم`, history card «إجازة سنوية», range `1 أكتوبر - 3 أكتوبر`, `(3 أيام)`, chip «موافق عليها». Then click «تقديم طلب», expect sheet title «تقديم طلب إجازة»; choose نوع الإجازة = «إجازة سنوية», pick from/to dates via the date-picker dialog («موافق»), fill السبب, click «تقديم الطلب», expect toast «تم تقديم طلب الإجازة بنجاح!». Run → FAIL.
- [ ] **Step 2: Implement.** Solid navy `#284A63` header: logo h-7, row [«إدارة الإجازات» 22px white / white button «تقديم طلب» with add icon, navy text, radius 8], then balance cards inside the header (bg white/10 radius 10): row [Arabic type label | `{remaining}/{total} يوم` — `toFixed(0)` equivalents via `Math.round`] + white progress bar (h-2, radius 4, track white/20, `width:{clamp(remaining/total,0,1)*100}%`). Body `StaggeredColumn`: «سجل الإجازات» (18px w600); empty → centered «لا توجد إجازات» `#9CA3AF`; cards: type label (16px w500), calendar_today 16px + `{d MMM} - {d MMM}` + `({n} أيام)` (`أيام` if n>1 else `يوم`), status icon on the end (from `LEAVE_STATUS_CHIPS[key].icon`, color = icon colors `#16A34A`/`#DC2626`/`#EA580C`), optional description line, pill chip (bg/text from chip map, no icon inside the pill — pill shows label only, matching Flutter). Request sheet: `BottomSheet` title «تقديم طلب إجازة» subtitle «املأ النموذج أدناه لتقديم طلب الإجازة»; `Dropdown` label «نوع الإجازة» hint «اختر النوع» options from fetched types mapped through `leaveTypeLabel`; two `DateField`s «من تاريخ»/«إلى تاريخ» side by side; `TextArea` «السبب» placeholder «أدخل السبب...»; navy 48px «تقديم الطلب». Submit only when type+both dates set (button no-ops otherwise, like Flutter); body `{leave_type, from_date: apiDate(from), to_date: apiDate(to), reason}`; success → close sheet, toast «تم تقديم طلب الإجازة بنجاح!», reload; failure → toast `خطأ: {message}` (sheet stays open).
- [ ] **Step 3: Verify** — tsc + `npx playwright test tests/e2e/leaves.spec.ts`. PASS.
- [ ] **Step 4: Commit** — `feat: leaves page with request sheet (1:1 port)`

### Task 6: Attendance page

**Files:**
- Create: `app/(shell)/attendance/page.tsx`, `lib/location.ts`
- Test: `tests/e2e/attendance.spec.ts`
- Oracle: `sar_app/lib/screens/attendance.dart` (+ `lib/services/location_service.dart` messages, already in spec §Attendance)

**Interfaces:**
- Produces `lib/location.ts`: `class LocationException extends Error` and `getCurrentPosition(): Promise<{latitude:number, longitude:number}>` — rejects with LocationException messages: geolocation unsupported/disabled → «يرجى تفعيل خدمة الموقع لتسجيل الحضور»; `PERMISSION_DENIED` → «تم رفض إذن الوصول إلى الموقع» (browser cannot distinguish denied-forever; keep the denied message); wraps `navigator.geolocation.getCurrentPosition` with `{enableHighAccuracy:true, timeout:15000}`; timeout/position-unavailable → «يرجى تفعيل خدمة الموقع لتسجيل الحضور».
- Data: `GET /attendance?month&year` → `[{date:'yyyy-MM-dd', working_hours:number, status}]`; `GET /attendance/today` → `[{log_type:'IN'|'OUT', time:ISO}]` (iterate in order: IN sets checkedIn+time via `time12(parseDate-with-time)`, OUT clears); `GET /attendance/checkin-requests` → `{requests:[{id, location?, note?, requestedBy?, requestedAt?}]}` (failure → `[]`); `POST /attendance/checkin|checkout` body `{latitude, longitude, requestId?}` (requestId key only when set) → `{time:ISO}`; `POST /attendance/requests` body `{reason: '{type}: {reason}', attendance_date}`.
- Note: checkin/checkout responses parse time with `new Date(iso)` (full datetime, not `parseDate`) before `time12`.

- [ ] **Step 1: Failing test** — seedSession+mock, grant geolocation permission + set `geolocation: {latitude:33.3, longitude:44.4}` in the test context; goto `/attendance`; expect «الحضور والانصراف», green button «تسجيل الحضور», «وقت الحضور: لم يتم التسجيل», tabs «عرض التقويم»/«السجل». Click check-in → expect toast «جاري تحديد الموقع...» then a toast starting «تم تسجيل الحضور في», button becomes red «تسجيل الانصراف». Switch to «السجل» tab → row with «8.5 ساعة عمل» and chip «حاضر». Second spec: mock today → `[{log_type:'IN', time:'2026-10-21T09:00:00'}]`, expect checkout button and «وقت الحضور: 09:00 ص». Third: requests → one request `{id:'r1', requestedBy:'المدير', location:'المكتب', note:'يرجى الحضور', requestedAt:'2026-10-21T08:00:00'}`; expect banner «تنبيه: مطلوب تسجيل الحضور», «طلب من: المدير», «الموقع: المكتب», note text, button «تأكيد تسجيل الحضور الآن»; click it → POST body includes `requestId:'r1'` (assert via route interception) and banner disappears. Run → FAIL.
- [ ] **Step 2: Implement.** Gradient header `#3B6E71→#284A63`: logo h-7, «الحضور والانصراف» 22px, inner card bg white/10 radius 12: live clock (`clock(now)`, 48px bold; `setInterval` 1s state tick) + `longDate(now)` 14px white/80; row of two 96px buttons — primary: `AnimatedSwitcher` equivalent (`key` swap + `icon-pop` CSS) between green `#22C55E` «تسجيل الحضور» (login icon 32) and red `#EF4444` «تسجيل الانصراف» (logout icon 32), white spinner while submitting, disabled while `submitting`; secondary outlined «طلب تسوية» (add icon, bg white/20, border white/30) → adjustment sheet. Below: schedule icon + «وقت الحضور: {checkedIn ? time : 'لم يتم التسجيل'}». GPS submit flow exactly: guard `submitting`; toast «جاري تحديد الموقع...»; `getCurrentPosition()`; POST; `time12(new Date(result.time))`; success toast `تم تسجيل الحضور في {time}` / `تم تسجيل الانصراف في {time}`; update state (+ remove the matching pending request on requestId check-in); LocationException → toast its message; other errors → message contains `DoesNotExist` → «لا يوجد سجل موظف مرتبط بحسابك» else `خطأ: {message}`; finally clear `submitting`. Banners (only when `!loading && !checkedIn && requests.length`): per spec/oracle — bg `#FFF7ED`, border `#FB923C`, radius 12; orange circle with white notifications_active icon; title «تنبيه: مطلوب تسجيل الحضور» (`#9A3412` w700 15px); requester line `طلب من: {requestedBy}` or «طلب تسجيل حضور من الإدارة» (`#7C2D12` 13px); optional `الموقع: {location}` (w600); optional `الوقت: {requestTime(new Date(requestedAt))}` (12px `#9A3412`); optional note box (bg white/60 radius 8); full-width 44px `#EA580C` button with check_circle icon «تأكيد تسجيل الحضور الآن». Tabs: segmented control (container bg `#F3F4F6` radius 8; active segment white card shadow) «عرض التقويم» / «السجل»; calendar tab renders `CalendarView` with `records` mapped `{date: parseDate(r.date), hours, status}` (pass raw backend status strings — CalendarView maps them); history tab lists all records: `weekdayDayMonth(parseDate(date))` w500, below it `status==='Present'||'Half Day'` → `{hours.toFixed(1)} ساعة عمل` else «لا يوجد حضور», end pill from `ATTENDANCE_STATUS_CHIPS[attendanceStatusKey(status)]`. Adjustment sheet: title «طلب تسوية الحضور» subtitle «قدم طلب لتسوية سجل الحضور الخاص بك»; Dropdown «نوع الطلب» hint «اختر النوع» options `ATTENDANCE_REQUEST_TYPES`; DateField «التاريخ»; TextArea «السبب» placeholder «اشرح سبب طلبك...»; navy «تقديم الطلب»; requires date+reason (type optional — Flutter sends `'{type ?? ''}: {reason}'`); success → close + toast «تم تقديم طلب تسوية الحضور بنجاح!» (no reload); failure `خطأ: {message}`.
- [ ] **Step 3: Verify** — tsc + `npx playwright test tests/e2e/attendance.spec.ts`. PASS.
- [ ] **Step 4: Commit** — `feat: attendance page — GPS check-in/out, admin request banners, calendar/history (1:1 port)`

### Task 7: Customers list + shared status sheet

**Files:**
- Create: `app/(shell)/customers/page.tsx`, `components/customer-status-sheet.tsx`
- Test: `tests/e2e/customers.spec.ts`
- Oracle: `sar_app/lib/screens/customers.dart` (lines 1–562)

**Interfaces:**
- Produces `CustomerStatusSheet({open, current, onClose}: {open:boolean; current:string|null; onClose:(result:{status:string; description:string}|null)=>void})` — presentation only; and `async function changeCustomerStatus(customerId: string, result: {status:string; description:string}): Promise<boolean>` (exported from the same file): POSTs `/api/mobile/customers/{id}/status` with `{status, description?}` (description key omitted when empty), toast «تم تحديث الحالة» → true; catch → toast `فشل تحديث الحالة: {message}` → false. Task 8 (detail) consumes both.
- Data: `GET /customers` (optional `{search}`) → `[{id, customerName, phone, email, customerType, status, _count:{ownedApartments, tenantApartments}}]`.

- [ ] **Step 1: Failing test** — seedSession (roles `['RECEPTION']`) + mock; goto `/customers`; expect «العملاء», «عملاء مُسنَدون إليك», «إضافة عميل» visible, card «سارة علي» with chip «فرد», phone, email, status button «تحديد الحالة», mini-stat «1 يمتلك». Type `xyz` in search → «لا يوجد عملاء مُسنَدون إليك»; clear → card back. Click status button → sheet «تغيير الحالة»; «حفظ» disabled; pick «مهتم», type note, save → toast «تم تحديث الحالة». Second spec: roles `['SALES MOBILE']` → «إضافة عميل» absent. Run → FAIL.
- [ ] **Step 2: Implement sheet** — `BottomSheet` (no title prop; render centered bold «تغيير الحالة» 16px inside): three radio rows from `CUSTOMER_STATUSES` — radio icon (radio_button_checked filled in `customerStatusColor(s)` when selected, else radio_button_unchecked `#9CA3AF`) + label; outlined textarea «ملاحظة (اختياري)» maxLength 500 rows 3; navy 48px «حفظ» disabled until a status is chosen; resolves `{status, description: note.trim()}` on save, `null` on dismiss. Initial selection = `current` if it's one of the three.
- [ ] **Step 3: Implement page.** Gradient header `#284A63→#0D9488`: logo h-7; row [«العملاء» 22px | if `canAddCustomer()` (load on mount) white/20 radius-10 button add-icon «إضافة عميل» → `router.push('/customers/new')`]; «عملاء مُسنَدون إليك» 13px white/70; white search input radius 10, search icon, placeholder «ابحث بالاسم، البريد، أو الهاتف» — typing filters the loaded list client-side (lowercased name/email/phone `includes`). Body: loading spinner / error → centered `خطأ: {message}` red / empty → «لا يوجد عملاء مُسنَدون إليك» `#6B7280` / cards: white radius 12 border `#E5E7EB`; row [avatar 44px circle bg `#DBEAFE` first char `#1E40AF` bold | name 16px w600 + type chip (bg `#F3F4F6`, 11px, radius 6, `customerTypeLabel`) | chevron_left `#9CA3AF`] — card body navigates to `/customers/{id}`; phone row (phone icon 14 `#6B7280`) and email row when present; status button (stopPropagation): bg `customerStatusColor` at 8% + 30% border, flag icon 14 + text (`status || 'تحديد الحالة'`) 12px w600 + edit icon 12, all in the status color → opens sheet; on saved → reload list. Mini-stats row when counts > 0: `{n} يمتلك` (home icon, `#16A34A` bg 8%) / `{n} يستأجر` (key icon, `#2563EB`). Pull-to-refresh: a refresh icon-button in the header row (web substitute, per spec) calling reload with current `search` passed as `?search=`.
- [ ] **Step 4: Verify** — tsc + `npx playwright test tests/e2e/customers.spec.ts`. PASS.
- [ ] **Step 5: Commit** — `feat: customers list + change-status sheet (1:1 port, RECEPTION-gated add button)`

### Task 8: Customer detail page

**Files:**
- Create: `app/(shell)/customers/[id]/page.tsx`
- Test: `tests/e2e/customer-detail.spec.ts`
- Oracle: `sar_app/lib/screens/customers.dart` (lines 564–1034)

**Interfaces:** Consumes `CustomerStatusSheet`/`changeCustomerStatus`, `getJson`, `money`, `dateTime`, `showToast`. Data from `GET /customers/{id}`: `customerName, phone, email, customerType, source, type` (sub-type «التصنيف»), `status, budget, createdAt, favouriteAddresses:[{territory?, country?, city?, district?, streetAddress?}], statusLogs:[{status, description?, datetime? | createdAt?}], ownedApartments / tenantApartments:[{apartmentNumber, apartmentCode, status, cashPrice?, monthlyRent?, compound:{compoundName, city}}]`.

- [ ] **Step 1: Failing test** — goto `/customers/c1`; expect app bar «تفاصيل العميل», name, sections «معلومات الاتصال» (الهاتف/البريد), «معلومات عامة» (نوع العميل، المصدر، التصنيف، «الميزانية» `500,000 د.ع`, «تاريخ الإضافة»), button «تغيير الحالة», green button `اتصل بـ 07700000000`; click call → toast «الهاتف: 07700000000». Error spec: override to 500 → `خطأ: حدث خطأ في الاتصال`. Run → FAIL.
- [ ] **Step 2: Implement.** This page has its own navy app bar (56px, `#284A63`, white): back arrow (arrow_forward icon in RTL → use `arrow_back` with automatic RTL mirroring via `rotate-180`? No — Material Symbols don't auto-flip; use `arrow_forward` which points toward the screen edge in RTL, matching Flutter's back chevron) calling `router.back()`, title «تفاصيل العميل». Content (p-4): gradient card `#284A63→#0D9488` radius 12: white avatar 56px (first char navy bold 22px), name 20px bold white, raw `customerType` white/70 13px, status pill (bg white/20, flag icon, 12px w600) when status set. `section(title, rows)` card (white radius 12 border `#E5E7EB`, 15px w700 title + divider) rendered only when it has rows: «معلومات الاتصال» [phone/email info-rows]; «معلومات عامة» [نوع العميل (raw), المصدر, التصنيف (`type`), الميزانية `«{money(budget)} د.ع»` when >0, تاريخ الإضافة `dateTime(new Date(createdAt))`]; «العقارات المملوكة ({n})» / «العقارات المستأجرة ({n})» tiles: icon home green / key blue, `{number} • {code}` w600, `{compoundName} - {city}` 12px gray, raw status mini-chip bg `#F3F4F6`, amount `#059669` w600 — owner `«{money(cashPrice)} د.ع سعر»`, tenant `«{money(monthlyRent)} د.ع/شهر»` when >0; «عناوين مفضلة» info-rows: label `territory || 'عنوان'`, value = non-empty of [country, city, district, streetAddress] joined «، ». Then navy 48px «تغيير الحالة» (flag icon) → status sheet → on save reload. «سجل الحالات» section when logs: per log — blue chip (bg `#DBEAFE` text `#1E40AF` 12px w600) + `dateTime(new Date(datetime ?? createdAt))` 12px `#6B7280`, optional note 13px. Finally green `#16A34A` 48px `اتصل بـ {phone}` (phone icon) → `showToast('الهاتف: {phone}')` (quirk kept). Info-row helper: icon 18 `#6B7280`, label 12px `#6B7280`, value 14px w500.
- [ ] **Step 3: Verify** — tsc + playwright spec. PASS.
- [ ] **Step 4: Commit** — `feat: customer detail page (1:1 port)`

### Task 9: New customer page

**Files:**
- Create: `app/(shell)/customers/new/page.tsx`
- Test: `tests/e2e/customer-new.spec.ts`
- Oracle: `sar_app/lib/screens/customers.dart` (lines 1036–1204)

**Interfaces:** Consumes `postJson`, `TextField`, `Dropdown`, `Spinner`, `showToast`. POST body: `{customerName: trimmed, phone?, email?, customerType?, budget?}` — optional keys omitted when empty / unparsable (`budget` = `Number(t)` only when `t` non-empty and finite).

- [ ] **Step 1: Failing test** — goto `/customers/new`; app bar «إضافة عميل»; save with empty name → inline error «اسم العميل مطلوب», no POST; email `abc` → «بريد إلكتروني غير صالح»; valid fill (name + نوع العميل «فرد» + budget 500000) → intercept POST body `{customerName:'…', customerType:'individual', budget:500000}` (no phone/email keys), toast «تمت إضافة العميل بنجاح», navigates back to `/customers`. Run → FAIL.
- [ ] **Step 2: Implement.** Navy app bar «إضافة عميل» + back. Form (p-4, white-filled fields per oracle): `TextField` «اسم العميل *» (error on submit when blank), «الهاتف» (tel), «البريد الإلكتروني» (email; non-empty must contain `@`), `Dropdown` «نوع العميل» options [{individual,'فرد'},{company,'شركة'}], «الميزانية» (numeric). Navy 48px «حفظ» with white spinner while saving; double-submit guard. Success → toast «تمت إضافة العميل بنجاح» + `router.back()` (list reloads on return — trigger via a `sessionStorage` flag or simply `router.push('/customers')`; the list page reloads data on mount, matching Flutter's `.then(created → reload)`). Failure → `فشل إضافة العميل: {message}`, saving reset.
- [ ] **Step 3: Verify** — tsc + spec. PASS.
- [ ] **Step 4: Commit** — `feat: add-customer form (RECEPTION flow, 1:1 port)`

### Task 10: Apartments page

**Files:**
- Create: `app/(shell)/apartments/page.tsx`, `app/(shell)/apartments/add-sheet.tsx`
- Test: `tests/e2e/apartments.spec.ts`
- Oracle: `sar_app/lib/screens/apartments.dart`

**Interfaces:**
- Data: `GET /apartments` → `{apartments:[…], stats:{total, available, rented, total_revenue}}`; card fields `apartmentNumber, apartmentCode, status, monthlyRent, numberOfBedrooms, numberOfBathrooms, totalArea, notes, availableUnits, compound:{compoundName, city, district}`; `GET /apartments/compounds` → `[{id, compoundName, blocks:[{id, name}]}]`; `PATCH /apartments/{id}` body `{availableUnits: int|null}`; `POST /apartments` body = the exact 50-key map in the oracle lines 686–754 (port key-for-key: numbers via `numOrNull` = `''→null` else `Number`, empty strings → null for text/date fields, all 22 booleans always present, `installmentFrequency` only when paymentMethod==='Both' else null, `constructionEndDate` only when buildingStatus==='Under Construction' and date set, `documents` array from uploads).
- `add-sheet.tsx` produces `AddApartmentSheet({open, onClose, onCreated}: {open:boolean; onClose:()=>void; onCreated:()=>void})` — fetches compounds itself on open.

- [ ] **Step 1: Failing test** — goto `/apartments`; expect «إدارة الشقق», stats «5»/«إجمالي الشقق», «3»/«شقق متاحة», «2»/«شقق مؤجرة», «2,500,000 د.ع»/«الإيرادات الشهرية», «شققي (1)», card «شقة A-101 (C7)», location «مجمع الياسمين، المنصور، بغداد», chip «متاحة», tiles 750,000/«د.ع/شهر», 3/«غرف», 2/«حمامات», 150/«م²». Units dialog: click «تعديل عدد الوحدات» → dialog «تعديل عدد الوحدات» with «الشقة: A-101», input prefilled `4`; type `abc` + save → toast «أدخل رقمًا صحيحًا» and no PATCH; type `6` + «حفظ» → PATCH body `{availableUnits:6}` + toast «تم حفظ التعديل». Add sheet: click «إضافة شقة» → sheet «إضافة شقة جديدة»; submit immediately → toast «يرجى ملء المجمع، المبنى، ورقم الشقة»; select compound «مجمع الياسمين» → block dropdown gains «Block A»; select it, fill رقم الشقة `B-202`, toggle amenity «مصعد», click «إضافة الشقة» → intercept POST: `compoundId:'cp1'`, `compoundBlockId:'b1'`, `apartmentNumber:'B-202'`, `hasElevator:true`, `petsAllowed:false`, `status:'Vacant'`, `installmentFrequency:null`, `documents:[]` → toast «تم إضافة الشقة بنجاح!». Run → FAIL.
- [ ] **Step 2: Implement page.** Gradient header `#16A34A→#0D9488`: logo h-7; row [«إدارة الشقق» 22px | white button «إضافة شقة» (green text)]; 2-col stats grid (bg white/10 radius 10, value 20px bold white, label 13px white/80): total/«إجمالي الشقق», available/«شقق متاحة», rented/«شقق مؤجرة», `{money(total_revenue)} د.ع`/«الإيرادات الشهرية». Body `StaggeredColumn`: `شققي ({n})` 18px w600; empty «لا توجد شقق» `#9CA3AF`; cards: `شقة {number} ({code})` 18px w500 (code part only when code non-empty), location_on 16px + joined [compoundName, district, city] by «، », end pill from `apartmentCardStatus(status)`; optional notes line; 4 equal tiles (bg `#F9FAFB` radius 8, icon 18 colored, value 13px w500, label 11px `#9CA3AF`): payments/`{money(monthlyRent)}`/«د.ع/شهر» green, bed/«غرف» navy, bathtub/«حمامات» `#9333EA`, crop_square/«م²» `#EA580C`; top-border footer with outlined green «تعديل عدد الوحدات» (edit icon 16). Units dialog (modal, radius 20): title «تعديل عدد الوحدات», «الشقة: {number}» 13px `#6B7280`, input «عدد الوحدات المتاحة» numeric autofocus prefilled with current value; buttons «إلغاء» (text) / green «حفظ» with spinner; validation: non-empty and (`!Number.isInteger(+t)` or `<0`) → toast «أدخل رقمًا صحيحًا»; empty → PATCH `null`; success → close + toast «تم حفظ التعديل» + reload; failure `خطأ: {message}`.
- [ ] **Step 3: Implement add-sheet.** `BottomSheet` title «إضافة شقة جديدة» subtitle «املأ البيانات لإضافة شقة جديدة». On open: fetch compounds (error → red `خطأ: {e}` 13px; empty → orange «لا توجد مجمعات»). Field order/sections exactly per oracle (and spec §7-Apartments): required green-labeled «المجمع السكني *» dropdown (compoundName), «المبنى (Block) *» (blocks of selected compound; reset on compound change), «رقم الشقة *» (hint `مثال: A-101`); «معلومات المبنى»: رقم المبنى (hint B1) + رقم الطابق (3), عدد الطوابق (10) + الوحدات المتاحة (5); «مواصفات الوحدة»: نوع الشقة dropdown (`APARTMENT_TYPES`, hint «نوع الشقة»), غرف النوم (3) + الحمامات (2), غرف المعيشة (1) + المساحة (م²) (150), المساحة الصافية (م²) (130), switches بلكونة + غرفة خادمة, dropdowns حالة التأثيث/`FURNISHING_STATUSES` + الإطلالة/`VIEW_TYPES`, الحالة الإنشائية/`CONDITIONS` + حالة البناء/`BUILDING_STATUSES` (hint «اختر» each), conditional DateField «تاريخ انتهاء الإنشاء» when Under Construction; «المرافق»: 20 `FilterChip`s from `AMENITIES` (wrap, gap 8); «الحالة والإيجار»: الحالة/`APARTMENT_FORM_STATUSES` default `Vacant` + نوع العرض/`OFFERING_TYPES`, نوع الإشغال/`OCCUPANCY_TYPES`, الإيجار الشهري (750000) + رسوم الصيانة (50000), الضمان (1000000) + الرصيد المستحق (0), DateFields بداية الإيجار / نهاية الإيجار / تاريخ الانتقال; «الدفع»: طريقة الدفع/`PAYMENT_METHODS` + switches من المالك / عبر وسيط, conditional «السعر النقدي» (500000) when Cash|Both, Both-only block: الدفعة الأولى (100000) + دفعة الاستلام (50000), قسط شهري (25000) + قسط ربع سنوي (75000), قسط نصف سنوي (150000) + قسط سنوي (300000), تكرار الدفع/`INSTALLMENT_FREQUENCIES` default Monthly + المدة (سنوات) (5), السعر الإجمالي (750000); divider; DateField «تاريخ آخر فحص», TextArea «ملاحظات» («أدخل ملاحظات...»), «رابط الخطة (Floor Plan URL)» (https://...); «صور الشقة»: hidden `<input type="file" multiple accept="image/*">`, 80×80 `URL.createObjectURL` thumbnails radius 10 with red −4-offset close badge, dashed add tile add_a_photo icon «إضافة صور» 10px `#9CA3AF`. Submit green 48px «إضافة الشقة»: guard toast «يرجى ملء المجمع، المبنى، ورقم الشقة»; `for` each image `uploadFile(file)` → `{documentName:'Photo', documentType:'Photo', file:url}`; build the full body per the oracle key list; POST; success → close + toast «تم إضافة الشقة بنجاح!» + `onCreated()`; failure → toast `خطأ: {message}` (sheet stays open). Store all date values as `Date|null` and serialize with `apiDate`.
- [ ] **Step 4: Verify** — tsc + `npx playwright test tests/e2e/apartments.spec.ts`. PASS.
- [ ] **Step 5: Commit** — `feat: apartments page — stats, cards, units dialog, full add-apartment sheet (1:1 port)`

### Task 11: Profile page

**Files:**
- Create: `app/(shell)/profile/page.tsx`
- Test: `tests/e2e/profile.spec.ts`
- Oracle: `sar_app/lib/screens/profile.dart`

**Interfaces:** Consumes `getJson`, `logout`, `deleteAccount`, `StaggeredColumn`, `MIcon`, `showToast`, `Spinner`. `GET /me` → `{user:{name, email}, employee:{fullName, position, employeeCode, email, phone, department, hireDate}, company}`; flatten: name = `employee.fullName ?? user.name`; email = `employee.email ?? user.email`; phone = `employee.phone`; joining date = `String(hireDate).split('T')[0]`.

- [ ] **Step 1: Failing test** — goto `/profile`; expect «الملف الشخصي», name «أحمد محمد», avatar initials «أم», designation «موظف استقبال», chip «EMP-7», rows البريد الإلكتروني/الهاتف/القسم/المسمى الوظيفي/«2024-01-01»/الشركة, links سياسة الخصوصية (href `https://sar-iq.com/privacy`, target _blank) / شروط الاستخدام (`/terms`) / التواصل مع الدعم (`mailto:support@sar-realestate.com`). «تسجيل الخروج» → localStorage `auth_token` cleared + URL `/login`. Delete flow: «حذف الحساب» → dialog; «حذف نهائي» disabled; type «حذف» → enabled; confirm → DELETE `/api/mobile/me` intercepted, URL `/login`, toast «تم حذف الحساب بنجاح». Run → FAIL.
- [ ] **Step 2: Implement.** Gradient header `#284A63→#3B6E71` fixed height 180px: logo h-7 + «الملف الشخصي» 22px. Content pulled up `-mt-16` (Flutter −64 translate), px-4, `StaggeredColumn`: profile card (elevated, p-6 centered): navy avatar 96px with initials (first chars of first two non-empty name words), name 22px bold, designation 14px `#353535`, employeeId pill (bg `#D9DAD9`, text `#3B6E71` 14px). Info card: rows [البريد الإلكتروني mail / الهاتف call / القسم work / المسمى الوظيفي work / تاريخ الانضمام calendar_today / الشركة business] — only non-empty values; icon 20 `#9CA3AF`, label 13px `#353535`, value 15px w500, bottom borders except last. Links card: three `<a>` rows (icon `#6B7280` start, label 14px, open_in_new 16 `#9CA3AF` end, dividers): «سياسة الخصوصية» → https://sar-iq.com/privacy, «شروط الاستخدام» → https://sar-iq.com/terms, «التواصل مع الدعم» → mailto:support@sar-realestate.com — all `target="_blank" rel="noopener"`. Outlined red «تسجيل الخروج» (logout icon, border `#FECACA`, text `#DC2626`, 48px) → `await logout()` → `router.replace('/login')`. Red text button «حذف الحساب» (delete_forever icon) → dialog (radius 20): title «حذف الحساب», body «سيؤدي هذا الإجراء إلى حذف حسابك وجميع بياناتك الشخصية المرتبطة به بشكل دائم. لا يمكن التراجع عن هذه العملية.» + «للتأكيد، اكتب كلمة "حذف" في الحقل أدناه:» + input (hint «حذف»); «إلغاء» / red filled «حذف نهائي» enabled only when input.trim()==='حذف'; confirm → full-screen blocking spinner overlay → `deleteAccount()` → `router.replace('/login')` + toast «تم حذف الحساب بنجاح»; failure → close overlay + toast `فشل حذف الحساب: {message}`. Footer caption «حذف الحساب عملية دائمة ولا يمكن التراجع عنها» (11px `#9CA3AF`, centered).
- [ ] **Step 3: Verify** — tsc + spec. PASS.
- [ ] **Step 4: Commit** — `feat: profile page — info, legal links, logout, delete-account flow (1:1 port)`

### Task 12: Full verification + PWA checks

**Files:** none new (fixes only if verification fails).

- [ ] **Step 1: Full test suite** — `npm test && npx playwright test`. All pass.
- [ ] **Step 2: Production build** — `npm run build`. Must succeed with all routes listed (`/login`, `/dashboard`, `/leaves`, `/attendance`, `/apartments`, `/customers`, `/customers/[id]`, `/customers/new`, `/profile`, `/offline`, `/api/[...path]`).
- [ ] **Step 3: PWA smoke** — `npm run start -- -p 3200` then: `curl -s localhost:3200/manifest.json` has `"dir":"rtl"`, `"display":"standalone"`, `"theme_color":"#284A63"`, 192/512/maskable icons; `curl -s localhost:3200/sw.js` serves the worker; `curl -s localhost:3200/offline` renders the Arabic offline page. Stop the server.
- [ ] **Step 4: /verify skill** — run the project verify flow (launch dev server, drive login → each tab with mocked or real API as available, screenshot) before claiming completion.
- [ ] **Step 5: Commit any fixes** — `fix: verification fixes` (only if needed). Final state: clean tree, all tests green, production build passing.

---

## Self-review notes

- Spec coverage: §1–2 architecture/structure (done in scaffold, Task 1); §3 theme (globals.css, Task 1); §4 formatting (lib/format.ts + Task 2 tests); §5 shell (Task 1); §6 components (Task 1); §7 screens → Tasks 4–11; §8 API contract → mocks.ts (Task 3) + per-task bodies; §9 PWA → Task 12; §10 errors → embedded per task; §11 testing → Tasks 2, 3, and per-page specs; §12 out-of-scope quirks preserved (Tasks 7, 8, 10).
- Flutter dashboard header is vertical gradient (top→bottom); all other tab headers are horizontal (centerRight→centerLeft ≙ CSS `90deg` in RTL → use `linear-gradient(to left, from, to)`); customer-detail/profile per oracle. GradientHeader takes raw CSS gradients via its `from/to` + 135deg default — pass a `className`/style override where direction matters; acceptable to add an optional `direction` prop (additive, non-breaking).
- `POST /attendance/requests` sends `reason`/`attendance_date` only (no separate type key) — type is prefixed into reason.
- Leaves balance «يوم» count uses rounded ints; `total_allocated` default 1 avoids ÷0 (oracle line 274).
