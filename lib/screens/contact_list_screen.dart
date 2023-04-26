import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';

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
    // print("..number of items: ${_contactList.length}"); // debug statement to check the number of items in the list
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
    // print("..number of items: ${_contactList.length}"); // debug statement to check the number of items in the list
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

  void _showForm(int? id) async {
    if (id != null) {
      final existingContactList =
          _contactList.firstWhere((element) => element['id'] == id);
      _nameController.text = existingContactList['name'];
      _phoneController.text = existingContactList['phone'];
      _emailController.text = existingContactList['email'];
      _photo = base64Decode(existingContactList['photo']);
    } else {
      _nameController.text = '';
      _phoneController.text = '';
      _emailController.text = '';
      _photo = Uint8List(0);
    }

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    await Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: Text(id == null ? 'Create New Contact' : 'Update Contact'),
        ),
        body: Container(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _photo.isNotEmpty
                        ? MemoryImage(_photo)
                        : const AssetImage('assets/images/default_contact.png')
                            as ImageProvider,
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(hintText: 'Phone'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'Email'),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      if (id == null) {
                        await _addContact();
                      }
                      if (id != null) {
                        await _updateContact(id);
                      }
                      // create the text fields
                      _nameController.text = '';
                      _phoneController.text = '';
                      _emailController.text = '';
                      // close
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(id == null ? 'Create New' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      );
    })).catchError((error) {
      showSnackBar(error.toString());
    });
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
            onTap: () {
              try {
                showSnackBar('Tile $index Tapped');
                // function to call the contact can be implemented here,
                // but it is not in the assignment scope So I have left as a SnackBar for now
              } catch (e) {
                print('Error showing snackbar: $e');
              }
            },
            leading: SizedBox(
              width: 50,
              height: 50,
              child: CircleAvatar(
                backgroundImage: _contactList[index]['photo'].isNotEmpty
                    ? MemoryImage(base64Decode(_contactList[index]['photo']))
                    : const AssetImage('assets/images/default_contact.png')
                        as ImageProvider,
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
                  onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: const Text(
                            'Are you sure you want to delete this contact?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _deleteContact(_contactList[index]['id']);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  ),
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
