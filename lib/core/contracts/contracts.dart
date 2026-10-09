// SHARED CONTRACT between frontend (features/) and backend (data/).
// Both owners must agree before changing anything in this file.
//
// Frontend depends ONLY on these types. Backend implements the interfaces
// in lib/data/ and wires them in lib/core/di/providers.dart.

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum Agency {
  lto,
  mmda,
  city;

  static Agency fromJson(String value) =>
      Agency.values.firstWhere((a) => a.name == value.toLowerCase());

  String toJson() => name;
}

// ---------------------------------------------------------------------------
// Models (immutable)
// ---------------------------------------------------------------------------

class EmergencyContact {
  const EmergencyContact({required this.name, required this.phone});

  final String name;
  final String phone;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String,
        phone: json['phone'] as String,
      );

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};
}

class Profile {
  const Profile({
    required this.name,
    required this.age,
    required this.plateNo,
    required this.licenseNo,
    required this.restrictionCode,
    required this.vehicleType,
    this.bloodType,
    this.insurer,
    this.policyNo,
    this.contacts = const [],
  });

  final String name;
  final int age;
  final String plateNo;
  final String licenseNo;
  final String restrictionCode;
  final String vehicleType;
  final String? bloodType;
  final String? insurer;
  final String? policyNo;
  final List<EmergencyContact> contacts;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'] as String,
    age: json['age'] as int,
    plateNo: json['plate_no'] as String,
    licenseNo: json['license_no'] as String,
    restrictionCode: json['restriction_code'] as String,
    vehicleType: json['vehicle_type'] as String,
    bloodType: json['blood_type'] as String?,
    insurer: json['insurer'] as String?,
    policyNo: json['policy_no'] as String?,
    contacts: (json['contacts'] as List<dynamic>? ?? const [])
        .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'plate_no': plateNo,
    'license_no': licenseNo,
    'restriction_code': restrictionCode,
    'vehicle_type': vehicleType,
    'blood_type': bloodType,
    'insurer': insurer,
    'policy_no': policyNo,
    'contacts': contacts.map((c) => c.toJson()).toList(),
  };
}

class Fine {
  const Fine({
    required this.violation,
    required this.agency,
    required this.amount,
    required this.legalBasis,
    this.aliases = const [],
  });

  final String violation;
  final Agency agency;

  /// Amount in PHP.
  final num amount;
  final String legalBasis;
  final List<String> aliases;

  factory Fine.fromJson(Map<String, dynamic> json) => Fine(
    violation: json['violation'] as String,
    agency: Agency.fromJson(json['agency'] as String),
    amount: json['amount'] as num,
    legalBasis: json['legal_basis'] as String,
    aliases: (json['aliases'] as List<dynamic>? ?? const [])
        .cast<String>()
        .toList(growable: false),
  );

  Map<String, dynamic> toJson() => {
    'violation': violation,
    'agency': agency.toJson(),
    'amount': amount,
    'legal_basis': legalBasis,
    'aliases': aliases,
  };
}

class Hotline {
  const Hotline({required this.name, required this.number, this.zone});

  final String name;
  final String number;

  /// null = nationwide.
  final String? zone;

  factory Hotline.fromJson(Map<String, dynamic> json) => Hotline(
    name: json['name'] as String,
    number: json['number'] as String,
    zone: json['zone'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'number': number,
    'zone': zone,
  };
}

class CodingStatus {
  const CodingStatus({required this.isCoding, required this.message});

  final bool isCoding;
  final String message;

  factory CodingStatus.fromJson(Map<String, dynamic> json) => CodingStatus(
    isCoding: json['is_coding'] as bool,
    message: json['message'] as String,
  );

  Map<String, dynamic> toJson() => {'is_coding': isCoding, 'message': message};
}

class LawChunk {
  const LawChunk({
    required this.id,
    required this.source,
    required this.section,
    required this.title,
    required this.text,
    this.tags = const [],
  });

  final String id;
  final String source;
  final String section;
  final String title;
  final String text;
  final List<String> tags;

  factory LawChunk.fromJson(Map<String, dynamic> json) => LawChunk(
    id: json['id'] as String,
    source: json['source'] as String,
    section: json['section'] as String,
    title: json['title'] as String,
    text: json['text'] as String,
    tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>().toList(
      growable: false,
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'section': section,
    'title': title,
    'text': text,
    'tags': tags,
  };
}

// ---------------------------------------------------------------------------
// Interfaces (implemented by backend in lib/data/, faked in lib/core/fakes/)
// ---------------------------------------------------------------------------

abstract interface class ProfileRepository {
  Future<Profile?> load();
  Future<void> save(Profile profile);
}

abstract interface class CodingService {
  CodingStatus statusFor(String plateNo, DateTime now);
}

abstract interface class FinesRepository {
  Future<List<Fine>> search(String query, Agency agency);
}

abstract interface class HotlineRepository {
  /// Hotlines for [zone] plus nationwide ones. null zone = nationwide only.
  Future<List<Hotline>> forZone(String? zone);
}

/// Offline AI assistant. Streams tokens/chunks of the answer.
///
/// Answer format (Tagalog/Taglish headings, in this order):
///   1. Kalma muna  — calm, reassuring opener
///   2. Batas       — relevant law WITH citation (source + section)
///   3. Pagsusuri   — analysis of the situation
///   4. Gagawin     — concrete next steps
abstract interface class AiAssistant {
  Stream<String> ask(String question);
  Stream<String> analyzeTwoSides(String driverA, String driverB);
}

/// Thrown by [SosService] when the device can't do what was asked (no SIM,
/// no dialer app, permission denied, SMS not sent). [message] is user-facing
/// Taglish: show it as-is.
class SosUnavailable implements Exception {
  const SosUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class SosService {
  /// null when there is no fix (location off, permission denied, timeout).
  Future<({double lat, double lng})?> currentLocation();

  /// Throws [SosUnavailable] if SMS can't be sent (e.g. no SIM).
  Future<void> smsContacts(List<EmergencyContact> contacts, String message);

  /// Throws [SosUnavailable] if no dialer app exists (e.g. Wi-Fi tablet).
  Future<void> openDialer(String number);

  /// Native (Kotlin) foreground service: hold/press volume buttons to trigger SOS.
  Future<void> enableVolumeTrigger();

  /// False on devices without a ready SIM / SMS support. Use to grey out
  /// "text contacts" buttons.
  Future<bool> canSendSms();

  /// False on devices without a ready SIM / calling support.
  Future<bool> canCall();
}

/// Local (on-device) speech recognition, e.g. Whisper. Filipino + English.
/// Must never use Android's online recognizer.
abstract interface class SpeechService {
  Future<void> startListening();
  Future<String> stopAndTranscribe();
}

/// Manages on-device models (LLM, speech, embeddings).
/// The download is the ONLY network use in the app and happens once.
abstract interface class ModelManager {
  bool get isReady;

  /// Downloads all missing models. Emits progress 0.0..1.0, completes when done.
  Stream<double> downloadModels();
}
