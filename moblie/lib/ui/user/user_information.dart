import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  User? user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  String? _photoUrl;
  File? _imageFile;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _nameController.text = user!.displayName ?? '';
      _emailController.text = user!.email ?? '';
      _photoUrl = user!.photoURL;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    String fileName = '${user!.uid}.jpg';
    Reference storageReference =
    FirebaseStorage.instance.ref().child('user_images/$fileName');
    UploadTask uploadTask = storageReference.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<void> _updateUserInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      try {
        String? photoUrl = _photoUrl;
        if (_imageFile != null) {
          photoUrl = await _uploadImage(_imageFile!);
        }

        await user!.updateDisplayName(_nameController.text);
        await user!.updateEmail(_emailController.text);
        await user!.updatePhotoURL(photoUrl);

        // Check if the user document exists
        DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists) {
          // Update the document
          await userDocRef.update({
            'name': _nameController.text,
            'email': _emailController.text,
            'photoUrl': photoUrl,
          });
        } else {
          // Create the document if it doesn't exist
          await userDocRef.set({
            'name': _nameController.text,
            'email': _emailController.text,
            'photoUrl': photoUrl,
          });
        }

        setState(() {
          _photoUrl = photoUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cập nhật thông tin thành công')));

        // Navigate back to the account tab after successful update
        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        print("Error updating user info: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')));
      } finally {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt tài khoản'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!) as ImageProvider<Object>
                    : (_photoUrl != null
                    ? NetworkImage(_photoUrl!) as ImageProvider<Object>
                    : null),
                child: _imageFile == null && _photoUrl == null
                    ? Icon(Icons.account_circle, size: 50)
                    : null,
              ),
              TextButton(
                onPressed: _pickImage,
                child: Text('Cập nhật ảnh đại diện'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tên'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _isUpdating
                  ? CircularProgressIndicator()
                  : TextButton(
                onPressed: _updateUserInfo,
                child: Text('Cập nhật thông tin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
