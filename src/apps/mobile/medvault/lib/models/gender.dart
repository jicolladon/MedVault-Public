enum Gender { male, female, other, preferNotToSay }

extension GenderApiValue on Gender {
  String get apiValue {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'PreferNotToSay';
    }
  }
}

Gender? genderFromApiValue(String? value) {
  switch (value) {
    case 'Male':
    case 'male':
      return Gender.male;
    case 'Female':
    case 'female':
      return Gender.female;
    case 'Other':
    case 'other':
      return Gender.other;
    case 'PreferNotToSay':
    case 'preferNotToSay':
    case 'Prefer not to say':
    case 'prefer-not-to-say':
      return Gender.preferNotToSay;
    default:
      return null;
  }
}
