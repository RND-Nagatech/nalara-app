import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import '../../../shared/errors/app_failure.dart';
import '../../../shared/network/api_client.dart';
import '../../../utils/constants.dart';
import '../domain/branding_logo.dart';

class FileSelectorBrandingLogoPicker implements BrandingLogoPicker {
  @override
  Future<PickedBrandingLogo?> pick() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Logo PNG atau JPEG',
          extensions: ['png', 'jpg', 'jpeg'],
          uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
          mimeTypes: ['image/png', 'image/jpeg'],
        ),
      ],
    );
    if (file == null) return null;
    if (await file.length() > 2 * 1024 * 1024) {
      throw const AppFailure(
        'Ukuran logo maksimal 2 MB. Pilih gambar yang lebih kecil.',
        code: 'PAYLOAD_TOO_LARGE',
      );
    }
    final bytes = await file.readAsBytes();
    final png =
        bytes.length >= 8 &&
        base64Encode(bytes.sublist(0, 8)) == 'iVBORw0KGgo=';
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (!png && !jpeg) {
      throw const AppFailure('Pilih gambar PNG atau JPEG yang valid.');
    }
    return PickedBrandingLogo(
      mimeType: png ? 'image/png' : 'image/jpeg',
      bytes: bytes,
    );
  }
}

BrandingLogo? decodeBrandingLogo(Map<String, dynamic> data) {
  const invalid = AppFailure(
    'Respons logo belum sesuai. Muat ulang halaman identitas laporan.',
    code: 'INVALID_RESPONSE',
  );
  if (!data.containsKey('logo')) throw invalid;
  final raw = data['logo'];
  if (raw == null) return null;
  if (raw is! Map ||
      raw['version'] is! String ||
      (raw['version'] as String).isEmpty ||
      raw['mimeType'] != 'image/png' ||
      raw['contentBase64'] is! String) {
    throw invalid;
  }
  try {
    final bytes = base64Decode(raw['contentBase64'] as String);
    if (bytes.length < 8 ||
        bytes.length > 2 * 1024 * 1024 ||
        base64Encode(bytes.sublist(0, 8)) != 'iVBORw0KGgo=') {
      throw invalid;
    }
    return BrandingLogo(version: raw['version'] as String, bytes: bytes);
  } on FormatException {
    throw invalid;
  }
}

class BrandingLogoRepositoryImpl implements BrandingLogoRepository {
  final ApiClient api;
  final int _session;
  BrandingLogoRepositoryImpl(this.api)
    : _session = api.tokens.sessionGeneration;
  @override
  Future<BrandingLogo?> read() async => decodeBrandingLogo(
    Map<String, dynamic>.from(
      await api.request(
        'GET',
        ApiConstants.tutorBrandingLogo,
        expectedSessionGeneration: _session,
      ),
    ),
  );
  @override
  Future<BrandingLogo> upload(PickedBrandingLogo file) async {
    final logo = decodeBrandingLogo(
      await api.uploadFile(
        ApiConstants.tutorBrandingLogo,
        file.bytes,
        filename: file.mimeType == 'image/png' ? 'logo.png' : 'logo.jpg',
        mimeType: file.mimeType,
        expectedSessionGeneration: _session,
      ),
    );
    if (logo == null) {
      throw const AppFailure(
        'Logo belum tersimpan. Muat ulang lalu coba lagi.',
        code: 'INVALID_RESPONSE',
      );
    }
    return logo;
  }

  @override
  Future<void> remove() async {
    final data = await api.delete(
      ApiConstants.tutorBrandingLogo,
      expectedSessionGeneration: _session,
    );
    if (!data.containsKey('logo') || data['logo'] != null) {
      throw const AppFailure(
        'Penghapusan logo belum terkonfirmasi. Muat ulang halaman.',
        code: 'INVALID_RESPONSE',
      );
    }
  }
}
