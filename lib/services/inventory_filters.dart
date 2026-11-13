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
    if (buildingStatus.isNotEmpty) {
      out['buildingStatus'] = buildingStatus.join(',');
    }
    if (amenities.isNotEmpty) {
      out['amenities'] = amenities.join(',');
    }
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
