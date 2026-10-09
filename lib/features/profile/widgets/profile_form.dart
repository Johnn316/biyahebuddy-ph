import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/contracts/contracts.dart';
import '../../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSizes.gap);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            // SingleChildScrollView (not ListView) so off-screen fields are
            // still built and validated.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?widget.header,
                  const FormSectionTitle('Ikaw', icon: Icons.person_rounded),
                  BigTextField(
                    key: const Key('field-name'),
                    controller: _name,
                    label: 'Pangalan',
                    required: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  gap,
                  BigTextField(
                    key: const Key('field-age'),
                    controller: _age,
                    label: 'Edad',
                    required: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final age = int.tryParse(v);
                      return age == null || age < 16 || age > 100
                          ? '16 hanggang 100 lang'
                          : null;
                    },
                  ),
                  const FormSectionTitle(
                    'Lisensya at sasakyan',
                    icon: Icons.badge_rounded,
                  ),
                  BigTextField(
                    key: const Key('field-license'),
                    controller: _license,
                    label: 'License no.',
                    hint: 'Hal. N01-23-456789',
                    required: true,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  gap,
                  BigTextField(
                    key: const Key('field-restriction'),
                    controller: _restriction,
                    label: 'Restriction code',
                    hint: 'Hal. B, B1',
                    required: true,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  gap,
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
                  gap,
                  BigDropdownField(
                    key: const Key('field-vehicle'),
                    label: 'Uri ng sasakyan',
                    options: vehicleTypes,
                    value: _vehicleType,
                    required: true,
                    onChanged: (v) => setState(() => _vehicleType = v),
                  ),
                  const FormSectionTitle(
                    'Kalusugan at insurance',
                    icon: Icons.health_and_safety_rounded,
                  ),
                  BigDropdownField(
                    key: const Key('field-blood'),
                    label: 'Blood type',
                    options: bloodTypes,
                    value: _bloodType,
                    onChanged: (v) => setState(() => _bloodType = v),
                  ),
                  gap,
                  BigTextField(
                    key: const Key('field-insurer'),
                    controller: _insurer,
                    label: 'Insurer',
                    textCapitalization: TextCapitalization.words,
                  ),
                  gap,
                  BigTextField(
                    key: const Key('field-policy'),
                    controller: _policy,
                    label: 'Policy no.',
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const FormSectionTitle(
                    'Emergency contacts',
                    icon: Icons.contact_phone_rounded,
                  ),
                  Text(
                    'Sila ang ite-text kapag pinindot mo ang EMERGENCY. '
                    'Kailangan ng kahit isa.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  for (final (i, c) in _contacts.indexed)
                    _ContactCard(
                      key: ObjectKey(c),
                      index: i,
                      controllers: c,
                      canRemove: _contacts.length > 1,
                      onRemove: () => setState(() {
                        _contacts.remove(c);
                        c.dispose();
                      }),
                    ),
                  gap,
                  OutlinedButton.icon(
                    key: const Key('add-contact'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(AppSizes.minTap),
                      textStyle: Theme.of(context).textTheme.titleLarge,
                    ),
                    onPressed: () =>
                        setState(() => _contacts.add(_ContactControllers())),
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Magdagdag ng contact'),
                  ),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.all(AppSizes.gap),
              child: FilledButton(
                key: const Key('profile-submit'),
                onPressed: widget.saving ? null : _submit,
                child: widget.saving
                    ? const SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Text(widget.submitLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    super.key,
    required this.index,
    required this.controllers,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _ContactControllers controllers;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: AppSizes.gap),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contact ${index + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    key: Key('remove-contact-$index'),
                    tooltip: 'Tanggalin',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            BigTextField(
              key: Key('field-contact-name-$index'),
              controller: controllers.name,
              label: 'Pangalan',
              required: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            BigTextField(
              key: Key('field-contact-phone-$index'),
              controller: controllers.phone,
              label: 'Mobile no.',
              hint: '09171234567',
              required: true,
              keyboardType: TextInputType.phone,
              validator: validatePhone,
            ),
          ],
        ),
      ),
    );
  }
}
