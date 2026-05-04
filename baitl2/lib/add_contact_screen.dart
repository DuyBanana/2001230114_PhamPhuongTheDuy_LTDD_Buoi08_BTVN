import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'db_helper.dart';

class AddContactScreen extends StatefulWidget {
  // Nhận vào danh bạ cũ nếu ở chế độ Sửa
  final Map<String, dynamic>? existingContact;
  const AddContactScreen({super.key, this.existingContact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _avatar;
  Uint8List? _existingAvatarBytes; // Chứa ảnh cũ nếu có

  @override
  void initState() {
    super.initState();
    // Nếu có dữ liệu truyền vào -> Đổ dữ liệu cũ ra các ô nhập liệu
    if (widget.existingContact != null) {
      _nameController.text = widget.existingContact!['name'] ?? '';
      _phoneController.text = widget.existingContact!['phone'] ?? '';
      _emailController.text = widget.existingContact!['email'] ?? '';
      _existingAvatarBytes = widget.existingContact!['avatar'];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
        _existingAvatarBytes = null; // Chọn ảnh mới thì xóa ảnh cũ đi
      });
    }
  }

  Future<void> _saveContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên và số điện thoại không được để trống!')),
      );
      return;
    }

    Uint8List? avatarBytes = _existingAvatarBytes;
    if (_avatar != null) {
      avatarBytes = await _avatar!.readAsBytes();
    }

    final contact = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'avatar': avatarBytes,
    };

    // Kiểm tra: Nếu có id thì Gọi hàm Cập nhật, ngược lại Gọi hàm Thêm
    if (widget.existingContact != null) {
      await DBHelper().updateContact(widget.existingContact!['id'], contact);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công!')),
      );
    } else {
      await DBHelper().insertContact(contact);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm mới thành công!')),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.existingContact != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa danh bạ' : 'Thêm danh bạ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatar != null
                      ? FileImage(_avatar!)
                      : (_existingAvatarBytes != null ? MemoryImage(_existingAvatarBytes!) : null) as ImageProvider?,
                  child: (_avatar == null && _existingAvatarBytes == null)
                      ? const Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên'),
              ),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: _saveContact,
                  child: Text(isEdit ? 'Cập nhật' : 'Lưu')
              ),
            ],
          ),
        ),
      ),
    );
  }
}