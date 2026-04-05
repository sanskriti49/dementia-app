import 'package:flutter/material.dart';
import 'emergency_service.dart';
import 'emergency_contact.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<EmergencyContact> contacts = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    contacts = await EmergencyService.getContacts();
    setState(() {});
  }

  void addContactDialog() {
    String name = "";
    String phone = "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Name"),
              onChanged: (v) => name = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Phone"),
              keyboardType: TextInputType.phone,
              onChanged: (v) => phone = v,
            ),

          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await EmergencyService.addContact(
                EmergencyContact(name: name, phone: phone),
              );
              Navigator.pop(context);
              load();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Contacts")),
      floatingActionButton: FloatingActionButton(
        onPressed: addContactDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (_, i) {
          final c = contacts[i];
          return ListTile(
            title: Text(c.name),
            subtitle: Text(c.phone),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await EmergencyService.deleteContact(i);
                load();
              },
            ),
          );
        },
      ),
    );
  }
}