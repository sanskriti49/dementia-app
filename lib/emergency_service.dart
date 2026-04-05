import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_contact.dart';

class EmergencyService {
  static const String key = "emergency_contacts";

  static Future<List<EmergencyContact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key) ?? [];

    return data.map((e) {
      return EmergencyContact.fromJson(jsonDecode(e));
    }).toList();
  }

  static Future<void> addContact(EmergencyContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getContacts();

    contacts.add(contact);

    final encoded = contacts.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(key, encoded);
  }

  static Future<void> deleteContact(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final contacts = await getContacts();

    contacts.removeAt(index);

    final encoded = contacts.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(key, encoded);
  }
}