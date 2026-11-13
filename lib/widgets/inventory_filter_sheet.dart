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
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
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
                      _range(
                          'القسط الشهري', 'minInstallment', 'maxInstallment'),
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
