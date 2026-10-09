import '../contracts/contracts.dart';

class FakeProfileRepository implements ProfileRepository {
  Profile? _profile = const Profile(
    name: 'Juan Dela Cruz',
    age: 34,
    plateNo: 'NAB 1234',
    licenseNo: 'N01-23-456789',
    restrictionCode: 'B, B1',
    vehicleType: 'Private car',
    bloodType: 'O+',
    insurer: 'Sample Insurance Co.',
    policyNo: 'POL-0000-SAMPLE',
    contacts: [
      EmergencyContact(name: 'Maria Dela Cruz (asawa)', phone: '09171234567'),
      EmergencyContact(name: 'Pedro Dela Cruz (kapatid)', phone: '09981234567'),
    ],
  );

  @override
  Future<Profile?> load() async => _profile;

  @override
  Future<void> save(Profile profile) async => _profile = profile;
}
