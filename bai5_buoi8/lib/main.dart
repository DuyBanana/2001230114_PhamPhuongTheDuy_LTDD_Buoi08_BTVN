import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(RealMusicPlayerApp());
}

class RealMusicPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.purpleAccent,
        scaffoldBackgroundColor: Color(0xFF1E1E2C),
      ),
      home: MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Danh sách phát chứa các file âm thanh THẬT được chọn từ máy
  List<PlatformFile> _playlist = [];

  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // Lắng nghe trạng thái Play/Pause
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Cập nhật tổng thời lượng bài hát
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    // Cập nhật thời gian thực khi đang phát (để thanh Slider chạy)
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    // Tự động chuyển bài khi hát xong
    _audioPlayer.onPlayerComplete.listen((event) {
      _nextSong();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- CÁC HÀM CHỨC NĂNG THẬT ---

  // 1. Mở bộ nhớ điện thoại để lấy file âm thanh
  Future<void> _pickAudioFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true, // Cho phép chọn nhiều bài hát để làm danh sách
    );

    if (result != null) {
      setState(() {
        _playlist.addAll(result.files);
      });
      // Nếu danh sách trước đó rỗng, tự động phát bài vừa thêm
      if (_playlist.length == result.files.length) {
        _playSong(0);
      }
    }
  }

  // 2. Hàm phát nhạc từ đường dẫn thật trên máy
  void _playSong(int index) async {
    if (_playlist.isEmpty) return;

    setState(() {
      _currentIndex = index;
    });

    // Khác với Bài 4, ở đây ta dùng DeviceFileSource để đọc file từ bộ nhớ
    String path = _playlist[_currentIndex].path!;
    await _audioPlayer.play(DeviceFileSource(path));
  }

  // 3. Các hàm điều khiển cơ bản
  void _pauseSong() async {
    await _audioPlayer.pause();
  }

  void _nextSong() {
    if (_playlist.isEmpty) return;
    int nextIndex = (_currentIndex + 1) % _playlist.length;
    _playSong(nextIndex);
  }

  void _prevSong() {
    if (_playlist.isEmpty) return;
    int prevIndex = (_currentIndex - 1) >= 0 ? (_currentIndex - 1) : (_playlist.length - 1);
    _playSong(prevIndex);
  }

  // Hàm chuyển đổi giây thành định dạng Phút:Giây (00:00)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // --- GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    bool hasMusic = _playlist.isNotEmpty;
    String currentTitle = hasMusic ? _playlist[_currentIndex].name : "Chưa có bài hát nào";

    return Scaffold(
      appBar: AppBar(
        title: Text('MP3 PLAYER', style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Giao diện đĩa nhạc
          SizedBox(height: 20),
          Container(
            height: 220,
            width: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
              image: DecorationImage(
                image: NetworkImage('https://cdn-icons-png.flaticon.com/512/26/26307.png'), // Icon mặc định
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 30),

          // Tên bài hát đang phát
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              currentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Cắt chữ nếu tên file quá dài
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 5),
          Text(
            hasMusic ? "My Device" : "Hãy thêm nhạc",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 20),

          // Thanh Slider Tua nhạc
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(_formatDuration(_position)),
                Expanded(
                  child: Slider(
                    activeColor: Colors.purpleAccent,
                    inactiveColor: Colors.grey.shade800,
                    min: 0.0,
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                    onChanged: (value) async {
                      if (!hasMusic) return;
                      final position = Duration(seconds: value.toInt());
                      await _audioPlayer.seek(position);
                    },
                  ),
                ),
                Text(_formatDuration(_duration)),
              ],
            ),
          ),

          // Bộ nút Play, Pause, Next, Prev
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                iconSize: 40,
                icon: Icon(Icons.skip_previous),
                onPressed: _prevSong,
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purpleAccent,
                ),
                child: IconButton(
                  iconSize: 50,
                  color: Colors.white,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (!hasMusic) return;
                    _isPlaying ? _pauseSong() : _playSong(_currentIndex);
                  },
                ),
              ),
              IconButton(
                iconSize: 40,
                icon: Icon(Icons.skip_next),
                onPressed: _nextSong,
              ),
            ],
          ),

          SizedBox(height: 10),
          Divider(color: Colors.grey.shade800, thickness: 2),

          // Danh sách phát (Playlist) bên dưới
          Expanded(
            child: hasMusic
                ? ListView.builder(
              itemCount: _playlist.length,
              itemBuilder: (context, index) {
                bool isActive = index == _currentIndex;
                return ListTile(
                  leading: Icon(
                    isActive ? Icons.music_note : Icons.play_circle_outline,
                    color: isActive ? Colors.purpleAccent : Colors.grey,
                  ),
                  title: Text(
                    _playlist[index].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? Colors.purpleAccent : Colors.white,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () => _playSong(index),
                );
              },
            )
                : Center(child: Text("Nhấn vào nút '+' để thêm nhạc", style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),

      // Nút góc phải bên dưới để Thêm file MP3 từ máy điện thoại
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purpleAccent,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: _pickAudioFiles,
      ),
    );
  }
}