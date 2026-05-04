import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsAnalyzerScreen extends StatefulWidget {
  const SmsAnalyzerScreen({super.key});

  @override
  State<SmsAnalyzerScreen> createState() => _SmsAnalyzerScreenState();
}

class _SmsAnalyzerScreenState extends State<SmsAnalyzerScreen> {
  final Telephony telephony = Telephony.instance;

  List<SmsMessage> _allMessages = [];    // Chứa tất cả tin nhắn
  List<SmsMessage> _displayMessages = []; // Chứa tin nhắn đang được lọc để hiển thị
  bool _isLoading = true;

  final TextEditingController _phoneSearchController = TextEditingController();
  String _currentFilter = 'ALL'; // 'ALL', 'QC', 'OTP'

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  // Xin quyền đọc SMS
  Future<void> _initializePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
    ].request();

    if (statuses[Permission.sms]!.isGranted) {
      _loadMessages();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng cấp quyền để đọc tin nhắn!')),
        );
      }
    }
  }

  // Tải toàn bộ tin nhắn
  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    setState(() {
      _allMessages = messages;
      _displayMessages = messages;
      _isLoading = false;
    });
  }

  // Hàm xử lý các bộ lọc
  void _applyFilter(String type) {
    setState(() {
      _currentFilter = type;
      _phoneSearchController.clear(); // Xóa thanh tìm sđt khi chuyển tab

      if (type == 'ALL') {
        _displayMessages = _allMessages;
      } else if (type == 'QC') {
        // Lọc tin nhắn bắt đầu bằng [QC]
        _displayMessages = _allMessages.where((m) =>
            (m.body ?? '').toUpperCase().startsWith('[QC]')
        ).toList();
      } else if (type == 'OTP') {
        // Lọc tin nhắn chứa [OTP]
        _displayMessages = _allMessages.where((m) =>
            (m.body ?? '').toUpperCase().contains('[OTP]')
        ).toList();
      }
    });
  }

  // Lọc theo số điện thoại
  void _filterByPhone(String phone) {
    setState(() {
      _currentFilter = 'PHONE';
      if (phone.isEmpty) {
        _displayMessages = _allMessages;
      } else {
        _displayMessages = _allMessages.where((m) =>
            (m.address ?? '').contains(phone)
        ).toList();
      }
    });
  }

  // Xử lý khi nhấn vào tin nhắn OTP để lấy 6 số
  void _extractAndShowOTP(String body) {
    // Dùng Regex tìm chuỗi 6 số nằm phía sau chữ [OTP]
    RegExp regExp = RegExp(r'\[OTP\].*?(\d{6})', caseSensitive: false);
    var match = regExp.firstMatch(body);

    String otpCode = match != null ? match.group(1)! : "Không tìm thấy 6 chữ số";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã OTP của bạn là:', textAlign: TextAlign.center),
        content: Text(
          otpCode,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 2),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG')),
        ],
      ),
    );
  }

  // Hàm chuyển đổi Timestamp sang Ngày/Tháng
  String _formatDate(int? timestamp) {
    if (timestamp == null) return '';
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Analyzer'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Thống kê tổng số tin nhắn
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(
              'Tổng số tin nhắn: ${_allMessages.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          // Thanh tìm kiếm số điện thoại
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _phoneSearchController,
              decoration: const InputDecoration(
                labelText: 'Tìm theo số điện thoại',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterByPhone,
              keyboardType: TextInputType.phone,
            ),
          ),

          // Các nút Lọc nhóm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: _currentFilter == 'ALL',
                onSelected: (_) => _applyFilter('ALL'),
              ),
              FilterChip(
                label: const Text('Quảng cáo [QC]'),
                selected: _currentFilter == 'QC',
                onSelected: (_) => _applyFilter('QC'),
              ),
              FilterChip(
                label: const Text('Mã [OTP]'),
                selected: _currentFilter == 'OTP',
                onSelected: (_) => _applyFilter('OTP'),
              ),
            ],
          ),
          const Divider(),

          // Danh sách hiển thị
          Expanded(
            child: _displayMessages.isEmpty
                ? const Center(child: Text('Không có tin nhắn nào phù hợp.'))
                : ListView.builder(
              itemCount: _displayMessages.length,
              itemBuilder: (context, index) {
                SmsMessage msg = _displayMessages[index];
                bool isOTP = (msg.body ?? '').toUpperCase().contains('[OTP]');

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.message),
                  ),
                  title: Text(msg.address ?? 'Không rõ'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        msg.body ?? 'Không có nội dung',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(msg.date),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: isOTP
                      ? const Icon(Icons.key, color: Colors.blue)
                      : null,
                  onTap: () {
                    if (isOTP) {
                      _extractAndShowOTP(msg.body!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}