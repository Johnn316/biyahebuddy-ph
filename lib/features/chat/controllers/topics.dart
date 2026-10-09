import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// One Buddy topic: a category of tappable questions.
class BuddyTopic {
  const BuddyTopic({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.questions,
  });

  final String id;
  final String label;

  /// Filipino one-liner under the label.
  final String subtitle;
  final IconData icon;

  /// Each is EXACTLY a `question` from assets/data/faq.json (so Buddy answers
  /// with the curated, law-checked answer), except [flagFlowQuestion], which
  /// starts the guided na-flag flow. Checked by test/chat_topics_test.dart.
  final List<String> questions;
}

/// Starts the guided na-flag flow (see flag_flow.dart).
const flagFlowQuestion = 'Na-flag ako, ano ang gagawin?';

/// The 12 categories. Only questions our laws.json / fines.json can answer.
const buddyTopics = [
  BuddyTopic(
    id: 'signs',
    label: 'Signs & Signals',
    subtitle: 'Signal, stop line, sirena',
    icon: CupertinoIcons.lightbulb_fill,
    questions: [
      'Kailangan ba mag-signal bago lumiko o huminto?',
      'Saan dapat huminto, bago o lampas sa stop line?',
      'Ano gagawin pag may ambulansya na may sirena?',
    ],
  ),
  BuddyTopic(
    id: 'markings',
    label: 'Road Markings & Overtaking',
    subtitle: 'Mga guhit sa kalsada at pag-overtake',
    icon: Icons.add_road_rounded,
    questions: [
      'Pwede ba mag-overtake sa double solid yellow line?',
      'Pwede ba mag-overtake sa isang solid na dilaw na linya?',
      'Pwede ba mag-overtake sa putol-putol na linya?',
      'Pwede ba lumipat ng lane sa solid na puting linya?',
      'Saan bawal mag-overtake?',
    ],
  ),
  BuddyTopic(
    id: 'right-of-way',
    label: 'Right of Way & Turning',
    subtitle: 'Sino ang mauuna, paano lumiko',
    icon: CupertinoIcons.arrow_turn_up_right,
    questions: [
      'Sino ang may right of way sa intersection?',
      'Saang lane dapat manggaling bago kumanan o kumaliwa?',
      'Kailangan bang magbigay daan sa tao sa pedestrian lane?',
      'Bawal ba mag-counterflow?',
    ],
  ),
  BuddyTopic(
    id: 'helmet-seatbelt',
    label: 'Helmet & Seatbelt',
    subtitle: 'Motor at kotse',
    icon: Icons.sports_motorsports_rounded,
    questions: [
      'Magkano multa pag walang helmet sa motor?',
      'Magkano multa pag walang seatbelt?',
    ],
  ),
  BuddyTopic(
    id: 'cellphone',
    label: 'Cellphone While Driving',
    subtitle: 'Text, tawag, Waze',
    icon: CupertinoIcons.device_phone_portrait,
    questions: [
      'Bawal ba gumamit ng cellphone habang nagmamaneho?',
      'Pwede ba gumamit ng Waze o GPS habang nagmamaneho?',
    ],
  ),
  BuddyTopic(
    id: 'drunk',
    label: 'Drunk Driving',
    subtitle: 'Nakainom at breath test',
    icon: Icons.no_drinks_rounded,
    questions: [
      'Ano ang parusa sa drunk driving?',
      'Pwede ba tumanggi sa breathalyzer test?',
    ],
  ),
  BuddyTopic(
    id: 'child',
    label: 'Child Safety',
    subtitle: 'Bata sa sasakyan',
    icon: Icons.child_care_rounded,
    questions: [
      'Kailangan ba ng car seat ang anak ko?',
      'Pwede ba ang bata sa harap na upuan?',
    ],
  ),
  BuddyTopic(
    id: 'speed-parking',
    label: 'Speed & Parking',
    subtitle: 'Bilis, kaskasero, paradahan',
    icon: CupertinoIcons.speedometer,
    questions: [
      'Ano ang speed limit sa Pilipinas?',
      'Ano ang reckless driving?',
      'Saan bawal mag-park?',
      'Bawal ba huminto sa yellow box?',
    ],
  ),
  BuddyTopic(
    id: 'accidents',
    label: 'Accidents',
    subtitle: 'Kapag nakabangga o nabangga',
    icon: CupertinoIcons.exclamationmark_triangle_fill,
    questions: [
      'Ano ang dapat gawin pag nakabangga ako?',
      'Bawal ba umalis pagkatapos ng aksidente?',
    ],
  ),
  BuddyTopic(
    id: 'traffic-stops',
    label: 'Traffic Stops (Na-flag)',
    subtitle: 'Kapag pinara ng enforcer',
    icon: CupertinoIcons.flag_fill,
    questions: [
      flagFlowQuestion,
      'Kinuha ang lisensya ko, pwede pa ba ako magmaneho?',
    ],
  ),
  BuddyTopic(
    id: 'license',
    label: 'License & Registration',
    subtitle: 'Lisensya, permit, OR/CR',
    icon: CupertinoIcons.person_crop_rectangle_fill,
    questions: [
      'Ano ang multa pag nagmaneho nang walang lisensya?',
      'Ano ang mangyayari kung expired ang lisensya ko?',
      'Pwede ba magmaneho mag-isa gamit ang student permit?',
      'Kailangan bang dala ang OR/CR habang nagmamaneho?',
    ],
  ),
  BuddyTopic(
    id: 'coding',
    label: 'Number Coding',
    subtitle: 'UVVRP at multa',
    icon: CupertinoIcons.calendar,
    questions: [
      'Anong oras ang number coding?',
      'Magkano ang multa sa coding?',
    ],
  ),
];

BuddyTopic? topicById(String? id) {
  for (final t in buddyTopics) {
    if (t.id == id) return t;
  }
  return null;
}
