// Build-time feature switches (shared by frontend and backend).

/// Voice input (on-device Whisper speech-to-text).
///
/// false for the demo build: every mic button is hidden and ModelManager
/// skips the Whisper download (~148 MB). The code stays in place — flip to
/// true to bring it back.
const bool kVoiceInputEnabled = false;

/// "Dalawang panig" (two-driver analysis in Buddy chat).
///
/// false for the demo build: the "Tanong | Dalawang panig" switch is hidden
/// and Buddy is ask-only. The code stays in place — flip to true to bring it
/// back.
const bool kTwoSidesEnabled = false;
