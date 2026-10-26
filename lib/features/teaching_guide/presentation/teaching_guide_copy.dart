import '../domain/teaching_guide.dart';

extension TeachingGuideCopy on TeachingGuideStep {
  String get title => switch (this) {
    TeachingGuideStep.subject => 'Tambah bidang belajar',
    TeachingGuideStep.student => 'Tambah siswa pertama',
    TeachingGuideStep.schedule => 'Buat jadwal pertama',
    TeachingGuideStep.target => 'Buat target belajar',
  };

  String get description => switch (this) {
    TeachingGuideStep.subject =>
      'Isi nama bidang yang Anda ajarkan, seperti Matematika, Piano, atau Bahasa Inggris.',
    TeachingGuideStep.student =>
      'Masukkan nama siswa, kelas atau tingkat, dan catatan jika diperlukan. Pilih keluarga yang sesuai apabila sudah tersedia.',
    TeachingGuideStep.schedule =>
      'Pilih siswa satu per satu atau dari Grup siswa, lalu isi bidang belajar serta tanggal dan jam. Zona waktu mengikuti Pengaturan; ketuk Ubah bila perlu. Untuk jadwal rutin, aktifkan Ulangi setiap minggu dan pilih hari serta batas pengulangannya.',
    TeachingGuideStep.target =>
      'Isi nama rencana, pilih siswa dan bidang belajar, lalu tentukan periode, target, dan indikator hasil belajarnya.',
  };

  String route({required bool completed}) => switch (this) {
    TeachingGuideStep.subject =>
      completed ? '/teacher/subjects' : '/teacher/subjects/new',
    TeachingGuideStep.student =>
      completed ? '/teacher/students' : '/teacher/students/new',
    TeachingGuideStep.schedule =>
      completed ? '/teacher/schedule' : '/teacher/schedule/new',
    TeachingGuideStep.target =>
      completed ? '/teacher/targets' : '/teacher/targets/new',
  };
}
