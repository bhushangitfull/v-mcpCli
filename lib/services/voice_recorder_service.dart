import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _currentPath = '${dir.path}/voice_input.wav';

    // Delete previous file if exists
    final file = File(_currentPath!);
    if (await file.exists()) await file.delete();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,   // Whisper expects 16kHz
        numChannels: 1,      // mono
      ),
      path: _currentPath!,
    );
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop(); // returns file path
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  void dispose() {
    _recorder.dispose();
  }
}
