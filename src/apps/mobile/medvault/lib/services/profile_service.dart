import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../models/api_models.dart';
import '../models/profile_models.dart';
import 'auth_service.dart';
import 'database.dart' as db;

class ProfileData {
  final UserProfile profile;
  final List<EmergencyContact> emergencyContacts;

  const ProfileData({required this.profile, required this.emergencyContacts});
}

class ProfileService {
  ProfileService({required AuthService authService, db.AppDatabase? database})
    : _authService = authService,
      _db = database ?? db.AppDatabase();

  final AuthService _authService;
  final db.AppDatabase _db;
  bool _hasPendingEmergencyContactsSync = false;

  Future<ProfileData> loadProfileData() async {
    final profile = await fetchUserProfile();
    final userId = _resolveStorageUserId(profile);
    var contacts = await getEmergencyContacts(userId: userId);

    if (!_authService.demoMode) {
      try {
        final remoteContacts = await _authService.getEmergencyContacts();
        if (remoteContacts.isNotEmpty) {
          final mappedRemoteContacts = _fromApiContacts(remoteContacts);
          await replaceEmergencyContacts(
            userId: userId,
            contacts: mappedRemoteContacts,
            syncRemote: false,
          );
          contacts = await getEmergencyContacts(userId: userId);
        } else if (contacts.isNotEmpty) {
          await _syncEmergencyContactsToRemote(contacts: contacts);
        }
      } catch (error) {
        debugPrint('Failed to sync emergency contacts from remote: $error');
      }
    }

    if (contacts.isEmpty) {
      final legacyContacts = _legacyContactsFromProfile(profile);
      if (legacyContacts.isNotEmpty) {
        await replaceEmergencyContacts(
          userId: userId,
          contacts: legacyContacts,
        );
        contacts = await getEmergencyContacts(userId: userId);
      }
    }

    return ProfileData(profile: profile, emergencyContacts: contacts);
  }

  Future<UserProfile> fetchUserProfile() async {
    return _authService.getProfile();
  }

  Future<UserProfile> updateUserProfile(UpdateProfileRequest request) async {
    return _authService.updateProfile(request);
  }

  String displayName(UserProfile profile) {
    final fullName = [profile.firstName, profile.lastName]
        .where((value) => value != null && value.trim().isNotEmpty)
        .join(' ')
        .trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return profile.email;
  }

  String? profilePhotoUrl(UserProfile profile) {
    final raw = profile.profilePictureUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return raw;
  }

