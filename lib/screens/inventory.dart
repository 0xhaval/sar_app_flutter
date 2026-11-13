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

    final amenities = kAmenities.where((a) => apt[a.value] == true).toList();

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
