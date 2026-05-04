import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'add_contact_screen.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});
  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  List<Map<String, dynamic>> _allContacts = []; // Chứa toàn bộ data
  List<Map<String, dynamic>> _foundContacts = []; // Chứa data sau khi lọc
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() { _isLoading = true; });
    final contacts = await DBHelper().getContacts();
    setState(() {
      _allContacts = contacts;
      _foundContacts = contacts; // Ban đầu hiển thị tất cả
      _isLoading = false;
    });
  }

  // Hàm Lọc dữ liệu cho chức năng Tìm kiếm
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allContacts;
    } else {
      results = _allContacts.where((contact) =>
      contact['name'].toString().toLowerCase().contains(enteredKeyword.toLowerCase()) ||
          contact['phone'].toString().contains(enteredKeyword)
      ).toList();
    }
    setState(() {
      _foundContacts = results;
    });
  }

  // Hàm xử lý Xóa
  Future<void> _deleteContact(int id) async {
    await DBHelper().deleteContact(id);
    _loadContacts();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa thành công!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Màu nền giống ảnh mẫu
      appBar: AppBar(
        title: const Text('My Contacts', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0, // Xóa đổ bóng viền
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddContactScreen()),
              );
              _loadContacts();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Thanh Tìm kiếm (Search Bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _foundContacts.isEmpty
                ? const Center(child: Text('Không tìm thấy danh bạ nào.'))
                : ListView.builder(
              itemCount: _foundContacts.length,
              itemBuilder: (context, index) {
                final contact = _foundContacts[index];
                return Dismissible(
                  key: Key(contact['id'].toString()), // Key bắt buộc để xóa
                  direction: DismissDirection.endToStart, // Vuốt từ phải sang trái
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteContact(contact['id']);
                  },
                  child: Column( // Bọc Column để thêm gạch chân phân cách giống mẫu
                    children: [
                      ListTile(
                        onTap: () async {
                          // Chạm vào để Sửa
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddContactScreen(existingContact: contact),
                            ),
                          );
                          _loadContacts();
                        },
                        leading: contact['avatar'] != null
                            ? CircleAvatar(
                          radius: 25,
                          backgroundImage: MemoryImage(contact['avatar']),
                        )
                            : CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.primaries[index % Colors.primaries.length], // Đổi màu random cho đẹp
                          child: Text(
                            contact['name']?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        title: Text(contact['name'] ?? 'Không có tên', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(contact['phone'] ?? 'Không có số', style: const TextStyle(color: Colors.grey)),
                      ),
                      const Divider(height: 1, indent: 80, endIndent: 16), // Đường kẻ ngang
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}