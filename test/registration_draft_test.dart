import 'package:flutter_test/flutter_test.dart';
import 'package:rawasi_app_n/features/auth/data/registration_data.dart';
import 'package:rawasi_app_n/features/auth/data/registration_draft.dart';
import 'package:rawasi_app_n/features/auth/views/register_view_step_4.dart';

void main() {
  group('registration draft', () {
    test('carries one step forward into the next', () {
      final draft = RegistrationDraft(const RegistrationData(academicYear: '1'));

      draft.save((d) => d.copyWith(phone1: '01000000123'));
      draft.save((d) => d.copyWith(firstName: 'طالب', madhab: 'hanafi'));

      expect(draft.data.academicYear, '1');
      expect(draft.data.phone1, '01000000123');
      expect(draft.data.firstName, 'طالب');
      expect(draft.data.madhab, 'hanafi');
    });

    test('a later step cannot clobber an earlier one', () {
      // Each step writes only the fields it owns, so step 5 saving its own
      // values must not blank out what step 4 collected.
      final draft = RegistrationDraft(const RegistrationData(
        academicYear: '2',
        firstName: 'طالب',
        madhab: 'shafii',
        schoolBranch: 'science',
      ));

      draft.save((d) => d.copyWith(
            instituteName: 'معهد',
            governorate: 'القاهرة',
            city: 'المعادي',
          ));

      expect(draft.data.firstName, 'طالب');
      expect(draft.data.madhab, 'shafii');
      expect(draft.data.schoolBranch, 'science');
      expect(draft.data.instituteName, 'معهد');
    });

    test('going back and forward is lossless in both directions', () {
      // The reported bug: fill step 4, go on to step 5, fill it, go BACK to
      // fix the birth date, then forward again. The old code rebuilt step 5
      // with empty controllers, so everything typed there was gone.
      final draft = RegistrationDraft(const RegistrationData(academicYear: '1'));

      // step 4
      draft.save((d) => d.copyWith(
            firstName: 'طالب',
            lastName: 'تجريبي',
            gender: 'male',
            birthDate: '2008-01-01',
            madhab: 'hanafi',
            schoolBranch: 'science',
          ));

      // step 5 — filled in, then left via back (dispose writes it down)
      draft.save((d) => d.copyWith(
            instituteName: 'معهد الأزهر',
            governorate: 'القاهرة',
            city: 'المعادي',
            phone2: '01000000124',
          ));

      // back on step 4: it re-reads the draft, and the corrected date is saved
      expect(draft.data.firstName, 'طالب');
      expect(draft.data.birthDate, '2008-01-01');
      draft.save((d) => d.copyWith(birthDate: '2007-05-09'));

      // forward to step 5 again: its fields must still be there
      expect(draft.data.birthDate, '2007-05-09');
      expect(draft.data.instituteName, 'معهد الأزهر');
      expect(draft.data.governorate, 'القاهرة');
      expect(draft.data.city, 'المعادي');
      expect(draft.data.phone2, '01000000124');
    });

    test('an empty draft starts blank rather than null', () {
      final draft = RegistrationDraft();

      expect(draft.data.academicYear, '');
      expect(draft.data.madhab, '');
      expect(draft.data.schoolBranch, isNull);
      expect(draft.data.isWhatsapp, isTrue);
    });
  });

  group('birth date', () {
    test('the picker cannot reach today, which the API rejects', () {
      // The API validates before:today. Capping the picker at "today" let the
      // student pick a date that only failed on the final submit.
      final last = latestBirthDate();
      final today = DateTime.now();
      final midnight = DateTime(today.year, today.month, today.day);

      expect(last.isBefore(midnight), isTrue);
      expect(midnight.difference(last).inDays, 1);
    });
  });
}
