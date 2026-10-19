class BrandingLogo {
  final String version;
  final List<int> bytes;
  BrandingLogo({required this.version, required List<int> bytes})
    : bytes = List.unmodifiable(bytes);
}

class PickedBrandingLogo {
  final String mimeType;
  final List<int> bytes;
  PickedBrandingLogo({required this.mimeType, required List<int> bytes})
    : bytes = List.unmodifiable(bytes);
}

abstract interface class BrandingLogoPicker {
  Future<PickedBrandingLogo?> pick();
}

// Each instance is bound to the teacher session active when the editor opens.
abstract interface class BrandingLogoRepository {
  Future<BrandingLogo?> read();
  Future<BrandingLogo> upload(PickedBrandingLogo file);
  Future<void> remove();
}
