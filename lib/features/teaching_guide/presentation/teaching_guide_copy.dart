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
      'Tentukan yang Anda ajarkan, seperti Matematika, Piano, atau Bahasa Inggris.',
    TeachingGuideStep.student =>
      'Simpan data siswa yang akan mengikuti kegiatan belajar.',
    TeachingGuideStep.schedule =>
      'Pilih siswa, bidang belajar, dan waktu pertemuannya.',
    TeachingGuideStep.target =>
      'Tentukan hasil belajar yang ingin dicapai bersama siswa.',
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
