import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../shared/state/load_cubit.dart';
import '../../../shared/widgets/nalara_dropdown.dart';
import '../../../shared/widgets/nalara_pickers.dart';
import '../../../shared/widgets/page_widgets.dart';
import '../../../utils/currency_input.dart';
import '../../../utils/color.dart';
import '../domain/tuition_fee.dart';
import '../domain/tuition_repository.dart';

class TuitionFeeEditor extends StatefulWidget {
  final String studentId;
  final TuitionFee? initial;
  final TuitionRepository repository;
  const TuitionFeeEditor({
    super.key,
    required this.studentId,
    required this.initial,
    required this.repository,
  });
  @override
  State<TuitionFeeEditor> createState() => _TuitionFeeEditorState();
}

class _TuitionFeeEditorState extends State<TuitionFeeEditor> {
  final _form = GlobalKey<FormState>();
  final _submit = SubmitCubit();
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : RupiahInputFormatter.format(widget.initial!.amount),
  );
  late DateTime? _date = widget.initial == null || widget.initial!.paid
      ? null
      : DateTime.parse(widget.initial!.dueDate);
  late String _status = widget.initial?.paid == true
      ? 'unpaid'
      : widget.initial?.status ?? 'unpaid';
  @override
  void dispose() {
    _amount.dispose();
    _submit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submit.state.busy || !_form.currentState!.validate()) return;
    final ok = await _submit.run(
      () => widget.repository.save(
        widget.studentId,
        amount: RupiahInputFormatter.parse(_amount.text),
        dueDate: DateFormat('yyyy-MM-dd').format(_date!),
        status: _status,
        version: widget.initial?.version ?? 0,
      ),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SubmitCubit, SubmitState>(
    bloc: _submit,
    builder: (context, state) => PopScope(
      canPop: !state.busy,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initial?.paid == true
                    ? 'Biaya periode berikutnya'
                    : 'Atur biaya bimbel',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: NalaraColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Isi nominal dan tanggal pembayaran yang disepakati dengan Orang Tua.',
                style: TextStyle(color: NalaraColors.muted, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text('Nominal biaya'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amount,
                enabled: !state.busy,
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahInputFormatter()],
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: 'Masukkan nominal',
                ),
                validator: (value) {
                  final amount = RupiahInputFormatter.parse(value ?? '');
                  return amount < 1 || amount > 1000000000000
                      ? 'Masukkan nominal Rp 1–1.000.000.000.000'
                      : null;
                },
              ),
              const SizedBox(height: 18),
              FormField<DateTime>(
                initialValue: _date,
                validator: (_) =>
                    _date == null ? 'Pilih tanggal jatuh tempo' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Tanggal jatuh tempo'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: state.busy
                          ? null
                          : () async {
                              final picked = await showNalaraDatePicker(
                                context: context,
                                initialDate: _date ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2200),
                              );
                              if (picked != null && mounted) {
                                setState(() => _date = picked);
                                field.didChange(picked);
                              }
                            },
                      child: Text(
                        _date == null
                            ? 'Pilih tanggal'
                            : DateFormat('d MMMM yyyy', 'id_ID').format(_date!),
                      ),
                    ),
                    if (field.errorText != null)
                      Text(
                        field.errorText!,
                        style: const TextStyle(color: NalaraColors.danger),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              NalaraDropdown<String>(
                value: _status,
                enabled: !state.busy,
                decoration: const InputDecoration(
                  labelText: 'Status pembayaran',
                ),
                menuTitle: 'Status pembayaran',
                options: const [
                  NalaraDropdownOption(value: 'unpaid', label: 'Belum lunas'),
                  NalaraDropdownOption(value: 'paid', label: 'Lunas'),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 22),
              SubmitButton(
                cubit: _submit,
                label: 'Simpan biaya',
                onPressed: _save,
              ),
              TextButton(
                onPressed: state.busy
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
