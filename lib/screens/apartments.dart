import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../widgets/animated_bottom_sheet.dart';
import '../widgets/staggered_column.dart';

class _Apartment {
  final String id;
  final String title;
  final String location;
  final int price;
  final int bedrooms;
  final int bathrooms;
  final int area;
  final String description;
  final String status;
  final String createdAt;

  _Apartment({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.description,
    required this.status,
    required this.createdAt,
  });
}

class ApartmentsScreen extends StatefulWidget {
  const ApartmentsScreen({super.key});

  @override
  State<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends State<ApartmentsScreen> {
  final List<_Apartment> _apartments = [
    _Apartment(
      id: '1', title: 'شقة فاخرة في الكرادة', location: 'الكرادة، بغداد',
      price: 750000, bedrooms: 3, bathrooms: 2, area: 150,
      description: 'شقة حديثة ومجهزة بالكامل مع إطلالة رائعة على نهر دجلة',
      status: 'available', createdAt: '2026-03-15',
    ),
    _Apartment(
      id: '2', title: 'شقة عائلية في المنصور', location: 'المنصور، بغداد',
      price: 900000, bedrooms: 4, bathrooms: 3, area: 200,
      description: 'شقة واسعة مثالية للعائلات الكبيرة في منطقة راقية',
      status: 'rented', createdAt: '2026-03-10',
    ),
    _Apartment(
      id: '3', title: 'استوديو في الجادرية', location: 'الجادرية، بغداد',
      price: 400000, bedrooms: 1, bathrooms: 1, area: 60,
      description: 'استوديو مريح مناسب للعزاب قريب من الجامعة',
      status: 'available', createdAt: '2026-03-08',
    ),
  ];

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFFDCFCE7);
      case 'rented': return const Color(0xFFDBEAFE);
      default: return const Color(0xFFFFF7ED);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'available': return const Color(0xFF15803D);
      case 'rented': return const Color(0xFF1D4ED8);
      default: return const Color(0xFFC2410C);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available': return 'متاحة';
      case 'rented': return 'مؤجرة';
      default: return 'صيانة';
    }
  }

  void _handleDelete(String id) {
    setState(() {
      _apartments.removeWhere((apt) => apt.id == id);
    });
    Fluttertoast.showToast(msg: 'تم حذف الشقة بنجاح!');
  }

  void _showAddApartmentDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final priceController = TextEditingController();
    final areaController = TextEditingController();
    final bedroomsController = TextEditingController();
    final bathroomsController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedStatus = 'available';

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
                _buildField('عنوان الشقة', titleController, 'مثال: شقة فاخرة في الكرادة'),
                const SizedBox(height: 12),
                _buildField('الموقع', locationController, 'مثال: الكرادة، بغداد'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('السعر (شهري بالدينار)', priceController, '750000', isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('المساحة (م²)', areaController, '150', isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildField('عدد الغرف', bedroomsController, '3', isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('عدد الحمامات', bathroomsController, '2', isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('الحالة', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text('متاحة')),
                    DropdownMenuItem(value: 'rented', child: Text('مؤجرة')),
                    DropdownMenuItem(value: 'maintenance', child: Text('صيانة')),
                  ],
                  onChanged: (v) => setSheetState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 12),
                const Text('الوصف', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'أدخل وصف الشقة...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty && locationController.text.isNotEmpty) {
                        setState(() {
                          _apartments.insert(0, _Apartment(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text,
                            location: locationController.text,
                            price: int.tryParse(priceController.text) ?? 0,
                            bedrooms: int.tryParse(bedroomsController.text) ?? 0,
                            bathrooms: int.tryParse(bathroomsController.text) ?? 0,
                            area: int.tryParse(areaController.text) ?? 0,
                            description: descriptionController.text,
                            status: selectedStatus,
                            createdAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          ));
                        });
                        Navigator.pop(context);
                        Fluttertoast.showToast(msg: 'تم إضافة الشقة بنجاح!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalApartments = _apartments.length;
    final availableApartments = _apartments.where((a) => a.status == 'available').length;
    final rentedApartments = _apartments.where((a) => a.status == 'rented').length;
    final totalRevenue = _apartments.where((a) => a.status == 'rented').fold<int>(0, (sum, a) => sum + a.price);
    final numberFormat = NumberFormat('#,###');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF16A34A), Color(0xFF0D9488)],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إدارة الشقق', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
                    ElevatedButton.icon(
                      onPressed: _showAddApartmentDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة شقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    _buildStatCard('$totalApartments', 'إجمالي الشقق'),
                    _buildStatCard('$availableApartments', 'شقق متاحة'),
                    _buildStatCard('$rentedApartments', 'شقق مؤجرة'),
                    _buildStatCard('${numberFormat.format(totalRevenue)} د.ع', 'الإيرادات الشهرية'),
                  ],
                ),
              ],
            ),
          ),

          // Apartments List
          Padding(
            padding: const EdgeInsets.all(16),
            child: StaggeredColumn(
              children: [
                Text('شققي (${_apartments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ..._apartments.map((apartment) => _buildApartmentCard(apartment, numberFormat)),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
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

  Widget _buildApartmentCard(_Apartment apartment, NumberFormat numberFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(apartment.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(apartment.location, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(apartment.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(apartment.status),
                    style: TextStyle(fontSize: 12, color: _getStatusTextColor(apartment.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(apartment.description, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 12),

            // Info Grid
            Row(
              children: [
                _buildInfoTile(Icons.monetization_on, numberFormat.format(apartment.price), 'د.ع/شهر', const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                _buildInfoTile(Icons.bed, '${apartment.bedrooms}', 'غرف', const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _buildInfoTile(Icons.bathtub, '${apartment.bathrooms}', 'حمامات', const Color(0xFF9333EA)),
                const SizedBox(width: 8),
                _buildInfoTile(Icons.crop_square, '${apartment.area}', 'م²', const Color(0xFFEA580C)),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDelete(apartment.id),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('حذف'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تاريخ الإضافة: ${DateFormat('d/M/yyyy', 'ar').format(DateTime.parse(apartment.createdAt))}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}
