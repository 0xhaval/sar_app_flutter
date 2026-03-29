import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../widgets/animated_bottom_sheet.dart';
import '../widgets/staggered_column.dart';
import '../services/api_service.dart';

class ApartmentsScreen extends StatefulWidget {
  const ApartmentsScreen({super.key});

  @override
  State<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends State<ApartmentsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _apartments = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.call('get_employee_apartments');
      if (!mounted) return;
      setState(() {
        _apartments = List<Map<String, dynamic>>.from(data['apartments'] ?? []);
        _stats = Map<String, dynamic>.from(data['stats'] ?? {});
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'vacant': return const Color(0xFFDCFCE7);
      case 'occupied': return const Color(0xFFD9DAD9);
      default: return const Color(0xFFFFF7ED);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'vacant': return const Color(0xFF15803D);
      case 'occupied': return const Color(0xFF284A63);
      default: return const Color(0xFFC2410C);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'vacant': return 'متاحة';
      case 'occupied': return 'مؤجرة';
      default: return 'صيانة';
    }
  }

  Future<void> _handleDelete(String name) async {
    try {
      await ApiService.call('delete_apartment', params: {'name': name});
      Fluttertoast.showToast(msg: 'تم حذف الشقة بنجاح!');
      _loadData();
    } catch (e) {
      Fluttertoast.showToast(msg: 'خطأ: $e');
    }
  }

