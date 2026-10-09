// Build-time feature switches (shared by frontend and backend).

/// Voice input (on-device Whisper speech-to-text).
///
/// false for the demo build: every mic button is hidden and ModelManager
/// skips the Whisper download (~148 MB). The code stays in place — flip to
/// true to bring it back.
const bool kVoiceInputEnabled = false;
