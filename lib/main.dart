import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:your_app/login.dart'; // Import your LoginPage
import 'package:your_app/home.dart'; // Import your HomePage (create this if you haven't)

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => LoginPage(), // Set LoginPage as the initial route
        '/home': (context) => HomePage(), // Define the route for your home page
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isRecording = false;
  final _audioRecorder = Record();
  final _audioPlayer = AudioPlayer();
  List<String> _audioFiles = [];
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Amplitude>? _amplitudeSub;
  String? _currentRecordingPath;
  int _recordingId = 0;
  int _chunkIndex = 0;
  int _lastProcessedPosition = 0;
  Color _backgroundColor = Colors.white; // Add this line

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      setState(() => _isRecording = recordState == RecordState.record);
    });
    _amplitudeSub = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 300))
        .listen((amp) => _processAudioChunk());
  }

  Future<void> _loadAudioFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().where((file) => file.path.endsWith('.m4a')).toList();
    setState(() {
      _audioFiles = files.map((file) => file.path).toList();
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        _recordingId = DateTime.now().millisecondsSinceEpoch;
        _currentRecordingPath = '${directory.path}/recording_$_recordingId.m4a';
        _chunkIndex = 0;
        _lastProcessedPosition = 0;
        await _audioRecorder.start(path: _currentRecordingPath);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        print('Audio recorded and saved at: $path');
        _loadAudioFiles();
        // Send the final chunk if any
        await _sendAudioChunk(path, true);
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _processAudioChunk() async {
    print("-----------_processAudioChunk------------");
    // Change background color randomly
    setState(() {
      _backgroundColor = Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0);
    });
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize - _lastProcessedPosition >= 1) { // 1 byte
          await _sendAudioChunk(_currentRecordingPath!, false);
          _chunkIndex++;
        }
      }
    }
  }

  Future<void> _sendAudioChunk(String filePath, bool isFinal) async {
    try {
      final file = File(filePath);
      final raf = file.openSync(mode: FileMode.read);
      raf.setPositionSync(_lastProcessedPosition);
      
      int endPosition = _lastProcessedPosition + 1; // 1 byte chunk
      if (isFinal) {
        endPosition = await file.length();
      }
      
      final chunkSize = endPosition - _lastProcessedPosition;
      final bytes = raf.readSync(chunkSize);
      raf.closeSync();

      final uri = Uri.parse('https://api.coindesk.com/v1/bpi/currentprice.json');
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['recording_id'] = _recordingId.toString();
      request.fields['chunk_index'] = _chunkIndex.toString();
      request.fields['is_final'] = isFinal.toString();
      
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        bytes,
        filename: 'chunk_${_recordingId}_$_chunkIndex.m4a',
      ));

      final response = await request.send();
      _lastProcessedPosition = endPosition;
      print(_lastProcessedPosition);
      if (response.statusCode == 200) {
        print('Chunk $_chunkIndex sent successfully');
        // _lastProcessedPosition = endPosition;
      } else {
        print('Failed to send chunk $_chunkIndex. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending audio chunk: $e');
    }
  }

  Future<void> _playAudio(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _recordSub?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Add this line
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    size: 50,
                    color: _isRecording ? Colors.red : Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    _isRecording ? 'Recording in progress...' : 'Press the button to start recording',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _audioFiles.length,
              itemBuilder: (context, index) {
                final file = File(_audioFiles[index]);
                return ListTile(
                  title: Text(file.path.split('/').last),
                  trailing: IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () => _playAudio(_audioFiles[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
        child: Icon(_isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }
}
