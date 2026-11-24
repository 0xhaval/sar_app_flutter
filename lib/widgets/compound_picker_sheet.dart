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
                    backgroundColor: const Color(0xFF111317),
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
