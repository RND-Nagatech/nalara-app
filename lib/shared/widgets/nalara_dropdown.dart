import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A presentation-only choice. Use stable domain IDs as values, not labels.
class NalaraDropdownOption<T extends Object> {
  final T value;
  final String label;
  final String searchText;
  final String subtitle;
  final Widget? leading;
  final bool enabled;
  const NalaraDropdownOption({
    required this.value,
    required this.label,
    this.searchText = '',
    this.subtitle = '',
    this.leading,
    this.enabled = true,
  });
}

/// Shared searchable form field. New dropdown UIs should use this component.
///
/// The panel shows at most four options (fewer if the keyboard/viewport needs
/// room). Filtering never fetches data or modifies the caller's option list.
class NalaraDropdown<T extends Object> extends FormField<T> {
  static const maxVisibleOptions = 4;
  final List<NalaraDropdownOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final InputDecoration decoration;
  final String hint, searchHint;
  final String? menuTitle;

  /// Optional selected content; selection, focus and validation stay shared.
  final Widget Function(BuildContext, NalaraDropdownOption<T>?)?
  selectedBuilder;

  NalaraDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.decoration = const InputDecoration(),
    this.hint = 'Pilih opsi',
    this.searchHint = 'Cari pilihan...',
    this.menuTitle,
    this.selectedBuilder,
    bool enabled = true,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
  }) : assert(
         options.map((option) => option.value).toSet().length == options.length,
       ),
       super(
         initialValue: value,
         enabled: enabled && onChanged != null,
         builder: (state) => (state as _NalaraDropdownState<T>)._field(),
       );

  @override
  FormFieldState<T> createState() => _NalaraDropdownState<T>();
}

class _NalaraDropdownState<T extends Object> extends FormFieldState<T> {
  final _focus = FocusNode();
  bool _open = false;
  @override
  NalaraDropdown<T> get widget => super.widget as NalaraDropdown<T>;

