import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


void main() {
  runApp(UserManagerApp());
}

class UserManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Người dùng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF1F1F1F)),
      ),
      home: UserListScreen(),
    );
  }
}

// ==========================================
// PHẦN 1: LỚP XỬ LÝ DATABASE (SQLITE)
// ==========================================
class DatabaseHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'user_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tạo bảng users
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT,
            password TEXT,
            dob TEXT,
            country TEXT,
            avatar_path TEXT
          )
        ''');
        // Thêm 1 dữ liệu mẫu khi vừa tạo DB
        await db.insert('users', {
          'name': 'Melissa Peters',
          'email': 'melpeters@gmail.com',
          'password': 'password123',
          'dob': '23/05/1995',
          'country': 'Nigeria',
          'avatar_path': ''
        });
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await getDatabase();
    return await db.query('users');
  }

  static Future<int> addUser(Map<String, dynamic> user) async {
    final db = await getDatabase();
    return await db.insert('users', user);
  }

  static Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await getDatabase();
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }
}

// ==========================================
// PHẦN 2: MÀN HÌNH DANH SÁCH NGƯỜI DÚNG
// ==========================================
class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<Map<String, dynamic>> _userList = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Hàm tải dữ liệu từ SQLite
  void _loadUsers() async {
    final users = await DatabaseHelper.getUsers();
    setState(() {
      _userList = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Danh sách Tài khoản', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _userList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _userList.length,
        itemBuilder: (context, index) {
          var user = _userList[index];
          String avatarPath = user['avatar_path'] ?? '';

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Color(0xFF1E1E1E),
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.deepPurpleAccent,
                // Hiển thị ảnh thật nếu có, ngược lại hiện Icon
                backgroundImage: avatarPath.isNotEmpty ? FileImage(File(avatarPath)) : null,
                child: avatarPath.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
              ),
              title: Text(user['name'], style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${user['id']} - ${user['email']}'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                // Chuyển sang trang Edit và chờ kết quả quay lại
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen(userData: user)),
                );
                _loadUsers(); // Tải lại danh sách sau khi sửa xong
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // Thêm nhanh một user trống để test
          await DatabaseHelper.addUser({
            'name': 'New User',
            'email': 'newuser@email.com',
            'password': '',
            'dob': '',
            'country': '',
            'avatar_path': ''
          });
          _loadUsers();
        },
      ),
    );
  }
}

// ==========================================
// PHẦN 3: MÀN HÌNH CHỈNH SỬA THÔNG TIN
// ==========================================
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfileScreen({required this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _countryCtrl;

  String _currentAvatarPath = '';

  @override
  void initState() {
    super.initState();
    // Gán dữ liệu cũ vào các ô nhập liệu
    _nameCtrl = TextEditingController(text: widget.userData['name']);
    _emailCtrl = TextEditingController(text: widget.userData['email']);
    _passCtrl = TextEditingController(text: widget.userData['password']);
    _dobCtrl = TextEditingController(text: widget.userData['dob']);
    _countryCtrl = TextEditingController(text: widget.userData['country']);
    _currentAvatarPath = widget.userData['avatar_path'] ?? '';
  }

  // Hàm mở Gallery chọn ảnh
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _currentAvatarPath = pickedFile.path;
      });
    }
  }

  // Hàm lưu thông tin vào CSDL
  void _saveData() async {
    Map<String, dynamic> updatedUser = {
      'name': _nameCtrl.text,
      'email': _emailCtrl.text,
      'password': _passCtrl.text,
      'dob': _dobCtrl.text,
      'country': _countryCtrl.text,
      'avatar_path': _currentAvatarPath,
    };

    await DatabaseHelper.updateUser(widget.userData['id'], updatedUser);

    // Hiển thị thông báo và quay lại màn hình trước
    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Đã lưu thay đổi thành công!')));
    Navigator.pop(this.context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar và Nút đổi ảnh
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: _currentAvatarPath.isNotEmpty ? FileImage(File(_currentAvatarPath)) : null,
                    child: _currentAvatarPath.isEmpty ? Icon(Icons.person, size: 60, color: Colors.grey) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.deepPurpleAccent,
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 30),

            // Các trường nhập liệu
            _buildTextField('Name', _nameCtrl),
            _buildTextField('Email', _emailCtrl),
            _buildTextField('Password', _passCtrl, isPassword: true),
            _buildTextField('Date of Birth', _dobCtrl),
            _buildTextField('Country/Region', _countryCtrl),

            SizedBox(height: 30),

            // Nút Save Changes
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                onPressed: _saveData,
                child: Text('Save changes', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Hàm hỗ trợ tạo giao diện ô nhập liệu cho gọn code
  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepPurpleAccent)),
        ),
      ),
    );
  }
}