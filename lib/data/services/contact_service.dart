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

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final filtered = contacts.where((c) => c.displayName.toLowerCase().contains(query.toLowerCase())).toList();
    
    return filtered.map((c) => {
      'name': c.displayName,
      'phones': c.phones.map((p) => p.number).toList()
    }).toList();
  }
}