  @override
  void didUpdateWidget(covariant NalaraDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) setValue(widget.value);
  }

  @override
  void reset() {
    super.reset();
    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_open || !widget.enabled) return;
    final originalValue = widget.value;
    final snapshot = List<NalaraDropdownOption<T>>.unmodifiable(widget.options);
    FocusScope.of(context).unfocus();
    setState(() => _open = true);
    T? chosen;
    try {
      chosen = await showDialog<T>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .16),
        builder: (_) => _DropdownPanel<T>(
          title:
              widget.menuTitle ?? widget.decoration.labelText ?? 'Pilih opsi',
          searchHint: widget.searchHint,
          options: snapshot,
          selected: value,
        ),
      );
    } finally {
      if (mounted) setState(() => _open = false);
    }
    if (!mounted) return;
    // Ignore a late choice after a scope/value change, disabling, or removal.
    if (chosen != null &&
        widget.enabled &&
        widget.value == originalValue &&
        widget.options.any(
          (option) => option.value == chosen && option.enabled,
        )) {
      didChange(chosen);
      widget.onChanged?.call(chosen);
    }
    if (mounted && widget.enabled) _focus.requestFocus();
  }

  Widget _field() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    NalaraDropdownOption<T>? selected;
    for (final option in widget.options) {
      if (option.value == value) {
        selected = option;
        break;
      }
    }
    final label =
        selected?.label ?? (value == null ? widget.hint : 'Pilihan tersimpan');
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.decoration.labelText ?? widget.menuTitle ?? 'Pilihan',
      value: label,
      hint: errorText ?? widget.decoration.errorText,
      onTap: widget.enabled ? _choose : null,
      child: InkWell(
        focusNode: _focus,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(12),
        onFocusChange: (_) {
          if (mounted) setState(() {});
        },
        onTap: widget.enabled ? _choose : null,
        child: ExcludeSemantics(
          child: InputDecorator(
            isFocused: _open || _focus.hasFocus,
            isEmpty: value == null,
            decoration: widget.decoration
                .applyDefaults(theme.inputDecorationTheme)
                .copyWith(
                  enabled: widget.enabled,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  errorText: errorText ?? widget.decoration.errorText,
                  errorMaxLines: 3,
                  suffixIcon: Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.enabled
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                ),
            child:
                widget.selectedBuilder?.call(context, selected) ??
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'NalaraInter',
                    fontSize: 14,
                    height: 1.4,
                    color: widget.enabled && value != null
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _DropdownPanel<T extends Object> extends StatefulWidget {
  final List<NalaraDropdownOption<T>> options;
  final T? selected;
  final String title, searchHint;
  const _DropdownPanel({
    required this.options,
    required this.selected,
    required this.title,
    required this.searchHint,
  });
  @override
  State<_DropdownPanel<T>> createState() => _DropdownPanelState<T>();
}

class _DropdownPanelState<T extends Object> extends State<_DropdownPanel<T>> {
  final _search = TextEditingController(), _scroll = ScrollController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() => _query = query.trim().toLowerCase());
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final words = _query.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final matches = widget.options
        .where((option) {
          final text = '${option.label} ${option.searchText} ${option.subtitle}'
              .toLowerCase();
          return words.every(text.contains);
        })
        .toList(growable: false);
    final hasSubtitles = matches.any((option) => option.subtitle.isNotEmpty);
    final rowHeight = math.max(
      hasSubtitles ? 72.0 : 52.0,
      MediaQuery.textScalerOf(context).scale(14) * (hasSubtitles ? 4 : 2.8) +
          12,
    );
    return Dialog(
      key: const ValueKey('nalara-dropdown-panel'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      backgroundColor: const Color(0xFFFBF8F0),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup pilihan',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              TextField(
                key: const ValueKey('nalara-dropdown-search'),
                controller: _search,
                onChanged: _filter,
                style: const TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 14,
                  height: 1.4,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _filter,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _search.clear();
                            _filter('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                fit: FlexFit.loose,
                child: matches.isEmpty
                    ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 24,
                          ),
                          child: Text(
                            widget.options.isEmpty
                                ? 'Belum ada pilihan tersedia.'
                                : 'Tidak ada pilihan yang sesuai pencarian.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height:
                            math.min(
                              NalaraDropdown.maxVisibleOptions,
                              matches.length,
                            ) *
                            rowHeight,
                        child: Scrollbar(
                          controller: _scroll,
                          thumbVisibility:
                              matches.length > NalaraDropdown.maxVisibleOptions,
                          child: ListView.builder(
                            key: const ValueKey('nalara-dropdown-options'),
                            controller: _scroll,
                            padding: EdgeInsets.zero,
                            itemExtent: rowHeight,
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final option = matches[index];
                              final selected = option.value == widget.selected;
                              return Semantics(
                                selected: selected,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Material(
                                    color: selected
                                        ? colors.primary.withValues(alpha: .09)
                                        : Colors.white.withValues(alpha: .65),
                                    borderRadius: BorderRadius.circular(10),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: ValueKey(option.value),
                                      onTap: option.enabled
                                          ? () => Navigator.of(
                                              context,
                                            ).pop(option.value)
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            if (option.leading != null) ...[
                                              option.leading!,
                                              const SizedBox(width: 12),
                                            ],
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    option.label,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontFamily: 'NalaraInter',
                                                      fontSize: 14,
                                                      height: 1.4,
                                                      fontWeight: selected
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      color: option.enabled
                                                          ? colors.onSurface
                                                          : colors
                                                                .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  if (option
                                                      .subtitle
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      option.subtitle,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'NalaraInter',
                                                        fontSize: 12,
                                                        height: 1.4,
                                                        color: colors
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (selected) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: colors.primary,
                                                size: 20,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared searchable multi-select form field.
///
/// It uses the same branded panel as [NalaraDropdown], but keeps the panel
/// open while options are checked so callers can submit a stable set of IDs.
class NalaraMultiDropdown<T extends Object> extends FormField<Set<T>> {
  static const maxVisibleOptions = NalaraDropdown.maxVisibleOptions;
  final List<NalaraDropdownOption<T>> options;
  final ValueChanged<Set<T>>? onChanged;
  final Set<T> selectedValues;
  final InputDecoration decoration;
  final String hint, searchHint;
  final String? menuTitle;

  NalaraMultiDropdown({
    super.key,
    required this.options,
    required this.onChanged,
    this.selectedValues = const {},
    this.decoration = const InputDecoration(),
    this.hint = 'Pilih opsi',
    this.searchHint = 'Cari pilihan...',
    this.menuTitle,
    bool enabled = true,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
  }) : assert(
         options.map((option) => option.value).toSet().length == options.length,
       ),
       super(
         initialValue: Set<T>.unmodifiable(selectedValues),
         enabled: enabled && onChanged != null,
         builder: (state) => (state as _NalaraMultiDropdownState<T>)._field(),
       );

  @override
  FormFieldState<Set<T>> createState() => _NalaraMultiDropdownState<T>();
}

class _NalaraMultiDropdownState<T extends Object>
    extends FormFieldState<Set<T>> {
  final _focus = FocusNode();
  bool _open = false;

  @override
  NalaraMultiDropdown<T> get widget => super.widget as NalaraMultiDropdown<T>;

  @override
  void didUpdateWidget(covariant NalaraMultiDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameSet(oldWidget.selectedValues, widget.selectedValues)) {
      setValue(Set<T>.unmodifiable(widget.selectedValues));
    }
  }

  @override
  void reset() {
    super.reset();
    widget.onChanged?.call(value ?? const {});
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_open || !widget.enabled) return;
    final original = Set<T>.unmodifiable(value ?? const {});
    final snapshot = List<NalaraDropdownOption<T>>.unmodifiable(widget.options);
    FocusScope.of(context).unfocus();
    setState(() => _open = true);
    Set<T>? chosen;
    try {
      chosen = await showDialog<Set<T>>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: .16),
        builder: (_) => _MultiDropdownPanel<T>(
          title:
              widget.menuTitle ?? widget.decoration.labelText ?? 'Pilih opsi',
          searchHint: widget.searchHint,
          options: snapshot,
          selected: original,
        ),
      );
    } finally {
      if (mounted) setState(() => _open = false);
    }
    if (!mounted) return;
    if (chosen != null && widget.enabled && _optionsAreValid(chosen)) {
      final next = Set<T>.unmodifiable(chosen);
      didChange(next);
      widget.onChanged?.call(next);
    }
    if (mounted && widget.enabled) _focus.requestFocus();
  }

  bool _optionsAreValid(Set<T> values) => values.every(
    (value) =>
        widget.options.any((option) => option.value == value && option.enabled),
  );

  Widget _field() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedValues = value ?? <T>{};
    final selected = widget.options
        .where((option) => selectedValues.contains(option.value))
        .toList(growable: false);
    final label = selected.isEmpty
        ? widget.hint
        : selected.length == 1
        ? selected.first.label
        : '${selected.length} anak dipilih';
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.decoration.labelText ?? widget.menuTitle ?? 'Pilihan',
      value: label,
      hint: errorText ?? widget.decoration.errorText,
      onTap: widget.enabled ? _choose : null,
      child: InkWell(
        focusNode: _focus,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(12),
        onFocusChange: (_) {
          if (mounted) setState(() {});
        },
        onTap: widget.enabled ? _choose : null,
        child: ExcludeSemantics(
          child: InputDecorator(
            isFocused: _open || _focus.hasFocus,
            isEmpty: selected.isEmpty,
            decoration: widget.decoration
                .applyDefaults(theme.inputDecorationTheme)
                .copyWith(
                  enabled: widget.enabled,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  errorText: errorText ?? widget.decoration.errorText,
                  errorMaxLines: 3,
                  suffixIcon: Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: widget.enabled
                        ? colors.primary
                        : colors.onSurfaceVariant,
                  ),
                ),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'NalaraInter',
                fontSize: 14,
                height: 1.4,
                color: widget.enabled && selected.isNotEmpty
                    ? colors.onSurface
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiDropdownPanel<T extends Object> extends StatefulWidget {
  final List<NalaraDropdownOption<T>> options;
  final Set<T> selected;
  final String title, searchHint;

  const _MultiDropdownPanel({
    required this.options,
    required this.selected,
    required this.title,
    required this.searchHint,
  });

  @override
  State<_MultiDropdownPanel<T>> createState() => _MultiDropdownPanelState<T>();
}

class _MultiDropdownPanelState<T extends Object>
    extends State<_MultiDropdownPanel<T>> {
  final _search = TextEditingController(), _scroll = ScrollController();
  late final Set<T> _selected = {...widget.selected};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() => _query = query.trim().toLowerCase());
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _toggle(T value) {
    setState(() {
      if (!_selected.add(value)) _selected.remove(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final words = _query.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final matches = widget.options
        .where((option) {
          final text = '${option.label} ${option.searchText}'.toLowerCase();
          return words.every(text.contains);
        })
        .toList(growable: false);
    final rowHeight = math.max(
      60.0,
      MediaQuery.textScalerOf(context).scale(14) * 2.8 + 14,
    );
    return Dialog(
      key: const ValueKey('nalara-multi-dropdown-panel'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      backgroundColor: const Color(0xFFFBF8F0),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'NalaraInter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup pilihan',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              TextField(
                key: const ValueKey('nalara-multi-dropdown-search'),
                controller: _search,
                onChanged: _filter,
                style: const TextStyle(
                  fontFamily: 'NalaraInter',
                  fontSize: 14,
                  height: 1.4,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _filter,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _search.clear();
                            _filter('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                fit: FlexFit.loose,
                child: matches.isEmpty
                    ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 24,
                          ),
                          child: Text(
                            widget.options.isEmpty
                                ? 'Belum ada pilihan tersedia.'
                                : 'Tidak ada pilihan yang sesuai pencarian.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'NalaraInter',
                              fontSize: 14,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height:
                            math.min(
                              NalaraMultiDropdown.maxVisibleOptions,
                              matches.length,
                            ) *
                            rowHeight,
                        child: Scrollbar(
                          controller: _scroll,
                          thumbVisibility:
                              matches.length >
                              NalaraMultiDropdown.maxVisibleOptions,
                          child: ListView.builder(
                            key: const ValueKey(
                              'nalara-multi-dropdown-options',
                            ),
                            controller: _scroll,
                            padding: EdgeInsets.zero,
                            itemExtent: rowHeight,
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final option = matches[index];
                              final selected = _selected.contains(option.value);
                              return Semantics(
                                selected: selected,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Material(
                                    color: selected
                                        ? colors.primary.withValues(alpha: .09)
                                        : Colors.white.withValues(alpha: .65),
                                    borderRadius: BorderRadius.circular(10),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: ValueKey(
                                        'nalara-multi-option-${option.value}',
                                      ),
                                      onTap: option.enabled
                                          ? () => _toggle(option.value)
                                          : null,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              key: ValueKey(
                                                'nalara-dropdown-checkbox-${option.value}',
                                              ),
                                              value: selected,
                                              onChanged: option.enabled
                                                  ? (_) => _toggle(option.value)
                                                  : null,
                                              activeColor: colors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                option.label,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'NalaraInter',
                                                  fontSize: 14,
                                                  height: 1.4,
                                                  fontWeight: selected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: option.enabled
                                                      ? colors.onSurface
                                                      : colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('nalara-multi-dropdown-done'),
                  onPressed: () =>
                      Navigator.of(context).pop(Set<T>.unmodifiable(_selected)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameSet<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);
