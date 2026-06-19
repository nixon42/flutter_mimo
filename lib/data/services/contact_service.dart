import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

abstract class ContactService {
  Future<List<Map<String, dynamic>>> searchContacts(String query);
}

class DeviceContactService implements ContactService {
  @override
  Future<List<Map<String, dynamic>>> searchContacts(String query) async {
    bool hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      throw Exception('Permission denied for reading contacts');
    }

    // Tarik HANYA nama & ID saja (sangat cepat & menghindari gagal join database di Android)
    final allContacts = await FlutterContacts.getContacts(withProperties: false, withAccounts: true);
    
    // Identifikasi akun apa saja yang terbaca
    Set<String> visibleAccounts = {};
    for (var c in allContacts) {
      for (var acc in c.accounts) {
        visibleAccounts.add('${acc.name} (${acc.type})');
      }
    }
    debugPrint('CONTACT_DEBUG: Visible Accounts to this App: ${visibleAccounts.join(", ")}');
    debugPrint('CONTACT_DEBUG: Total light contacts fetched: ${allContacts.length}');
    
    // Filter nama secara lokal di Flutter
    final matchedLightContacts = allContacts.where((c) {
      final displayName = c.displayName.toLowerCase();
      final backupName = '${c.name.first} ${c.name.last}'.toLowerCase();
      final q = query.toLowerCase();
      return displayName.contains(q) || backupName.contains(q);
    }).toList();

    debugPrint('CONTACT_DEBUG: Found ${matchedLightContacts.length} matching names.');

    // Tarik detail lengkap (termasuk nomor HP) HANYA untuk kontak yang namanya cocok
    List<Map<String, dynamic>> finalResult = [];
    for (var light in matchedLightContacts) {
      final fullContact = await FlutterContacts.getContact(light.id);
      if (fullContact != null) {
        debugPrint('CONTACT_DEBUG: Detail fetched for ${fullContact.displayName} (Phones: ${fullContact.phones.length})');
        finalResult.add({
          'name': fullContact.displayName,
          'phones': fullContact.phones.map((p) => p.number).toList(),
        });
      }
    }
    
    return finalResult;
  }
}