  void _showAddApartmentDialog() async {
    // Load residential compounds for dropdown
    List<Map<String, dynamic>> compounds = [];
    String? compoundsError;
    try {
      compounds = await ApiService.getList(
        'Residential Compound',
        fields: ['name', 'compound_name'],
        orderBy: 'compound_name asc',
      );
    } catch (e) {
      compoundsError = e.toString();
    }

    if (!mounted) return;

    final apartmentNumberController = TextEditingController();
    final buildingNumberController = TextEditingController();
    final floorNumberController = TextEditingController();
    final bedroomsController = TextEditingController();
    final bathroomsController = TextEditingController();
    final livingRoomsController = TextEditingController();
    final areaController = TextEditingController();
    final rentController = TextEditingController();
    final notesController = TextEditingController();

    String? selectedCompound;
    String? selectedApartmentType;
    String selectedStatus = 'Vacant';
    String? selectedFurnishing;
    String? selectedViewType;
    bool hasBalcony = false;
    bool hasMaidRoom = false;
    List<File> selectedImages = [];

    final apartmentTypes = ['Studio', '1BR', '2BR', '3BR', '4BR', 'Penthouse', 'Duplex', 'Villa'];
    final statusOptions = ['Vacant', 'Occupied', 'Under Maintenance', 'Reserved', 'Sold'];
    final furnishingOptions = ['Unfurnished', 'Semi-Furnished', 'Fully Furnished'];
    final viewOptions = ['Street', 'Garden', 'Pool', 'Sea', 'City', 'Internal'];

    final statusLabels = {
      'Vacant': 'شاغرة',
      'Occupied': 'مشغولة',
      'Under Maintenance': 'تحت الصيانة',
      'Reserved': 'محجوزة',
      'Sold': 'مباعة',
    };
    final furnishingLabels = {
      'Unfurnished': 'بدون أثاث',
      'Semi-Furnished': 'مفروشة جزئياً',
      'Fully Furnished': 'مفروشة بالكامل',
    };
    final viewLabels = {
      'Street': 'شارع',
      'Garden': 'حديقة',
      'Pool': 'مسبح',
      'Sea': 'بحر',
      'City': 'مدينة',
      'Internal': 'داخلي',
    };

    showAnimatedBottomSheet(
      context: context,
      title: 'إضافة شقة جديدة',
      subtitle: 'املأ البيانات لإضافة شقة جديدة',
      children: [
        StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Required Fields ---
                const Text('المجمع السكني *', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                const SizedBox(height: 8),
                if (compoundsError != null)
                  Text('خطأ في تحميل المجمعات: $compoundsError', style: const TextStyle(color: Colors.red, fontSize: 13))
                else if (compounds.isEmpty)
                  const Text('لا توجد مجمعات سكنية', style: TextStyle(color: Colors.orange, fontSize: 13))
                else
                  DropdownButtonFormField<String>(
                    value: selectedCompound,
                    hint: const Text('اختر المجمع السكني'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: compounds.map((c) => DropdownMenuItem<String>(
                      value: (c['name'] ?? '').toString(),
                      child: Text((c['compound_name'] ?? c['name'] ?? '').toString()),
                    )).toList(),
                    onChanged: (v) => setSheetState(() => selectedCompound = v),
                  ),
                const SizedBox(height: 12),
                _buildField('رقم الشقة *', apartmentNumberController, 'مثال: A-101'),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('معلومات المبنى', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildField('رقم المبنى', buildingNumberController, 'B1')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('رقم الطابق', floorNumberController, '3', isNumber: true)),
                ]),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('مواصفات الوحدة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),

                const Text('نوع الشقة', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedApartmentType,
                  hint: const Text('اختر النوع'),
                  isExpanded: true,
                  items: apartmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setSheetState(() => selectedApartmentType = v),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildField('غرف النوم', bedroomsController, '3', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('الحمامات', bathroomsController, '2', isNumber: true)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildField('غرف المعيشة', livingRoomsController, '1', isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('المساحة (م²)', areaController, '150', isNumber: true)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('بلكونة', style: TextStyle(fontSize: 14)),
                      value: hasBalcony,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setSheetState(() => hasBalcony = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('غرفة خادمة', style: TextStyle(fontSize: 14)),
                      value: hasMaidRoom,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setSheetState(() => hasMaidRoom = v),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('حالة التأثيث', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedFurnishing,
                          hint: const Text('اختر'),
                          isExpanded: true,
                          items: furnishingOptions.map((f) => DropdownMenuItem(value: f, child: Text(furnishingLabels[f] ?? f))).toList(),
                          onChanged: (v) => setSheetState(() => selectedFurnishing = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الإطلالة', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedViewType,
                          hint: const Text('اختر'),
                          isExpanded: true,
                          items: viewOptions.map((v) => DropdownMenuItem(value: v, child: Text(viewLabels[v] ?? v))).toList(),
                          onChanged: (v) => setSheetState(() => selectedViewType = v),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('الحالة والمالية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الحالة', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(statusLabels[s] ?? s))).toList(),
                          onChanged: (v) => setSheetState(() => selectedStatus = v ?? 'Vacant'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField('الإيجار الشهري', rentController, '750000', isNumber: true)),
                ]),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(controller: notesController, maxLines: 3, decoration: const InputDecoration(hintText: 'أدخل ملاحظات...')),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('صور الشقة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...selectedImages.asMap().entries.map((entry) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(entry.value, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedImages.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )),
                    GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
                        if (picked.isNotEmpty) {
                          setSheetState(() {
                            selectedImages.addAll(picked.map((p) => File(p.path)));
                          });
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 24, color: Color(0xFF9CA3AF)),
                            SizedBox(height: 4),
                            Text('إضافة صور', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedCompound == null || apartmentNumberController.text.isEmpty) {
                        Fluttertoast.showToast(msg: 'يرجى ملء المجمع السكني ورقم الشقة');
                        return;
                      }
                      try {
                        // Upload all selected images
                        List<Map<String, String>> uploadedDocs = [];
                        for (final img in selectedImages) {
                          final url = await ApiService.uploadFile(img);
                          uploadedDocs.add({'document_name': 'Photo', 'document_type': 'Photo', 'file': url});
                        }

                        final params = <String, dynamic>{
                          'residential_compound': selectedCompound,
                          'apartment_number': apartmentNumberController.text,
                          'building_number': buildingNumberController.text,
                          'floor_number': int.tryParse(floorNumberController.text) ?? 0,
                          'apartment_type': selectedApartmentType,
                          'number_of_bedrooms': int.tryParse(bedroomsController.text) ?? 0,
                          'number_of_bathrooms': int.tryParse(bathroomsController.text) ?? 0,
                          'number_of_living_rooms': int.tryParse(livingRoomsController.text) ?? 0,
                          'has_balcony': hasBalcony ? 1 : 0,
                          'has_maid_room': hasMaidRoom ? 1 : 0,
                          'total_area': double.tryParse(areaController.text) ?? 0,
                          'furnishing_status': selectedFurnishing,
                          'view_type': selectedViewType,
                          'status': selectedStatus,
                          'monthly_rent': double.tryParse(rentController.text) ?? 0,
                          'notes': notesController.text,
                        };

                        if (uploadedDocs.isNotEmpty) {
                          params['apartment_documents'] = jsonEncode(uploadedDocs);
                        }

                        await ApiService.call('create_apartment', params: params);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Fluttertoast.showToast(msg: 'تم إضافة الشقة بنجاح!');
                        _loadData();
                      } catch (e) {
                        Fluttertoast.showToast(msg: 'خطأ: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('إضافة الشقة', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final total = (_stats['total'] as num?)?.toInt() ?? 0;
    final available = (_stats['available'] as num?)?.toInt() ?? 0;
    final rented = (_stats['rented'] as num?)?.toInt() ?? 0;
    final revenue = (_stats['total_revenue'] as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [Color(0xFF16A34A), Color(0xFF0D9488)]),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/logo.png', height: 28, color: Colors.white),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إدارة الشقق', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
                    ElevatedButton.icon(
                      onPressed: _showAddApartmentDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة شقة'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF16A34A), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _buildStatCard('$total', 'إجمالي الشقق'),
                      _buildStatCard('$available', 'شقق متاحة'),
                      _buildStatCard('$rented', 'شقق مؤجرة'),
                      _buildStatCard('${numberFormat.format(revenue.toInt())} د.ع', 'الإيرادات الشهرية'),
                    ],
                  ),
              ],
            ),
          ),

          // Apartments List
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                : StaggeredColumn(
                    children: [
                      Text('شققي (${_apartments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      if (_apartments.isEmpty)
                        const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('لا توجد شقق', style: TextStyle(color: Color(0xFF9CA3AF)))))
                      else
                        ..._apartments.map((apt) => _buildApartmentCard(apt, numberFormat)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildApartmentCard(Map<String, dynamic> apartment, NumberFormat numberFormat) {
    final status = apartment['status'] ?? 'vacant';
    final price = (apartment['price'] as num?)?.toInt() ?? 0;
    final bedrooms = (apartment['bedrooms'] as num?)?.toInt() ?? 0;
    final bathrooms = (apartment['bathrooms'] as num?)?.toInt() ?? 0;
    final area = (apartment['area'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(apartment['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on, size: 16, color: Color(0xFF353535)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(apartment['location'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF353535)))),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: _getStatusBgColor(status), borderRadius: BorderRadius.circular(20)),
                  child: Text(_getStatusText(status), style: TextStyle(fontSize: 12, color: _getStatusTextColor(status))),
                ),
              ],
            ),
            if ((apartment['description'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(apartment['description'], style: const TextStyle(fontSize: 14, color: Color(0xFF353535))),
            ],
            const SizedBox(height: 12),
            Row(children: [
              _buildInfoTile(Icons.monetization_on, numberFormat.format(price), 'د.ع/شهر', const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              _buildInfoTile(Icons.bed, '$bedrooms', 'غرف', const Color(0xFF284A63)),
              const SizedBox(width: 8),
              _buildInfoTile(Icons.bathtub, '$bathrooms', 'حمامات', const Color(0xFF9333EA)),
              const SizedBox(width: 8),
              _buildInfoTile(Icons.crop_square, '$area', 'م²', const Color(0xFFEA580C)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDelete(apartment['name']),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('حذف'),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value, String label, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
      ),
    );
  }
}
