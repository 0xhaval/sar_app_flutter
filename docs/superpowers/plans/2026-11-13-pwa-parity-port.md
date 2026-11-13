# PWA → Flutter Parity Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port every feature added to the sibling PWA (`/mnt/data/relocated/Flutter/sar_pwa`) after its 1:1 port back into this Flutter app, so the two apps are at feature parity.

**Architecture:** The Flutter app keeps its existing structure — one screen file per domain under `lib/screens/`, static `ApiService`, shared widgets under `lib/widgets/`. New inventory-browse feature gets `lib/screens/inventory.dart` (3 screens), `lib/services/inventory_filters.dart` (pure filter model), `lib/widgets/inventory_filter_sheet.dart`. Customer-domain features are edits to `lib/screens/customers.dart`. All API contracts are copied verbatim from the PWA.

**Tech Stack:** Flutter (Dart ^3.11.3), `http`, `shared_preferences`, `intl`, `fluttertoast`. Tests with `flutter_test`.

## Global Constraints

- All user-facing strings are Arabic, copied **verbatim** from the PWA source (exact strings included in each task below).
- Endpoints and payloads must match the PWA byte-for-byte: paths under `/api/mobile/...`, field names as given per task.
- Colors: primary green `0xFF16A34A`, teal `0xFF0D9488`, navy `0xFF284A63`, chip bg `0xFFF0FDF4`, muted `0xFF6B7280`, body `0xFF353535`, border `0xFFE5E7EB`.
- Money formatting: `NumberFormat('#,###')` (Latin digits) + suffix `د.ع`.
- RTL: pushed screens wrap in `Directionality(textDirection: TextDirection.rtl, ...)` like `CustomerDetailScreen`.
- Verify with `/home/frappe/flutter/bin/flutter analyze` (no new issues) and `/home/frappe/flutter/bin/flutter test` after each task.
- Work on branch `feat/pwa-parity`. Commit after each task with the message given in the task; end every commit message with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Explicitly OUT of scope (reviewed, deliberately not ported): PWA `statusCode 0` network-error normalization (Flutter has richer per-site handling), unused `getUserEmail()` getter, PWA platform plumbing (service worker, Netlify, proxy).

---

### Task 1: `ApiService.putJson`

**Files:**
- Modify: `lib/services/api_service.dart` (after `patchJson`, line ~104)

**Interfaces:**
- Produces: `static Future<dynamic> ApiService.putJson(String path, {Map<String, dynamic>? body})` — used by Task 7 (`PUT /api/mobile/customers/{id}/compounds`).

- [ ] **Step 1: Add the method** (mirror of `patchJson`):

```dart
  static Future<dynamic> putJson(String path,
      {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await http.put(
      _uri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return parseBody(response, authenticated: _hasToken(headers));
  }
```

- [ ] **Step 2: Verify** — `flutter analyze` clean.
- [ ] **Step 3: Commit** — `feat(api): add putJson helper for PUT endpoints`

---

### Task 2: Customer status vocabulary — 3 → 7 values + full color map

**Files:**
- Modify: `lib/screens/customers.dart:7-22`
- Test: `test/screens/customer_status_test.dart` (currently asserts a stale 3-value list containing `متابعة` — already failing)

**Interfaces:**
- Produces: `kCustomerStatuses` (7 values) and `_statusColor` used by sheet, card chip, detail.

- [ ] **Step 1: Update the failing test** to the backend-truth 7-value list (same as PWA `lib/enums.ts:85-93`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sar_app/screens/customers.dart';

void main() {
  test('customer statuses match the backend seven-value vocabulary', () {
    expect(kCustomerStatuses, [
      'جديد',
      'تم التواصل',
      'زار المجمع',
      'مهتم',
      'غير مهتم',
      'مغلق - قام بالشراء',
      'مغلق - لم يشترِ',
    ]);
  });
}
```

- [ ] **Step 2: Run it, confirm FAIL** (code still has 3 values).
- [ ] **Step 3: Update `kCustomerStatuses` and `_statusColor`** (colors from PWA `customerStatusColor`):

```dart
/// Fixed customer-status vocabulary. MUST stay identical to
/// CUSTOMER_STATUSES in real-estate-app src/lib/validations.ts.
const List<String> kCustomerStatuses = [
  'جديد',
  'تم التواصل',
  'زار المجمع',
  'مهتم',
  'غير مهتم',
  'مغلق - قام بالشراء',
  'مغلق - لم يشترِ',
];

Color _statusColor(String status) {
  switch (status) {
    case 'جديد':
      return const Color(0xFF6B7280);
    case 'تم التواصل':
      return const Color(0xFF0891B2);
    case 'زار المجمع':
      return const Color(0xFF7C3AED);
    case 'مهتم':
      return const Color(0xFF16A34A);
    case 'غير مهتم':
      return const Color(0xFFDC2626);
    case 'مغلق - قام بالشراء':
      return const Color(0xFF2563EB);
    case 'مغلق - لم يشترِ':
      return const Color(0xFF991B1B);
    default:
      return const Color(0xFF6B7280);
  }
}
```

- [ ] **Step 4: Run test, confirm PASS.**
- [ ] **Step 5: Commit** — `feat(customers): sync status vocabulary and colors with backend (7 values)`

---

### Task 3: Feedback note — note-only sheet + "إضافة ملاحظة" button on detail

**Files:**
- Modify: `lib/screens/customers.dart` (top-level helpers after `changeCustomerStatus`; detail buttons at ~line 781)

**Interfaces:**
- Produces: `Future<bool> addCustomerNote(BuildContext context, String customerId)`.
- API: `POST /api/mobile/customers/{id}/status` body `{'description': note}` — **no `status` key** (logs feedback against current stage). Toast on success: `تمت إضافة الملاحظة`.

- [ ] **Step 1: Add the note sheet + helper** after `changeCustomerStatus` (~line 134):

```dart
/// Bottom sheet: note-only feedback (no status change). Resolves to the
/// trimmed note text or null when dismissed.
Future<String?> _showNoteSheet(BuildContext context) {
  final noteController = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'إضافة ملاحظة',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      labelText: 'الملاحظة',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: noteController.text.trim().isEmpty
                          ? null
                          : () =>
                              Navigator.of(ctx).pop(noteController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF284A63),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Opens the note sheet for [customerId] and posts a note-only status log.
/// Returns true when a note was added (caller should refresh).
Future<bool> addCustomerNote(BuildContext context, String customerId) async {
  final note = await _showNoteSheet(context);
  if (note == null || note.isEmpty) return false;
  try {
    await ApiService.postJson(
      '/api/mobile/customers/$customerId/status',
      body: {'description': note},
    );
    Fluttertoast.showToast(msg: 'تمت إضافة الملاحظة');
    return true;
  } catch (e) {
    Fluttertoast.showToast(msg: 'فشل إضافة الملاحظة: $e');
    return false;
  }
}
```

- [ ] **Step 2: Add the button on detail** — in `_buildDetail`, directly after the existing `تغيير الحالة` button `Padding` (ends ~line 796), add:

```dart
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final added = await addCustomerNote(context, widget.customerId);
                if (added && mounted) _load();
              },
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('إضافة ملاحظة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF284A63),
                side: const BorderSide(color: Color(0xFF284A63)),
              ),
            ),
          ),
        ),
