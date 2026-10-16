import 'package:flutter/material.dart';
import '../../../auth/domain/entities/teacher.dart';
import 'profile_style.dart';

class TeacherProfileCard extends StatelessWidget {
  final Teacher teacher;

  const TeacherProfileCard({super.key, required this.teacher});

  String get _initials {
    final words = teacher.name.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) return '';
    return '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('profile-identity'),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFDDE6D7)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0F4E9), Color(0xFFE4EDDF)],
      ),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -42,
          top: -64,
          child: ExcludeSemantics(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 25),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'AKUN NALARA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 10,
                  height: 1.4,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: ProfileStyle.green,
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    key: const ValueKey('profile-avatar'),
                    constraints: const BoxConstraints(
                      minWidth: 84,
                      minHeight: 84,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ProfileStyle.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14214E3B),
                          blurRadius: 16,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _initials.isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            size: 32,
                            color: Colors.white,
                          )
                        : Text(
                            _initials,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'NalaraLora',
                              fontSize: 28,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                teacher.name.trim().isEmpty
                    ? 'Nama belum tersedia'
                    : teacher.name,
                key: const ValueKey('profile-name'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NalaraLora',
                  fontSize: 25,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: ProfileStyle.ink,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Guru',
                    style: ProfileStyle.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ProfileStyle.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
