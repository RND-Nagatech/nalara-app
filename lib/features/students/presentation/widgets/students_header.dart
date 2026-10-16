import 'package:flutter/material.dart';
import 'students_style.dart';

class StudentsHeader extends StatelessWidget {
  final TextEditingController search;
  final bool loading;
  final VoidCallback onRefresh, onClear;
  final ValueChanged<String> onChanged, onSubmitted;
  final bool readOnly;
  const StudentsHeader({
    super.key,
    required this.search,
    required this.loading,
    required this.onRefresh,
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
    this.readOnly = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Siswa', style: StudentsStyle.title),
                  const SizedBox(height: 5),
                  Text(
                    readOnly
                        ? 'Pantau pembelajaran anak Anda'
                        : 'Kelola data siswa Anda',
                    style: StudentsStyle.body,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              key: const ValueKey('students-refresh'),
              onPressed: loading ? null : onRefresh,
              tooltip: 'Muat ulang siswa',
              style: IconButton.styleFrom(
                foregroundColor: StudentsStyle.green,
                fixedSize: const Size(40, 40),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StudentsStyle.green,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: search,
          builder: (context, value, _) => TextField(
            key: const ValueKey('students-search'),
            controller: search,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 14,
              color: StudentsStyle.ink,
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: 'Cari siswa',
              hintStyle: const TextStyle(
                color: Color(0xFF939693),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10, right: 6),
                child: Icon(
                  Icons.search_rounded,
                  size: 25,
                  color: Color(0xFF707674),
                ),
              ),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      key: const ValueKey('students-clear-search'),
                      onPressed: onClear,
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close_rounded, size: 21),
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: StudentsStyle.green,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
