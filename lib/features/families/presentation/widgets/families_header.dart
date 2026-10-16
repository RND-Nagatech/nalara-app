import 'package:flutter/material.dart';
import 'families_style.dart';

class FamiliesHeader extends StatelessWidget {
  final TextEditingController search;
  final bool loading;
  final VoidCallback onBack, onRefresh, onClear;
  final ValueChanged<String> onChanged, onSubmitted;

  const FamiliesHeader({
    super.key,
    required this.search,
    required this.loading,
    required this.onBack,
    required this.onRefresh,
    required this.onClear,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('families-back'),
              tooltip: 'Kembali',
              onPressed: onBack,
              style: IconButton.styleFrom(
                foregroundColor: FamiliesStyle.green,
                fixedSize: const Size(40, 40),
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 23),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Orang Tua & Keluarga', style: FamiliesStyle.title),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('families-refresh'),
              tooltip: 'Muat ulang keluarga',
              onPressed: loading ? null : onRefresh,
              style: IconButton.styleFrom(
                foregroundColor: FamiliesStyle.green,
                fixedSize: const Size(40, 40),
              ),
              icon: loading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: FamiliesStyle.green,
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
            key: const ValueKey('families-search'),
            controller: search,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontFamily: 'NalaraInter',
              fontSize: 14,
              color: FamiliesStyle.ink,
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: 'Cari Orang Tua atau nama keluarga',
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
                      key: const ValueKey('families-clear-search'),
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
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: FamiliesStyle.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: FamiliesStyle.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: FamiliesStyle.green,
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