  Future<List<EmergencyContact>> getEmergencyContacts({
    required String userId,
  }) async {
    final records =
        await (_db.select(_db.emergencyContactEntries)
              ..where((tbl) => tbl.userId.equals(userId))
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.isPrimary,
                  mode: OrderingMode.desc,
                ),
                (tbl) => OrderingTerm(expression: tbl.createdAt),
              ]))
            .get();

    return records
        .map(
          (entry) => EmergencyContact(
            id: entry.id,
            name: entry.name,
            relationship: EmergencyContactRelationship.fromValue(
              entry.relationship,
            ),
            phone: entry.phone,
            email: entry.email,
            isPrimary: entry.isPrimary,
          ),
        )
        .toList(growable: false);
  }

  Future<void> addEmergencyContact({
    required String userId,
    required EmergencyContact contact,
  }) async {
    final existing = await getEmergencyContacts(userId: userId);
    final shouldBePrimary = existing.isEmpty ? true : contact.isPrimary;
    final normalized = contact.copyWith(
      id: contact.id.trim().isEmpty ? _newContactId() : contact.id,
      isPrimary: shouldBePrimary,
    );

    await _db.transaction(() async {
      if (normalized.isPrimary) {
        await _clearPrimaryContact(userId: userId);
      }

      final now = DateTime.now();
      await _db
          .into(_db.emergencyContactEntries)
          .insert(
            db.EmergencyContactEntriesCompanion.insert(
              id: normalized.id,
              userId: userId,
              name: normalized.name,
              relationship: normalized.relationship.apiValue,
              phone: normalized.phone,
              email: Value(normalized.email),
              isPrimary: Value(normalized.isPrimary),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrReplace,
          );
    });

    await _ensureSinglePrimary(userId: userId);
    await _syncEmergencyContactsToRemote(userId: userId);
  }

  Future<void> updateEmergencyContact({
    required String userId,
    required EmergencyContact contact,
  }) async {
    await _db.transaction(() async {
      if (contact.isPrimary) {
        await _clearPrimaryContact(userId: userId);
      }

      final now = DateTime.now();
      await (_db.update(_db.emergencyContactEntries)..where(
            (tbl) => tbl.userId.equals(userId) & tbl.id.equals(contact.id),
          ))
          .write(
            db.EmergencyContactEntriesCompanion(
              name: Value(contact.name),
              relationship: Value(contact.relationship.apiValue),
              phone: Value(contact.phone),
              email: Value(contact.email),
              isPrimary: Value(contact.isPrimary),
              updatedAt: Value(now),
            ),
          );
    });

    await _ensureSinglePrimary(userId: userId);
    await _syncEmergencyContactsToRemote(userId: userId);
  }

  Future<void> removeEmergencyContact({
    required String userId,
    required String contactId,
  }) async {
    await (_db.delete(
          _db.emergencyContactEntries,
        )..where((tbl) => tbl.userId.equals(userId) & tbl.id.equals(contactId)))
        .go();

    await _ensureSinglePrimary(userId: userId);
    await _syncEmergencyContactsToRemote(userId: userId);
  }

  Future<void> setPrimaryEmergencyContact({
    required String userId,
    required String contactId,
  }) async {
    await _db.transaction(() async {
      await _clearPrimaryContact(userId: userId);
      await (_db.update(_db.emergencyContactEntries)..where(
            (tbl) => tbl.userId.equals(userId) & tbl.id.equals(contactId),
          ))
          .write(
            db.EmergencyContactEntriesCompanion(
              isPrimary: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });

    await _syncEmergencyContactsToRemote(userId: userId);
  }

  Future<void> replaceEmergencyContacts({
    required String userId,
    required List<EmergencyContact> contacts,
    bool syncRemote = true,
  }) async {
    final normalizedContacts = _normalizeContacts(contacts);

    await _db.transaction(() async {
      await (_db.delete(
        _db.emergencyContactEntries,
      )..where((tbl) => tbl.userId.equals(userId))).go();

      for (final contact in normalizedContacts) {
        final now = DateTime.now();
        await _db
            .into(_db.emergencyContactEntries)
            .insert(
              db.EmergencyContactEntriesCompanion.insert(
                id: contact.id.trim().isEmpty ? _newContactId() : contact.id,
                userId: userId,
                name: contact.name,
                relationship: contact.relationship.apiValue,
                phone: contact.phone,
                email: Value(contact.email),
                isPrimary: Value(contact.isPrimary),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });

    if (syncRemote) {
      await _syncEmergencyContactsToRemote(userId: userId);
    }
  }

  Future<void> clearEmergencyContacts({required String userId}) async {
    await (_db.delete(
      _db.emergencyContactEntries,
    )..where((tbl) => tbl.userId.equals(userId))).go();

    await _syncEmergencyContactsToRemote(contacts: const []);
  }

  Future<void> seedDemoEmergencyData({required String userId}) async {
    if (!_authService.demoMode) {
      return;
    }

    final existing = await getEmergencyContacts(userId: userId);
    if (existing.isNotEmpty) {
      return;
    }

    final contacts = [
      EmergencyContact(
        id: _newContactId(),
        name: 'Jane Doe',
        relationship: EmergencyContactRelationship.spouse,
        phone: '+1 (555) 987-6543',
        email: 'jane.doe@example.com',
        isPrimary: true,
      ),
      EmergencyContact(
        id: _newContactId(),
        name: 'Robert Doe',
        relationship: EmergencyContactRelationship.sibling,
        phone: '+1 (555) 456-7890',
        email: 'robert.doe@example.com',
        isPrimary: false,
      ),
    ];

    await replaceEmergencyContacts(userId: userId, contacts: contacts);
  }

  String _resolveStorageUserId(UserProfile profile) {
    final email = profile.email.trim();
    if (email.isNotEmpty) {
      return email;
    }

    return profile.userId;
  }

  List<EmergencyContact> _legacyContactsFromProfile(UserProfile profile) {
    final hasLegacyContact =
        (profile.emergencyContactName ?? '').trim().isNotEmpty ||
        (profile.emergencyContactPhone ?? '').trim().isNotEmpty;

    if (!hasLegacyContact) {
      return const [];
    }

    return [
      EmergencyContact(
        id: _newContactId(),
        name: profile.emergencyContactName?.trim().isNotEmpty == true
            ? profile.emergencyContactName!
            : 'Emergency Contact',
        relationship: EmergencyContactRelationship.fromValue(
          profile.emergencyContactRelationship,
        ),
        phone: profile.emergencyContactPhone ?? '',
        email: null,
        isPrimary: true,
      ),
    ];
  }

  List<EmergencyContact> _normalizeContacts(List<EmergencyContact> contacts) {
    if (contacts.isEmpty) {
      return const [];
    }

    final hasPrimary = contacts.any((contact) => contact.isPrimary);
    if (hasPrimary) {
      return contacts;
    }

    return [contacts.first.copyWith(isPrimary: true), ...contacts.skip(1)];
  }

  Future<void> _clearPrimaryContact({required String userId}) async {
    await (_db.update(
      _db.emergencyContactEntries,
    )..where((tbl) => tbl.userId.equals(userId))).write(
      db.EmergencyContactEntriesCompanion(
        isPrimary: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _ensureSinglePrimary({required String userId}) async {
    final contacts = await getEmergencyContacts(userId: userId);
    if (contacts.isEmpty) {
      return;
    }

    final primaryContacts = contacts.where((contact) => contact.isPrimary);
    if (primaryContacts.isEmpty) {
      await setPrimaryEmergencyContact(
        userId: userId,
        contactId: contacts.first.id,
      );
      return;
    }

    if (primaryContacts.length == 1) {
      return;
    }

    final keepPrimary = primaryContacts.first.id;
    await _db.transaction(() async {
      await _clearPrimaryContact(userId: userId);
      await (_db.update(_db.emergencyContactEntries)..where(
            (tbl) => tbl.userId.equals(userId) & tbl.id.equals(keepPrimary),
          ))
          .write(
            db.EmergencyContactEntriesCompanion(
              isPrimary: const Value(true),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  String _newContactId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> _syncEmergencyContactsToRemote({
    String? userId,
    List<EmergencyContact>? contacts,
  }) async {
    if (_authService.demoMode) {
      return;
    }

    final contactsToSync =
        contacts ??
        (userId == null
            ? const <EmergencyContact>[]
            : await getEmergencyContacts(userId: userId));

    final payload = _toApiContacts(contactsToSync);
    try {
      await _authService.replaceEmergencyContacts(contacts: payload);
      _hasPendingEmergencyContactsSync = false;
    } catch (error) {
      _hasPendingEmergencyContactsSync = true;
      debugPrint('Failed to sync emergency contacts to remote: $error');
    }
  }

  Future<void> syncPendingChanges() async {
    if (_authService.demoMode || !_hasPendingEmergencyContactsSync) {
      return;
    }

    try {
      final profile = await _authService.getProfile();
      final userId = _resolveStorageUserId(profile);
      await _syncEmergencyContactsToRemote(userId: userId);
    } catch (error) {
      debugPrint('Failed to sync pending profile changes: $error');
    }
  }

  List<ProfileEmergencyContact> _toApiContacts(
    List<EmergencyContact> contacts,
  ) {
    return contacts
        .map(
          (contact) => ProfileEmergencyContact(
            contactId: contact.id,
            name: contact.name,
            relationship: contact.relationship.apiValue,
            phone: contact.phone,
            email: contact.email,
            isPrimary: contact.isPrimary,
          ),
        )
        .toList(growable: false);
  }

  List<EmergencyContact> _fromApiContacts(
    List<ProfileEmergencyContact> contacts,
  ) {
    return contacts
        .map(
          (contact) => EmergencyContact(
            id: contact.contactId,
            name: contact.name,
            relationship: EmergencyContactRelationship.fromValue(
              contact.relationship,
            ),
            phone: contact.phone,
            email: contact.email,
            isPrimary: contact.isPrimary,
          ),
        )
        .toList(growable: false);
  }
}
