import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/grouped.dart';
import 'form_fields.dart';

const vehicleTypes = ['Kotse', 'Motorsiklo', 'SUV/Van', 'Truck', 'Iba pa'];
const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

final _phMobile = RegExp(r'^(09\d{9}|\+639\d{9})$');

String? validatePhone(String value) =>
    _phMobile.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))
    ? null
    : 'Hal. 09171234567';

/// Driver profile form used by onboarding and the Profile screen.
///
/// Fields scroll; the submit button stays pinned at the bottom (thumb zone).
class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
    this.saving = false,
    this.header,
  });

  final Profile? initial;
  final String submitLabel;
  final bool saving;
  final ValueChanged<Profile> onSubmit;

  /// Optional widget shown above the fields (e.g. theme switcher).
  final Widget? header;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ContactControllers {
  _ContactControllers([EmergencyContact? c])
    : name = TextEditingController(text: c?.name),
      phone = TextEditingController(text: c?.phone);

  final TextEditingController name;
  final TextEditingController phone;

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _license;
  late final TextEditingController _restriction;
  late final TextEditingController _plate;
  late final TextEditingController _insurer;
  late final TextEditingController _policy;
  late final List<_ContactControllers> _contacts;
  String? _vehicleType;
  String? _bloodType;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name);
    _age = TextEditingController(text: p == null ? null : '${p.age}');
    _license = TextEditingController(text: p?.licenseNo);
    _restriction = TextEditingController(text: p?.restrictionCode);
    _plate = TextEditingController(text: p?.plateNo);
    _insurer = TextEditingController(text: p?.insurer);
    _policy = TextEditingController(text: p?.policyNo);
    _vehicleType = vehicleTypes.contains(p?.vehicleType)
        ? p!.vehicleType
        : null;
    _bloodType = bloodTypes.contains(p?.bloodType) ? p!.bloodType : null;
    _contacts = [
      for (final c in p?.contacts ?? const <EmergencyContact>[])
        _ContactControllers(c),
    ];
    if (_contacts.isEmpty) _contacts.add(_ContactControllers());
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _age,
      _license,
      _restriction,
      _plate,
      _insurer,
      _policy,
    ]) {
      c.dispose();
    }
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      // Scroll to the first problem (no snackbar: it would cover the button).
      Scrollable.ensureVisible(
        invalid.first.context,
        alignment: 0.2,
        duration: const Duration(milliseconds: 300),
      );
      return;
    }
    widget.onSubmit(
      Profile(
        name: _name.text.trim(),
        age: int.parse(_age.text.trim()),
        plateNo: _plate.text.trim().toUpperCase(),
        licenseNo: _license.text.trim().toUpperCase(),
        restrictionCode: _restriction.text.trim().toUpperCase(),
        vehicleType: _vehicleType!,
        bloodType: _bloodType,
        insurer: _opt(_insurer),
        policyNo: _opt(_policy),
        contacts: [
          for (final c in _contacts)
            EmergencyContact(
              name: c.name.text.trim(),
              phone: c.phone.text.replaceAll(RegExp(r'[\s-]'), ''),
            ),
        ],
      ),
    );
  }

  Future<void> _removeContact(_ContactControllers c) async {
    final name = c.name.text.trim();
    final ok = await confirmWithSheet(
      context,
      title: name.isEmpty ? 'Tanggalin ang contact?' : 'Tanggalin si $name?',
      message: 'Hindi na siya ite-text kapag may emergency.',
      confirmLabel: 'Tanggalin',
      destructive: false, // red is reserved for SOS
    );
    if (!ok || !mounted) return;
    setState(() {
      _contacts.remove(c);
      c.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget field(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: child,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            // SingleChildScrollView (not ListView) so off-screen fields are
            // still built and validated.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?widget.header,
                    GroupedSection(
                      header: 'Ikaw',
                      children: [
                        field(
                          BigTextField(
                            key: const Key('field-name'),
                            controller: _name,
                            label: 'Pangalan',
                            required: true,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        field(
                          BigTextField(
                            key: const Key('field-age'),
                            controller: _age,
                            label: 'Edad',
                            required: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              final age = int.tryParse(v);
                              return age == null || age < 16 || age > 100
                                  ? '16 hanggang 100 lang'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    GroupedSection(
                      header: 'Lisensya at sasakyan',
                      children: [
                        field(
                          BigTextField(
                            key: const Key('field-license'),
                            controller: _license,
                            label: 'License no.',
                            hint: 'Hal. N01-23-456789',
                            required: true,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        field(
                          BigTextField(
                            key: const Key('field-restriction'),
                            controller: _restriction,
                            label: 'Restriction code',
                            hint: 'Hal. B, B1',
                            required: true,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        field(
                          BigTextField(
                            key: const Key('field-plate'),
                            controller: _plate,
                            label: 'Plate no.',
                            hint: 'Hal. NAB 1234',
                            required: true,
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => RegExp(r'\d').hasMatch(v)
                                ? null
                                : 'Dapat may numero ang plate',
                          ),
                        ),
                        field(
                          BigDropdownField(
                            key: const Key('field-vehicle'),
                            label: 'Uri ng sasakyan',
                            options: vehicleTypes,
                            value: _vehicleType,
                            required: true,
                            onChanged: (v) => setState(() => _vehicleType = v),
                          ),
                        ),
                      ],
                    ),
                    GroupedSection(
                      header: 'Kalusugan at insurance',
                      children: [
                        field(
                          BigDropdownField(
                            key: const Key('field-blood'),
                            label: 'Blood type',
                            options: bloodTypes,
                            value: _bloodType,
                            onChanged: (v) => setState(() => _bloodType = v),
                          ),
                        ),
                        field(
                          BigTextField(
                            key: const Key('field-insurer'),
                            controller: _insurer,
                            label: 'Insurer',
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        field(
                          BigTextField(
                            key: const Key('field-policy'),
                            controller: _policy,
                            label: 'Policy no.',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                    for (final (i, c) in _contacts.indexed)
                      GroupedSection(
                        key: ObjectKey(c),
                        header: i == 0
                            ? 'Emergency contacts · Contact 1'
                            : 'Contact ${i + 1}',
                        footer: i == 0
                            ? 'Sila ang ite-text kapag pinindot mo ang SOS. '
                                  'Kailangan ng kahit isa.'
                            : null,
                        children: [
                          field(
                            BigTextField(
                              key: Key('field-contact-name-$i'),
                              controller: c.name,
                              label: 'Pangalan',
                              required: true,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          field(
                            BigTextField(
                              key: Key('field-contact-phone-$i'),
                              controller: c.phone,
                              label: 'Mobile no.',
                              hint: '09171234567',
                              required: true,
                              keyboardType: TextInputType.phone,
                              validator: validatePhone,
                            ),
                          ),
                          if (_contacts.length > 1)
                            GroupedTile(
                              tapKey: Key('remove-contact-$i'),
                              leading: Icon(
                                CupertinoIcons.trash,
                                color: context.palette.muted,
                              ),
                              title: 'Tanggalin ang contact',
                              chevron: false,
                              onTap: () => _removeContact(c),
                            ),
                        ],
                      ),
                    GroupedSection(
                      children: [
                        GroupedTile(
                          tapKey: const Key('add-contact'),
                          leading: Icon(
                            CupertinoIcons.plus_circle_fill,
                            color: context.colors.primary,
                            size: 28,
                          ),
                          title: 'Magdagdag ng contact',
                          titleStyle: context.text.titleMedium?.copyWith(
                            color: context.colors.primary,
                          ),
                          chevron: false,
                          onTap: () => setState(
                            () => _contacts.add(_ContactControllers()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(
                top: BorderSide(color: context.colors.outline, width: 0.5),
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ContentWidth(
                child: FilledButton(
                  key: const Key('profile-submit'),
                  onPressed: widget.saving
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          _submit();
                        },
                  child: widget.saving
                      ? const CupertinoActivityIndicator()
                      : Text(widget.submitLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
