import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/sql_helper.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  // List of maps to store contacts data
  List<Map<String, dynamic>> _contactList = [];

  // image picker

  // Boolean to load the data
  bool _isLoading = true;

  void _refreshContactList() async {
    // Get the data from the database
    final data = await SQLHelper.getContacts();

    // Set the data to the list
    setState(() {
      _contactList = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshContactList();
    print(
        "..number of items: ${_contactList.length}"); // debug statement to check the number of items in the list
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Uint8List _photo = Uint8List(0);

  Future<void> _addContact() async {
    await SQLHelper.createContact(
      _nameController.text,
      _phoneController.text,
      _emailController.text,
      base64Encode(_photo),
    );
    _refreshContactList();
    print(
        "..number of items: ${_contactList.length}"); // debug statement to check the number of items in the list
  }

  Future<void> _updateContact(int id) async {
    await SQLHelper.updateContact(id, _nameController.text,
        _phoneController.text, _emailController.text, base64Encode(_photo));
    _refreshContactList();
  }

  Future<void> _deleteContact(int id) async {
    await SQLHelper.deleteContact(id);
    showSnackBar('Contact deleted successfully');
    _refreshContactList();
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // void encodePhoto() {
  //   if (_photo.isNotEmpty) {
  //     final bytes = File(_photo).readAsBytesSync();
  //     final base64Image = base64Encode(bytes);
  //     _photo = base64Image;

  //     print('Photo Encoded'); // debug
  //   }
  // }
  //
  // void decodePhoto() {
  //   if (_photo.isNotEmpty) {
  //     final bytes = base64Decode(_photo);
  //     final base64Image = base64Encode(bytes);
  //     _photo = base64Image;

  //     print('Photo Decoded'); // debug
  //   }
  // }

  void _showForm(int? id) async {
    if (id != null) {
      print('id is not Null $id');
      final existingContactList =
          _contactList.firstWhere((element) => element['id'] == id);
      _nameController.text = existingContactList['name'];
      _phoneController.text = existingContactList['phone'];
      _emailController.text = existingContactList['email'];
      _photo = base64Decode(existingContactList['photo']);
    } else {
      print('id is Null $id');
      _nameController.text = '';
      _phoneController.text = '';
      _emailController.text = '';
      _photo = Uint8List(0);
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text(id == null ? 'Create New Contact' : 'Update Contact'),
        ),
        body: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      _photo.isNotEmpty ? MemoryImage(_photo) : null,
                ),
                onTap: () async {
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    setState(() {
                      _photo = File(pickedFile.path).readAsBytesSync();
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(hintText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (id == null) {
                    await _addContact();
                  }
                  if (id != null) {
                    await _updateContact(id);
                  }
                  // create the text fields
                  _nameController.text = '';
                  _phoneController.text = '';
                  // Close the bottom sheet
                  Navigator.of(context).pop();
                },
                child: Text(id == null ? 'Create New' : 'Update'),
              ),
            ],
          ),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts: ${_contactList.length}'),
        // addbutton
        actions: [
          IconButton(
            onPressed: () => _showForm(null),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _contactList.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.all(5),
          child: ListTile(
            onTap: () => showSnackBar('Tile $index Tapped'),
            leading: SizedBox(
              width: 50,
              height: 50,
              child: CircleAvatar(
                backgroundImage: _contactList[index]['photo'].isNotEmpty
                    ? MemoryImage(base64Decode(_contactList[index]['photo']))
                    : null,
              ),
            ),
            title: Text(_contactList[index]['name']),
            subtitle: Text(_contactList[index]['phone']),
            trailing: SizedBox(
              width: 100,
              child: Row(children: [
                IconButton(
                  onPressed: () => _showForm(_contactList[index]['id']),
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () => _deleteContact(_contactList[index]['id']),
                  icon: const Icon(Icons.delete),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
