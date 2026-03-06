String pickName({required String en, String? ar, required bool isArabic}) {
  if (isArabic && ar != null && ar.isNotEmpty) {
    return ar;
  }
  return en;
}