```

- [ ] **Step 3: Verify** — `flutter analyze` clean, `flutter test` green.
- [ ] **Step 4: Commit** — `feat(customers): add note-only feedback sheet on customer detail`

---

### Task 4: Duplicate-phone 409 inline error on add-customer form

**Files:**
- Modify: `lib/screens/customers.dart` (`_CustomerFormScreenState`, ~lines 1043-1204)

**Interfaces:**
- API behavior: `POST /api/mobile/customers` returns HTTP 409 when phone already exists; `ApiException.statusCode == 409`, message from server. Fallback message: `هذا الرقم مسجّل مسبقاً لعميل آخر`. No toast for the 409 case; error shows inline on the phone field and clears when the phone is edited.

- [ ] **Step 1: Add state + wire the field.** Add `String? _phoneError;` next to `_saving`. Extend `_field` with optional `errorText` and `onChanged` parameters:

```dart
  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: _decoration(label).copyWith(errorText: errorText),
      ),
    );
  }
```

Phone field becomes:

```dart
              _field(
                controller: _phoneController,
                label: 'الهاتف',
                keyboardType: TextInputType.phone,
                errorText: _phoneError,
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
```

- [ ] **Step 2: Branch in `_submit` catch** (replace existing catch body):

```dart
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (e is ApiException && e.statusCode == 409) {
        setState(() => _phoneError =
            e.message.isNotEmpty ? e.message : 'هذا الرقم مسجّل مسبقاً لعميل آخر');
        return;
      }
      Fluttertoast.showToast(msg: 'فشل إضافة العميل: $e');
    }
