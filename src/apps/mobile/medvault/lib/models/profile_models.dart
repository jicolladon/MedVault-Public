class EmergencyContact {
  final String id;
  final String name;
  final EmergencyContactRelationship relationship;
  final String phone;
  final String? email;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.email,
    required this.isPrimary,
  });

  const EmergencyContact.empty()
    : id = '',
      name = '',
      relationship = EmergencyContactRelationship.other,
      phone = '',
      email = null,
      isPrimary = false;

  EmergencyContact copyWith({
    String? id,
    String? name,
    EmergencyContactRelationship? relationship,
    String? phone,
    String? email,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

enum EmergencyContactRelationship {
  spouse,
  parent,
  sibling,
  child,
  partner,
  friend,
  caregiver,
  other;

  String get apiValue {
    switch (this) {
      case EmergencyContactRelationship.spouse:
        return 'spouse';
      case EmergencyContactRelationship.parent:
        return 'parent';
      case EmergencyContactRelationship.sibling:
        return 'sibling';
      case EmergencyContactRelationship.child:
        return 'child';
      case EmergencyContactRelationship.partner:
        return 'partner';
      case EmergencyContactRelationship.friend:
        return 'friend';
      case EmergencyContactRelationship.caregiver:
        return 'caregiver';
      case EmergencyContactRelationship.other:
        return 'other';
    }
  }

  static EmergencyContactRelationship fromValue(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'spouse':
      case 'wife':
      case 'husband':
        return EmergencyContactRelationship.spouse;
      case 'parent':
      case 'mother':
      case 'father':
        return EmergencyContactRelationship.parent;
      case 'sibling':
      case 'brother':
      case 'sister':
        return EmergencyContactRelationship.sibling;
      case 'child':
      case 'son':
      case 'daughter':
        return EmergencyContactRelationship.child;
      case 'partner':
        return EmergencyContactRelationship.partner;
      case 'friend':
        return EmergencyContactRelationship.friend;
      case 'caregiver':
      case 'carer':
        return EmergencyContactRelationship.caregiver;
      default:
        return EmergencyContactRelationship.other;
    }
  }
}
