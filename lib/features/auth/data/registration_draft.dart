// lib/features/auth/data/registration_draft.dart
//
// The in-progress registration, held in one place for the whole flow.
//
// Why this exists — the data-loss bug it fixes:
//
// RegistrationData is immutable and was passed forward correctly, step by
// step, but nothing ever read it back. Every step built its controllers empty
// (`TextEditingController()` with no `text:`) and only folded its values into
// the model at the moment it navigated forward. So going back from step 5 to
// fix the birth date on step 4 and pressing next again constructed a *fresh*
// RegisterStep5View whose controllers started blank — every field the student
// had already typed there was gone. The values were never lost in transit;
// they were never written down in the first place, and never read back.
//
// A single mutable draft, created once and passed by reference through the
// steps, fixes both halves: each step seeds its controllers from the draft on
// entry and writes them back on exit (including on back-navigation, via
// dispose), so moving in either direction is lossless.
//
// Writing back in dispose() is what keeps this independent of *how* the step
// was left — forward, the app-bar arrow, or the system back gesture — so it
// needs no cooperation from the PopScope/canPop guards that stop the flow
// emptying the navigator. The two mechanisms never touch.

import 'package:rawasi_app_n/features/auth/data/registration_data.dart';

class RegistrationDraft {
  RegistrationData data;

  RegistrationDraft([RegistrationData? initial])
      : data = initial ?? const RegistrationData();

  /// Merge this step's current values into the draft.
  ///
  /// Takes the same named arguments as [RegistrationData.copyWith], so a step
  /// writes back exactly what it owns and leaves every other field untouched.
  void save(RegistrationData Function(RegistrationData current) update) {
    data = update(data);
  }
}