```

Also clear `_phoneError` at the top of `_submit` (`setState(() { _saving = true; _phoneError = null; });`).

- [ ] **Step 3: Verify** — `flutter analyze` clean.
- [ ] **Step 4: Commit** — `feat(customers): show duplicate-phone 409 error inline on add form`

---

### Task 5: Compound picker bottom sheet widget

**Files:**
- Create: `lib/widgets/compound_picker_sheet.dart`

**Interfaces:**
- Produces: `class CompoundOption { final String id; final String compoundName; final String city; }` and `Future<List<CompoundOption>?> showCompoundPickerSheet(BuildContext context, {List<String> initialIds = const []})` — null when dismissed, else the full new selection.
- API: `GET /api/mobile/compounds` → list of `{id, compoundName, city}` (after `{data}` unwrap).
- Strings: title `اختر المجمعات`, search hint `ابحث عن مجمع أو مدينة`, save button `حفظ (<n>)`, empty `لا توجد نتائج`, load error `تعذّر تحميل المجمعات`.

- [ ] **Step 1: Write the widget:**

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CompoundOption {
  final String id;
  final String compoundName;
  final String city;

  const CompoundOption({
    required this.id,
    required this.compoundName,
    required this.city,
  });

  factory CompoundOption.fromJson(Map<String, dynamic> json) => CompoundOption(
        id: (json['id'] ?? '').toString(),
        compoundName: (json['compoundName'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
      );
}

/// Multi-select compound picker. Loads GET /api/mobile/compounds, filters
/// client-side by name/city. Resolves to the selected compounds, or null
/// when dismissed.
Future<List<CompoundOption>?> showCompoundPickerSheet(
  BuildContext context, {
  List<String> initialIds = const [],
}) {
  return showModalBottomSheet<List<CompoundOption>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CompoundPickerSheet(initialIds: initialIds),
  );
}

class _CompoundPickerSheet extends StatefulWidget {
  final List<String> initialIds;

  const _CompoundPickerSheet({required this.initialIds});

  @override
  State<_CompoundPickerSheet> createState() => _CompoundPickerSheetState();
}

class _CompoundPickerSheetState extends State<_CompoundPickerSheet> {
  bool _loading = true;
  String? _error;
  List<CompoundOption> _options = [];
  late final Set<String> _selected = {...widget.initialIds};
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getJson('/api/mobile/compounds');
      if (!mounted) return;
      setState(() {
        _options = List<Map<String, dynamic>>.from(data ?? [])
            .map(CompoundOption.fromJson)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل المجمعات';
        _loading = false;
      });
    }
  }

  List<CompoundOption> get _filtered {
    if (_search.trim().isEmpty) return _options;
    final q = _search.trim().toLowerCase();
    return _options
        .where((o) =>
            o.compoundName.toLowerCase().contains(q) ||
            o.city.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر المجمعات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'ابحث عن مجمع أو مدينة',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SizedBox(
                  height: 320,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style:
                                    const TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          : _filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'لا توجد نتائج',
                                    style:
                                        TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                )
                              : ListView(
                                  children: _filtered.map((o) {
                                    final checked = _selected.contains(o.id);
                                    return CheckboxListTile(
                                      value: checked,
                                      activeColor: const Color(0xFF16A34A),
                                      title: Text(o.compoundName),
                                      subtitle: o.city.isEmpty
                                          ? null
                                          : Text(
                                              o.city,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                      onChanged: (v) => setState(() {
                                        if (v == true) {
                                          _selected.add(o.id);
                                        } else {
                                          _selected.remove(o.id);
                                        }
                                      }),
                                    );
                                  }).toList(),
                                ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(
                    _options.where((o) => _selected.contains(o.id)).toList(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF284A63),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('حفظ (${_selected.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify** — `flutter analyze` clean.
- [ ] **Step 3: Commit** — `feat(customers): multi-select compound picker sheet`

---

### Task 6: Add-customer form — interested compounds field

**Files:**
- Modify: `lib/screens/customers.dart` (`_CustomerFormScreenState`)

**Interfaces:**
- Consumes: `showCompoundPickerSheet`, `CompoundOption` from Task 5 (`import '../widgets/compound_picker_sheet.dart';`).
- API: create body gains `'interestedCompoundIds': [...]` **only when non-empty** (PWA `customers/new/page.tsx:51`).
- Strings: field label `المجمعات المهتم بها`, placeholder value `اختر المجمعات (اختياري)`.

- [ ] **Step 1: Add state** `List<CompoundOption> _selectedCompounds = [];` and a tappable selector between the customer-type dropdown and the budget field:

```dart
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showCompoundPickerSheet(
                      context,
                      initialIds:
                          _selectedCompounds.map((c) => c.id).toList(),
                    );
                    if (picked != null) {
                      setState(() => _selectedCompounds = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: _decoration('المجمعات المهتم بها'),
                    child: Text(
                      _selectedCompounds.isEmpty
                          ? 'اختر المجمعات (اختياري)'
                          : _selectedCompounds
                              .map((c) => c.compoundName)
                              .join('، '),
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedCompounds.isEmpty
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
              ),
```

- [ ] **Step 2: Extend the create body** in `_submit`:

```dart
      if (_selectedCompounds.isNotEmpty)
        'interestedCompoundIds':
            _selectedCompounds.map((c) => c.id).toList(),
```

- [ ] **Step 3: Verify** — `flutter analyze` clean.
- [ ] **Step 4: Commit** — `feat(customers): pick interested compounds on add-customer form`

---

### Task 7: Customer detail — code badge, assigned date, interested compounds + edit

**Files:**
- Modify: `lib/screens/customers.dart` (`_CustomerDetailScreenState._buildDetail` and `_section`)

**Interfaces:**
- Consumes: Task 1 `ApiService.putJson`, Task 5 picker.
- API: `PUT /api/mobile/customers/{id}/compounds` body `{'compoundIds': [...]}`. Toast: `تم تحديث المجمعات المهتم بها`.
- Detail payload fields: `customerCode` (string), `assignedAt` (ISO), `interestedCompounds: [{compound: {id, compoundName}}]`.
- Strings: InfoRow label `تاريخ الاستلام` (icon `Icons.event_available`), section `المجمعات المهتم بها`, edit action `تعديل`.

- [ ] **Step 1: Read the fields** at the top of `_buildDetail`:

```dart
    final customerCode = (c['customerCode'] ?? '').toString();
    final assignedAt = c['assignedAt']?.toString();
    final interested =
        List<Map<String, dynamic>>.from(c['interestedCompounds'] ?? []);
```

- [ ] **Step 2: Code badge in the gradient header** — after the name `Text` (and before the `type` block):

```dart
              if (customerCode.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    customerCode,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
```

- [ ] **Step 3: Assigned-date row** — in the `معلومات عامة` section after the `createdAt` row:

```dart
          if (assignedAt != null && assignedAt.isNotEmpty)
            _infoRow(
              Icons.event_available,
              'تاريخ الاستلام',
              _formatDate(assignedAt),
            ),
```

- [ ] **Step 4: Interested-compounds section with edit action.** Add an optional `action` parameter to `_section`:

```dart
  Widget _section(String title, List<Widget> children, {Widget? action}) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
```

Then insert the section after `معلومات عامة` (before owned apartments). It must render even when the list is empty so the edit action is reachable — pass a placeholder row when empty:

```dart
        _section(
          'المجمعات المهتم بها',
          interested.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'لا توجد مجمعات',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ),
                ]
              : interested.map((ic) {
                  final compound = (ic['compound'] as Map?) ?? const {};
                  return _infoRow(
                    Icons.apartment,
                    'مجمع',
                    (compound['compoundName'] ?? '').toString(),
                  );
                }).toList(),
          action: TextButton(
            onPressed: _editCompounds,
            child: const Text(
              'تعديل',
              style: TextStyle(color: Color(0xFF16A34A), fontSize: 13),
            ),
          ),
        ),
```

- [ ] **Step 5: The `_editCompounds` method** on `_CustomerDetailScreenState`:

```dart
  Future<void> _editCompounds() async {
    final interested = List<Map<String, dynamic>>.from(
        _customer?['interestedCompounds'] ?? []);
    final currentIds = interested
        .map((ic) =>
            ((ic['compound'] as Map?) ?? const {})['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final picked =
        await showCompoundPickerSheet(context, initialIds: currentIds);
    if (picked == null) return;
    try {
      await ApiService.putJson(
        '/api/mobile/customers/${widget.customerId}/compounds',
        body: {'compoundIds': picked.map((c) => c.id).toList()},
      );
      Fluttertoast.showToast(msg: 'تم تحديث المجمعات المهتم بها');
      if (mounted) _load();
    } catch (e) {
      Fluttertoast.showToast(msg: 'فشل تحديث المجمعات: $e');
    }
  }
```

- [ ] **Step 6: Verify** — `flutter analyze` clean, `flutter test` green.
- [ ] **Step 7: Commit** — `feat(customers): detail shows code, assigned date, and editable interested compounds`

---

### Task 8: Customer card — interested-compound badge

**Files:**
- Modify: `lib/screens/customers.dart` (`_buildCustomerCard`)

**Interfaces:**
- List payload field: `interestedCompounds: [{compound: {id, compoundName}}]`.
- Label logic (PWA `customers/page.tsx:225-233`): first compound name, plus ` +<n-1>` when more than one. Badge color teal `0xFF0D9488` at 10% bg, text `0xFF0D7A6F`, icon `Icons.apartment`.

- [ ] **Step 1: Build the label** at the top of `_buildCustomerCard`:

```dart
    final interested = List<Map<String, dynamic>>.from(
        customer['interestedCompounds'] ?? []);
    final compoundNames = interested
        .map((ic) =>
            ((ic['compound'] as Map?) ?? const {})['compoundName']
                ?.toString() ??
            '')
        .where((n) => n.isNotEmpty)
        .toList();
    final interestLabel = compoundNames.isEmpty
        ? ''
        : compoundNames.length == 1
            ? compoundNames.first
            : '${compoundNames.first} +${compoundNames.length - 1}';
```

- [ ] **Step 2: Render the badge** right before the owned/tenant mini-stats block (`if (ownedCount > 0 || tenantCount > 0)`):

```dart
            if (interestLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.apartment,
                        size: 14, color: Color(0xFF0D7A6F)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        interestLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0D7A6F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
```

- [ ] **Step 3: Verify** — `flutter analyze` clean.
- [ ] **Step 4: Commit** — `feat(customers): interested-compound badge on customer card`

---

### Task 9: Bulk status change (multi-select on list)

**Files:**
- Modify: `lib/screens/customers.dart` (`_CustomersScreenState`, `_buildCustomerCard`, top-level helper)

**Interfaces:**
- API: `POST /api/mobile/customers/bulk/status` body `{'ids': [...], 'status': ..., 'description': ...?}` → response `{count}`. Toast: `تم تحديث <count> عميل`.
- Strings: header toggle `تحديد` / `إلغاء`; action bar `<n> محدد` + button `تغيير الحالة`.
- Behavior (PWA `customers/page.tsx`): while selecting — add button hidden, card tap toggles selection instead of navigating, checkbox leading on each card; bar appears only when ≥1 selected; on success exit select mode + reload.

- [ ] **Step 1: Top-level bulk helper** after `addCustomerNote`:

```dart
/// Opens the status sheet and applies the choice to all [customerIds].
/// Returns true when applied (caller should refresh).
Future<bool> bulkChangeCustomerStatus(
  BuildContext context,
  List<String> customerIds,
) async {
  final result = await _showStatusSheet(context);
  if (result == null) return false;
  try {
    final res = await ApiService.postJson(
      '/api/mobile/customers/bulk/status',
      body: {
        'ids': customerIds,
        'status': result['status'],
        if ((result['description'] ?? '').isNotEmpty)
          'description': result['description'],
      },
    );
    final count = (res is Map ? res['count'] as num? : null)?.toInt() ??
        customerIds.length;
    Fluttertoast.showToast(msg: 'تم تحديث $count عميل');
    return true;
  } catch (e) {
    Fluttertoast.showToast(msg: 'فشل تحديث الحالة: $e');
    return false;
  }
}
```

- [ ] **Step 2: Selection state** on `_CustomersScreenState`:

```dart
  bool _selectMode = false;
  final Set<String> _selectedIds = {};
```

Header row: before the `if (_canAddCustomer)` button add the toggle, and hide the add button while selecting (`if (_canAddCustomer && !_selectMode)`):

```dart
                      Material(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            _selectMode = !_selectMode;
                            _selectedIds.clear();
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(
                              _selectMode ? 'إلغاء' : 'تحديد',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_canAddCustomer && !_selectMode) ...[
                        const SizedBox(width: 8),
                        // existing إضافة عميل button unchanged
                      ],
```

- [ ] **Step 3: Card selection behavior.** In `_buildCustomerCard`: compute `final id = customer['id']?.toString() ?? '';` and `final selected = _selectedIds.contains(id);`. Change the card `InkWell.onTap` to:

```dart
        onTap: () async {
          if (_selectMode) {
            setState(() {
              if (!_selectedIds.add(id)) _selectedIds.remove(id);
            });
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customerId: id),
            ),
          );
        },
```

Add a leading checkbox in the avatar `Row` (before `CircleAvatar`), shown only in select mode:

```dart
                if (_selectMode) ...[
                  Icon(
                    selected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: selected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                ],
```

And highlight the selected card border: on the card `Container` decoration, use `border: Border.all(color: selected ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB))`.

- [ ] **Step 4: Bottom action bar.** Wrap the screen's `RefreshIndicator` child in a `Stack` and pin the bar; simplest structural change: make `build` return

```dart
    return Stack(
      children: [
        RefreshIndicator( /* existing tree unchanged */ ),
        if (_selectMode && _selectedIds.isNotEmpty)
          Positioned(
            right: 16,
            left: 16,
            bottom: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF284A63),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      '${_selectedIds.length} محدد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        final updated = await bulkChangeCustomerStatus(
                          context,
                          _selectedIds.toList(),
                        );
                        if (updated && mounted) {
                          setState(() {
                            _selectMode = false;
                            _selectedIds.clear();
                          });
                          _loadData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('تغيير الحالة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
```

- [ ] **Step 5: Verify** — `flutter analyze` clean, `flutter test` green.
- [ ] **Step 6: Commit** — `feat(customers): bulk status change for selected customers`

---

### Task 10: Inventory filter model (pure logic) + unit tests

**Files:**
- Create: `lib/services/inventory_filters.dart`
- Test: `test/services/inventory_filters_test.dart`

**Interfaces:**
- Produces: `class Opt { final String value; final String label; }`, option constants (`kPaymentMethods`, `kInstallmentFreqs`, `kInstallmentYears`, `kOfferingTypes`, `kBuildingStatuses`, `kApartmentTypes`, `kApartmentStatuses`, `kBedroomOpts`, `kBathroomOpts`, `kFurnishing`, `kViewTypes`, `kConditions`, `kAmenities`), and `class InventoryFilters` with `Map<String, String> serialize()`, `int get activeCount`, `InventoryFilters copy()`, `static const unset = '__all__'`.
- Port of PWA `lib/inventory-filters.ts` — values are backend canonical English, labels Arabic, **inventory-specific amenity list (15 items), not the apartments-screen list**.

- [ ] **Step 1: Write the failing test** `test/services/inventory_filters_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sar_app/services/inventory_filters.dart';

void main() {
  test('default filters serialize to empty map and zero active count', () {
    final f = InventoryFilters();
    expect(f.serialize(), isEmpty);
    expect(f.activeCount, 0);
  });

  test('select, range, and list filters serialize like the PWA', () {
    final f = InventoryFilters()
      ..apartmentType = 'Studio'
      ..minPrice = '100000'
      ..maxPrice = '500000'
      ..buildingStatus = ['Under Construction', 'Ready to move in']
      ..amenities = ['hasElevator'];
    expect(f.serialize(), {
      'apartmentType': 'Studio',
      'minPrice': '100000',
      'maxPrice': '500000',
      'buildingStatus': 'Under Construction,Ready to move in',
      'amenities': 'hasElevator',
    });
    expect(f.activeCount, 5);
  });

  test('unset sentinel and empty strings are omitted', () {
    final f = InventoryFilters()
      ..status = InventoryFilters.unset
      ..minArea = '';
    expect(f.serialize(), isEmpty);
  });

  test('inventory amenity list has the 15 browse-specific entries', () {
    expect(kAmenities.length, 15);
    expect(kAmenities.first.value, 'hasBalcony');
    expect(kAmenities.first.label, 'بلكونة');
  });
}
```

- [ ] **Step 2: Run it, confirm FAIL** (file missing).
- [ ] **Step 3: Implement** `lib/services/inventory_filters.dart`:

```dart
/// Inventory-browse filter model. 1:1 port of the PWA's
/// sar_pwa/lib/inventory-filters.ts — values are the backend's canonical
/// English strings; labels are the Arabic shown in the filter sheet.
/// NOTE: the amenity list here is the browse-specific 15-item list and is
/// intentionally different from the apartments screen's 20-item list.
library;

class Opt {
  final String value;
  final String label;

  const Opt(this.value, this.label);
}

const kPaymentMethods = [
  Opt('Cash', 'نقداً'),
  Opt('Both', 'نقد وأقساط'),
];

const kInstallmentFreqs = [
  Opt('Monthly', 'شهري'),
  Opt('Quarterly', 'ربع سنوي'),
  Opt('Semi-Annual', 'نصف سنوي'),
  Opt('Annual', 'سنوي'),
];

const kInstallmentYears = [
  Opt('1', '1 سنة'),
  Opt('2', '2 سنة'),
  Opt('3', '3 سنة'),
  Opt('5', '5 سنة'),
  Opt('7', '7 سنة'),
  Opt('10', '10 سنة'),
  Opt('15', '15 سنة'),
  Opt('20', '20 سنة'),
];

const kOfferingTypes = [
  Opt('Rent', 'إيجار'),
  Opt('Sale', 'بيع'),
];

const kBuildingStatuses = [
  Opt('Under Construction', 'قيد الإنشاء'),
  Opt('Ready to move in', 'جاهز للسكن'),
];

const kApartmentTypes = [
  Opt('Studio', 'استوديو'),
  Opt('Apartment', 'شقة'),
  Opt('Duplex', 'دوبلكس'),
  Opt('Penthouse', 'بنتهاوس'),
  Opt('Loft', 'لوفت'),
  Opt('Townhouse', 'تاون هاوس'),
  Opt('Villa', 'فيلا'),
];

const kApartmentStatuses = [
  Opt('Vacant', 'شاغرة'),
  Opt('Occupied', 'مؤجرة'),
  Opt('Reserved', 'محجوزة'),
  Opt('Under Maintenance', 'تحت الصيانة'),
];

const kBedroomOpts = [
  Opt('1', '1 غرف'),
  Opt('2', '2 غرف'),
  Opt('3', '3 غرف'),
  Opt('4', '4 غرف'),
  Opt('5+', '5+ غرف'),
];

const kBathroomOpts = [
  Opt('1', '1 حمام'),
  Opt('2', '2 حمام'),
  Opt('3', '3 حمام'),
  Opt('4', '4 حمام'),
  Opt('5+', '5+ حمام'),
];

const kFurnishing = [
  Opt('Unfurnished', 'غير مفروشة'),
  Opt('Semi-Furnished', 'نصف مفروشة'),
  Opt('Fully Furnished', 'مفروشة بالكامل'),
];

const kViewTypes = [
  Opt('City', 'المدينة'),
  Opt('Garden', 'حديقة'),
  Opt('Pool', 'مسبح'),
  Opt('Sea', 'بحر'),
  Opt('Mountain', 'جبل'),
  Opt('Street', 'شارع'),
  Opt('Park', 'منتزه'),
];

const kConditions = [
  Opt('Excellent', 'ممتازة'),
  Opt('Good', 'جيدة'),
  Opt('Fair', 'مقبولة'),
  Opt('Needs Repair', 'تحتاج إصلاح'),
  Opt('Under Renovation', 'قيد التجديد'),
];

const kAmenities = [
  Opt('hasBalcony', 'بلكونة'),
  Opt('hasSwimmingPool', 'مسبح'),
  Opt('hasCoveredParking', 'موقف مسقّف'),
  Opt('hasElevator', 'مصعد'),
  Opt('hasAirConditioning', 'تكييف'),
  Opt('hasPrivateGarden', 'حديقة خاصة'),
  Opt('hasSecurity', 'حراسة'),
  Opt('hasMaidRoom', 'غرفة خادمة'),
  Opt('hasKidsPlayArea', 'منطقة ألعاب أطفال'),
  Opt('petsAllowed', 'يسمح بالحيوانات'),
  Opt('hasLandlinePhone', 'هاتف أرضي'),
  Opt('hasKitchenAppliances', 'أجهزة مطبخ'),
  Opt('hasWaterMeter', 'عداد ماء'),
  Opt('hasElectricityMeter', 'عداد كهرباء'),
  Opt('hasNaturalGasMeter', 'عداد غاز'),
];

class InventoryFilters {
  static const unset = '__all__';

  String paymentMethod = unset;
  String installmentFrequency = unset;
  String minInstallment = '';
  String maxInstallment = '';
  String installmentYears = unset;
  String apartmentType = unset;
  String bedrooms = unset;
  String bathrooms = unset;
  String minPrice = '';
  String maxPrice = '';
  String minRent = '';
  String maxRent = '';
  String minArea = '';
  String maxArea = '';
  String status = unset;
  String furnishingStatus = unset;
  String viewType = unset;
  String condition = unset;
  String offeringType = unset;
  List<String> buildingStatus = [];
  List<String> amenities = [];

  /// Query params exactly as the PWA's serializeFilters emits them.
  Map<String, String> serialize() {
    final out = <String, String>{};
    void sel(String key, String value) {
      if (value.isNotEmpty && value != unset) out[key] = value;
    }

    void range(String key, String value) {
      if (value.isNotEmpty) out[key] = value;
    }

    sel('paymentMethod', paymentMethod);
    sel('installmentFrequency', installmentFrequency);
    sel('installmentYears', installmentYears);
    sel('apartmentType', apartmentType);
    sel('bedrooms', bedrooms);
    sel('bathrooms', bathrooms);
    sel('status', status);
    sel('furnishingStatus', furnishingStatus);
    sel('viewType', viewType);
    sel('condition', condition);
    sel('offeringType', offeringType);
    range('minInstallment', minInstallment);
    range('maxInstallment', maxInstallment);
    range('minPrice', minPrice);
    range('maxPrice', maxPrice);
    range('minRent', minRent);
    range('maxRent', maxRent);
    range('minArea', minArea);
    range('maxArea', maxArea);
    if (buildingStatus.isNotEmpty) out['buildingStatus'] = buildingStatus.join(',');
    if (amenities.isNotEmpty) out['amenities'] = amenities.join(',');
    return out;
  }

  int get activeCount => serialize().length;

  InventoryFilters copy() {
    return InventoryFilters()
      ..paymentMethod = paymentMethod
      ..installmentFrequency = installmentFrequency
      ..minInstallment = minInstallment
      ..maxInstallment = maxInstallment
      ..installmentYears = installmentYears
      ..apartmentType = apartmentType
      ..bedrooms = bedrooms
      ..bathrooms = bathrooms
      ..minPrice = minPrice
      ..maxPrice = maxPrice
      ..minRent = minRent
      ..maxRent = maxRent
      ..minArea = minArea
      ..maxArea = maxArea
      ..status = status
      ..furnishingStatus = furnishingStatus
      ..viewType = viewType
      ..condition = condition
      ..offeringType = offeringType
      ..buildingStatus = [...buildingStatus]
      ..amenities = [...amenities];
  }
}
```

- [ ] **Step 4: Run test, confirm PASS.**
- [ ] **Step 5: Commit** — `feat(inventory): filter model with PWA-compatible serialization`

---

### Task 11: Inventory filter sheet widget

**Files:**
- Create: `lib/widgets/inventory_filter_sheet.dart`

**Interfaces:**
- Consumes: Task 10 model/constants.
- Produces: `Future<InventoryFilters?> showInventoryFilterSheet(BuildContext context, InventoryFilters initial)` — resolves to the applied draft or null on cancel/dismiss.
- Strings/UX (PWA `components/inventory/filter-sheet.tsx`): title `الفلاتر`, reset `تصفير`, dropdown labels/orders and "all" labels exactly as listed below, ranges with `من`/`إلى` hints, chip groups `حالة البناء` + `المرافق`, footer `إلغاء` / `تطبيق` (green `0xFF16A34A`).
- Dropdowns in order (label → options → all-label): النوع→kApartmentTypes→كل الأنواع; الحالة→kApartmentStatuses→كل الحالات; غرف النوم→kBedroomOpts→أي عدد; الحمامات→kBathroomOpts→أي عدد; العرض→kOfferingTypes→الكل; طريقة الدفع→kPaymentMethods→الكل; تكرار القسط→kInstallmentFreqs→الكل; سنوات التقسيط→kInstallmentYears→الكل; الفرش→kFurnishing→الكل; الإطلالة→kViewTypes→الكل; الحالة الإنشائية→kConditions→الكل.
- Ranges in order: السعر (نقداً)→minPrice/maxPrice; الإيجار الشهري→minRent/maxRent; المساحة (م²)→minArea/maxArea; القسط الشهري→minInstallment/maxInstallment.

- [ ] **Step 1: Write the widget:**

```dart
import 'package:flutter/material.dart';
import '../services/inventory_filters.dart';

/// Inventory filter bottom sheet — 1:1 port of the PWA's filter-sheet.tsx.
/// Resolves to the applied filters, or null when cancelled/dismissed.
Future<InventoryFilters?> showInventoryFilterSheet(
  BuildContext context,
  InventoryFilters initial,
) {
  return showModalBottomSheet<InventoryFilters>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _InventoryFilterSheet(initial: initial),
  );
}

class _InventoryFilterSheet extends StatefulWidget {
  final InventoryFilters initial;

  const _InventoryFilterSheet({required this.initial});

  @override
  State<_InventoryFilterSheet> createState() => _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends State<_InventoryFilterSheet> {
  late InventoryFilters _draft = widget.initial.copy();
  late final Map<String, TextEditingController> _ranges = {
    'minPrice': TextEditingController(text: _draft.minPrice),
    'maxPrice': TextEditingController(text: _draft.maxPrice),
    'minRent': TextEditingController(text: _draft.minRent),
    'maxRent': TextEditingController(text: _draft.maxRent),
    'minArea': TextEditingController(text: _draft.minArea),
    'maxArea': TextEditingController(text: _draft.maxArea),
    'minInstallment': TextEditingController(text: _draft.minInstallment),
    'maxInstallment': TextEditingController(text: _draft.maxInstallment),
  };

  @override
  void dispose() {
    for (final c in _ranges.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _reset() {
    setState(() {
      _draft = InventoryFilters();
      for (final c in _ranges.values) {
        c.clear();
      }
    });
  }

  InventoryFilters _collect() {
    return _draft
      ..minPrice = _ranges['minPrice']!.text.trim()
      ..maxPrice = _ranges['maxPrice']!.text.trim()
      ..minRent = _ranges['minRent']!.text.trim()
      ..maxRent = _ranges['maxRent']!.text.trim()
      ..minArea = _ranges['minArea']!.text.trim()
      ..maxArea = _ranges['maxArea']!.text.trim()
      ..minInstallment = _ranges['minInstallment']!.text.trim()
      ..maxInstallment = _ranges['maxInstallment']!.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'الفلاتر',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'تصفير',
                      style: TextStyle(color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _selectGrid(),
                    const SizedBox(height: 8),
                    _range('السعر (نقداً)', 'minPrice', 'maxPrice'),
                    _range('الإيجار الشهري', 'minRent', 'maxRent'),
                    _range('المساحة (م²)', 'minArea', 'maxArea'),
                    _range('القسط الشهري', 'minInstallment', 'maxInstallment'),
                    const SizedBox(height: 8),
                    _chips(
                      'حالة البناء',
                      kBuildingStatuses,
                      _draft.buildingStatus,
                    ),
                    const SizedBox(height: 8),
                    _chips('المرافق', kAmenities, _draft.amenities),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_collect()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectGrid() {
    final selects = <Widget>[
      _select('النوع', 'كل الأنواع', kApartmentTypes, _draft.apartmentType,
          (v) => _draft.apartmentType = v),
      _select('الحالة', 'كل الحالات', kApartmentStatuses, _draft.status,
          (v) => _draft.status = v),
      _select('غرف النوم', 'أي عدد', kBedroomOpts, _draft.bedrooms,
          (v) => _draft.bedrooms = v),
      _select('الحمامات', 'أي عدد', kBathroomOpts, _draft.bathrooms,
          (v) => _draft.bathrooms = v),
      _select('العرض', 'الكل', kOfferingTypes, _draft.offeringType,
          (v) => _draft.offeringType = v),
      _select('طريقة الدفع', 'الكل', kPaymentMethods, _draft.paymentMethod,
          (v) => _draft.paymentMethod = v),
      _select('تكرار القسط', 'الكل', kInstallmentFreqs,
          _draft.installmentFrequency, (v) => _draft.installmentFrequency = v),
      _select('سنوات التقسيط', 'الكل', kInstallmentYears,
          _draft.installmentYears, (v) => _draft.installmentYears = v),
      _select('الفرش', 'الكل', kFurnishing, _draft.furnishingStatus,
          (v) => _draft.furnishingStatus = v),
      _select('الإطلالة', 'الكل', kViewTypes, _draft.viewType,
          (v) => _draft.viewType = v),
      _select('الحالة الإنشائية', 'الكل', kConditions, _draft.condition,
          (v) => _draft.condition = v),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: selects
          .map((w) => SizedBox(
                width: (MediaQuery.of(context).size.width - 44) / 2,
                child: w,
              ))
          .toList(),
    );
  }

  Widget _select(
    String label,
    String allLabel,
    List<Opt> options,
    String value,
    void Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: InventoryFilters.unset,
              child: Text(allLabel, style: const TextStyle(fontSize: 13)),
            ),
            ...options.map(
              (o) => DropdownMenuItem(
                value: o.value,
                child: Text(o.label, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
          onChanged: (v) =>
              setState(() => onChanged(v ?? InventoryFilters.unset)),
        ),
      ],
    );
  }

  Widget _range(String label, String minKey, String maxKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _rangeField(minKey, 'من')),
              const SizedBox(width: 8),
              Expanded(child: _rangeField(maxKey, 'إلى')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeField(String key, String hint) {
    return TextField(
      controller: _ranges[key],
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
    );
  }

  Widget _chips(String label, List<Opt> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final isOn = selected.contains(o.value);
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() {
                if (isOn) {
                  selected.remove(o.value);
                } else {
                  selected.add(o.value);
                }
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isOn ? const Color(0xFF16A34A) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isOn
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isOn ? Colors.white : const Color(0xFF353535),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify** — `flutter analyze` clean.
- [ ] **Step 3: Commit** — `feat(inventory): filter bottom sheet`

---

### Task 12: Inventory screens — compounds list, apartments list, apartment detail

**Files:**
- Create: `lib/screens/inventory.dart` (3 screens in one file, matching the one-file-per-domain convention)

**Interfaces:**
- Consumes: Tasks 10-11.
- Produces: `class InventoryScreen extends StatefulWidget` (tab root, used by Task 13); internal `_InventoryApartmentsScreen(compoundId)` and `_InventoryApartmentDetailScreen(apartmentId)` pushed via `MaterialPageRoute`.
- APIs: `GET /api/mobile/inventory/complexes` (serialized filters + optional `search`) → `{complexes: [...]}`; `GET /api/mobile/inventory/apartments` (filters + `compoundId` + `pageSize=100` + optional `search`) → `{apartments: [...]}`; `GET /api/mobile/inventory/apartments/{id}` → apartment object.
- Behavior: 300ms debounce on search/filter change; errors swallowed to empty state; header gradient green `0xFF16A34A → 0xFF0D9488` (right→left); filter button shows active-count badge.
- Detail renders enum fields (`apartmentType`, `paymentMethod`, `furnishingStatus`, `viewType`) as **raw backend English strings** — intentional PWA parity; amenities chips use `kAmenities`; list status chip map: Vacant→شاغرة, Occupied→مؤجرة, Reserved→محجوزة, Under Maintenance→صيانة (note: `صيانة` here, unlike the filter sheet's `تحت الصيانة`).

- [ ] **Step 1: Write the three screens:**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../services/api_service.dart';
import '../services/inventory_filters.dart';
import '../widgets/inventory_filter_sheet.dart';

final _money = NumberFormat('#,###');

/// List-card status labels (PWA apartments list page — deliberately uses
/// 'صيانة' while the filter sheet uses 'تحت الصيانة').
String _aptStatusLabel(String? status) {
  switch (status) {
    case 'Vacant':
      return 'شاغرة';
    case 'Occupied':
      return 'مؤجرة';
    case 'Reserved':
      return 'محجوزة';
    case 'Under Maintenance':
      return 'صيانة';
    default:
      return (status == null || status.isEmpty) ? '—' : status;
  }
}

const _headerGradient = LinearGradient(
  begin: Alignment.centerRight,
  end: Alignment.centerLeft,
  colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
);

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  InventoryFilters _filters = InventoryFilters();
  String _search = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final query = <String, dynamic>{
        ..._filters.serialize(),
        if (_search.trim().isNotEmpty) 'search': _search.trim(),
      };
      final data = await ApiService.getJson(
        '/api/mobile/inventory/complexes',
        query: query.isEmpty ? null : query,
      );
      final rows = (data is Map && data['complexes'] is List)
          ? List<Map<String, dynamic>>.from(data['complexes'])
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _loading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final applied = await showInventoryFilterSheet(context, _filters);
    if (applied != null) {
      setState(() => _filters = applied);
      _scheduleLoad();
    }
  }

  String? _priceLine(Map<String, dynamic> c) {
    final range = (c['priceRange'] as Map?) ?? const {};
    final min = range['min'] as num?;
    final max = range['max'] as num?;
    if (min == null && max == null) return null;
    if (min != null && max != null && min != max) {
      return '${_money.format(min)} - ${_money.format(max)} د.ع';
    }
    return '${_money.format(min ?? max)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: _headerGradient),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/logo.png', height: 28, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'تصفّح المخزون',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SearchField(
                      hint: 'ابحث عن مجمع أو مدينة',
                      onChanged: (v) {
                        _search = v;
                        _scheduleLoad();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    count: _filters.activeCount,
                    onTap: _openFilters,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _rows.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: _rows.map(_buildCard).toList(),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final name = (c['compoundName'] ?? '—').toString();
    final location = [c['city'], c['district']]
        .where((p) => p != null && p.toString().isNotEmpty)
        .join(' · ');
    final matching = (c['matchingApartments'] as num?)?.toInt() ?? 0;
    final price = _priceLine(c);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _InventoryApartmentsScreen(
              compoundId: c['id']?.toString() ?? '',
              filters: _filters,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location.isEmpty ? '—' : location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$matching شقة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (price != null) ...[
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF353535),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryApartmentsScreen extends StatefulWidget {
  final String compoundId;
  final InventoryFilters filters;

  const _InventoryApartmentsScreen({
    required this.compoundId,
    required this.filters,
  });

  @override
  State<_InventoryApartmentsScreen> createState() =>
      _InventoryApartmentsScreenState();
}

class _InventoryApartmentsScreenState
    extends State<_InventoryApartmentsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  late InventoryFilters _filters = widget.filters.copy();
  String _search = '';
  String _title = 'الشقق';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final query = <String, dynamic>{
        ..._filters.serialize(),
        'compoundId': widget.compoundId,
        'pageSize': '100',
        if (_search.trim().isNotEmpty) 'search': _search.trim(),
      };
      final data = await ApiService.getJson(
        '/api/mobile/inventory/apartments',
        query: query,
      );
      final rows = (data is Map && data['apartments'] is List)
          ? List<Map<String, dynamic>>.from(data['apartments'])
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        if (rows.isNotEmpty) {
          final compound = (rows.first['compound'] as Map?) ?? const {};
          final name = (compound['compoundName'] ?? '').toString();
          if (name.isNotEmpty) _title = name;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _loading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final applied = await showInventoryFilterSheet(context, _filters);
    if (applied != null) {
      setState(() => _filters = applied);
      _scheduleLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(gradient: _headerGradient),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackRow(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(height: 8),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SearchField(
                            hint: 'رقم الشقة',
                            onChanged: (v) {
                              _search = v;
                              _scheduleLoad();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          count: _filters.activeCount,
                          onTap: _openFilters,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _rows.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد شقق مطابقة',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: _rows.map(_buildCard).toList(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> a) {
    final number =
        (a['apartmentNumber'] ?? a['apartmentCode'] ?? '').toString();
    final status = _aptStatusLabel(a['status']?.toString());
    final specs = <String>[
      if ((a['apartmentType'] ?? '').toString().isNotEmpty)
        a['apartmentType'].toString(),
      if (a['numberOfBedrooms'] != null) '${a['numberOfBedrooms']} غرف',
      if (a['numberOfBathrooms'] != null) '${a['numberOfBathrooms']} حمام',
      if (a['totalArea'] != null) '${a['totalArea']} م²',
    ].join(' · ');
    final cashPrice = a['cashPrice'] as num?;
    final monthlyRent = a['monthlyRent'] as num?;
    final price = cashPrice != null
        ? '${_money.format(cashPrice)} د.ع'
        : monthlyRent != null
            ? '${_money.format(monthlyRent)} د.ع/شهر'
            : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _InventoryApartmentDetailScreen(
              apartmentId: a['id']?.toString() ?? '',
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'شقة $number',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (specs.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  specs,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF353535),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryApartmentDetailScreen extends StatefulWidget {
  final String apartmentId;

  const _InventoryApartmentDetailScreen({required this.apartmentId});

  @override
  State<_InventoryApartmentDetailScreen> createState() =>
      _InventoryApartmentDetailScreenState();
}

class _InventoryApartmentDetailScreenState
    extends State<_InventoryApartmentDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _apt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getJson(
        '/api/mobile/inventory/apartments/${widget.apartmentId}',
      );
      if (!mounted) return;
      setState(() {
        _apt = data is Map ? Map<String, dynamic>.from(data) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _apt = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _apt == null
                  ? const Center(
                      child: Text(
                        'تعذّر تحميل الشقة',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : _buildDetail(),
        ),
      ),
    );
  }

  Widget _buildDetail() {
    final apt = _apt!;
    final number =
        (apt['apartmentNumber'] ?? apt['apartmentCode'] ?? '').toString();
    final compound = (apt['compound'] as Map?) ?? const {};
    final compoundName = (compound['compoundName'] ?? '').toString();
    final docs = List<Map<String, dynamic>>.from(apt['documents'] ?? []);
    final photos = docs
        .map((d) => (d['file'] ?? '').toString())
        .where((f) => f.isNotEmpty)
        .toList();
    final notes = (apt['notes'] ?? '').toString();

    String? fmt(dynamic v, [String suffix = '']) {
      if (v == null || v.toString().isEmpty) return null;
      return '$v$suffix';
    }

    String? moneyFmt(dynamic v) {
      if (v is! num) return null;
      return '${_money.format(v)} د.ع';
    }

    final rows = <(String, String?)>[
      ('النوع', fmt(apt['apartmentType'])),
      ('غرف النوم', fmt(apt['numberOfBedrooms'])),
      ('الحمامات', fmt(apt['numberOfBathrooms'])),
      ('المساحة', fmt(apt['totalArea'], ' م²')),
      ('الطابق', fmt(apt['floorNumber'])),
      ('السعر نقداً', moneyFmt(apt['cashPrice'])),
      ('الإيجار الشهري', moneyFmt(apt['monthlyRent'])),
      ('طريقة الدفع', fmt(apt['paymentMethod'])),
      ('الفرش', fmt(apt['furnishingStatus'])),
      ('الإطلالة', fmt(apt['viewType'])),
    ].where((r) => r.$2 != null).toList();

    final amenities =
        kAmenities.where((a) => apt[a.value] == true).toList();

    return ListView(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: _headerGradient),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackRow(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 8),
              Text(
                'شقة $number',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (compoundName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  compoundName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (photos.isNotEmpty)
          SizedBox(
            height: 192,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              children: photos
                  .map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          width: 240,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 240,
                            height: 160,
                            color: const Color(0xFFE5E7EB),
                            child: const Icon(
                              Icons.broken_image,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...rows.map(
                (r) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.$1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        r.$2!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (amenities.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'المرافق',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenities
                      .map(
                        (a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            a.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'ملاحظات',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF353535),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackRow extends StatelessWidget {
  final VoidCallback onTap;

  const _BackRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          SizedBox(width: 4),
          Text(
            'رجوع',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 18, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'فلترة',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

Note: the PWA keeps ONE shared filter state across the compounds and apartments pages (both live under the same React layout). In Flutter the apartments screen receives a `copy()` of the compounds screen's filters at push time — edits inside the pushed screen intentionally don't mutate the parent (closest sensible mapping of the PWA's per-page URL state).

- [ ] **Step 2: Verify** — `flutter analyze` clean, `flutter test` green.
- [ ] **Step 3: Commit** — `feat(inventory): browse screens — compounds, apartments, read-only detail`

---

### Task 13: Bottom-nav تصفّح tab

**Files:**
- Modify: `lib/app_shell.dart`

**Interfaces:**
- Consumes: `InventoryScreen` from Task 12 (`import 'screens/inventory.dart';`).
- Tab position 5 of 7 (index 4), between الشقق and العملاء; label `تصفّح`; icon `Icons.search` (both states — PWA uses the same glyph with fill toggle). No role gating.

- [ ] **Step 1: Add the screen + nav item.** `_screens` becomes:

```dart
  final List<Widget> _screens = const [
    DashboardScreen(),
    LeavesScreen(),
    AttendanceScreen(),
    ApartmentsScreen(),
    InventoryScreen(),
    CustomersScreen(),
    ProfileScreen(),
  ];
```

Nav row items (customers and profile indexes shift +1):

```dart
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'الرئيسية'),
                  _buildNavItem(1, Icons.description_outlined, Icons.description, 'الإجازات'),
                  _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today, 'الحضور'),
                  _buildNavItem(3, Icons.apartment_outlined, Icons.apartment, 'الشقق'),
                  _buildNavItem(4, Icons.search, Icons.search, 'تصفّح'),
                  _buildNavItem(5, Icons.people_outline, Icons.people, 'العملاء'),
                  _buildNavItem(6, Icons.person_outline, Icons.person, 'الملف'),
```

- [ ] **Step 2: Verify** — `flutter analyze` clean; `flutter test` green (widget smoke test must still pass).
- [ ] **Step 3: Commit** — `feat(inventory): add تصفّح browse tab to bottom nav`

---

### Task 14: Attendance — live-ticking header clock

**Files:**
- Modify: `lib/screens/attendance.dart` (state class; clock computed at build ~line 269)

**Interfaces:**
- Behavior (PWA `attendance/page.tsx:66-71`): the header clock re-renders every second.

- [ ] **Step 1: Add a periodic timer.** `import 'dart:async';` at the top. In the screen's `State` class:

```dart
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // ... existing init code unchanged ...
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
```

(If `initState`/`dispose` already exist, extend them instead of adding duplicates.)

- [ ] **Step 2: Verify** — `flutter analyze` clean.
- [ ] **Step 3: Commit** — `feat(attendance): live-ticking header clock`

---

## Self-Review Notes

- Spec coverage: all 7 customer-domain findings (Tasks 2-9), inventory browse (Tasks 10-13), attendance clock (Task 14), `putJson` prerequisite (Task 1). Deliberate exclusions listed under Global Constraints.
- Type consistency: `Opt`/`InventoryFilters`/`showInventoryFilterSheet`/`showCompoundPickerSheet`/`CompoundOption`/`putJson` names match across tasks.
- Ordering: 1 → 2 → 3/4 → 5 → 6/7 → 8 → 9 (customers file edited sequentially); 10 → 11 → 12 → 13 (inventory); 14 independent.
