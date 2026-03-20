import 'package:equatable/equatable.dart';

class Branch extends Equatable {
  final String id;
  final String nameEn;
  final String nameAr;
  final String areaEn;
  final String areaAr;
  final String mapUrl;

  const Branch({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.areaEn,
    required this.areaAr,
    required this.mapUrl,
  });

  @override
  List<Object?> get props => [id, nameEn, nameAr, areaEn, areaAr, mapUrl];
}

final List<Branch> appBranches = [
  const Branch(
    id: 'rehab',
    nameEn: 'Rehab Branch',
    nameAr: 'فرع الرحاب',
    areaEn: 'New Cairo',
    areaAr: 'القاهرة الجديدة',
    mapUrl: 'https://maps.app.goo.gl/NAZnJfaY99HrSBYJ9',
  ),
  const Branch(
    id: 'mahalla1',
    nameEn: 'Mahalla Branch 1',
    nameAr: 'فرع المحلة 1',
    areaEn: 'El Mahalla El Kubra',
    areaAr: 'المحلة الكبرى',
    mapUrl: 'https://maps.app.goo.gl/rRnhstcoyHXMKyaG8',
  ),
  const Branch(
    id: 'mahalla2',
    nameEn: 'Mahalla Branch 2',
    nameAr: 'فرع المحلة 2',
    areaEn: 'El Mahalla El Kubra',
    areaAr: 'المحلة الكبرى',
    mapUrl: 'https://maps.app.goo.gl/kTpifykykRoc9DRFA',
  ),
];
