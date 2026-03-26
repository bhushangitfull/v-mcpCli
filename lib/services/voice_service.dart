// lib/services/voice_service.dart
//
// pubspec.yaml dependencies:
//   record: ^5.2.0
//   path_provider: ^2.0.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceService {
  // ─── Paths ───────────────────────────────────────────────────────────────────
  // Using venv python directly — no PYTHONPATH needed
  static const String _venvPython =
      '/media/sakshi/A8C21512C214E67A/whisper-env/bin/python3';
  static const String _whisperModels =
      '/media/sakshi/A8C21512C214E67A/whisper-models';

  // ─── Internal state ──────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentAudioPath;

  // ─── Permission ──────────────────────────────────────────────────────────────

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  // ─── Recording ───────────────────────────────────────────────────────────────

  Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[VoiceService] No microphone permission');
        return false;
      }

      final dir = await getTemporaryDirectory();
      _currentAudioPath =
          '${dir.path}/voice_input_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // Whisper expects 16kHz
          numChannels: 1,    // mono
          bitRate: 256000,
        ),
        path: _currentAudioPath!,
      );

      debugPrint('[VoiceService] Recording started → $_currentAudioPath');
      return true;
    } catch (e) {
      debugPrint('[VoiceService] startRecording error: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      debugPrint('[VoiceService] Recording stopped → $path');
      return path;
    } catch (e) {
      debugPrint('[VoiceService] stopRecording error: $e');
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentAudioPath != null) {
        final file = File(_currentAudioPath!);
        if (await file.exists()) await file.delete();
        debugPrint('[VoiceService] Recording cancelled, file deleted');
        _currentAudioPath = null;
      }
    } catch (e) {
      debugPrint('[VoiceService] cancelRecording error: $e');
    }
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // ─── Local Whisper Transcription ─────────────────────────────────────────────

  Future<String?> transcribeLocally(
    String audioFilePath, {
    String model = 'base',
    String language = 'en',
  }) async {
    try {
      // Verify audio file exists
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        debugPrint('[VoiceService] Audio file not found: $audioFilePath');
        return null;
      }

      // Verify venv python exists
      final pythonBin = File(_venvPython);
      if (!await pythonBin.exists()) {
        debugPrint('[VoiceService] Python not found at: $_venvPython');
        debugPrint('[VoiceService] Run: ls /media/sakshi/A8C21512C214E67A/whisper-env/bin/');
        return null;
      }

      debugPrint('[VoiceService] Transcribing: $audioFilePath');
      debugPrint('[VoiceService] Using python: $_venvPython');

      final pythonScript = '''
import sys
import warnings
warnings.filterwarnings("ignore")

try:
    import whisper
except ImportError as e:
    print(f"ERR_IMPORT: {e}", file=sys.stderr)
    sys.exit(1)

try:
    model = whisper.load_model("$model", download_root="$_whisperModels")
except Exception as e:
    print(f"ERR_MODEL: {e}", file=sys.stderr)
    sys.exit(1)

try:
    result = model.transcribe(
        "$audioFilePath",
        language="$language",
        fp16=False,
        verbose=False,
    )
    text = result["text"].strip()
    print(text)
except Exception as e:
    print(f"ERR_TRANSCRIBE: {e}", file=sys.stderr)
    sys.exit(1)
''';

      final result = await Process.run(
        _venvPython,         // use venv python directly
        ['-c', pythonScript],
        environment: {
          ...Platform.environment,
          // No PYTHONPATH needed — venv python finds its own packages
        },
        stdoutEncoding: const SystemEncoding(),
        stderrEncoding: const SystemEncoding(),
      );

      if (result.stderr.toString().isNotEmpty) {
        debugPrint('[VoiceService] stderr: ${result.stderr}');
      }

      if (result.exitCode != 0) {
        debugPrint(
            '[VoiceService] Whisper failed (exit ${result.exitCode}): ${result.stderr}');
        return null;
      }

      final transcript = result.stdout.toString().trim();
      debugPrint('[VoiceService] Transcript: "$transcript"');

      _cleanupFile(audioFilePath);

      return transcript.isEmpty ? null : transcript;
    } catch (e) {
      debugPrint('[VoiceService] transcribeLocally error: $e');
      return null;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  void _cleanupFile(String audioFilePath) {
    try {
      final file = File(audioFilePath);
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint('[VoiceService] Deleted temp file: $audioFilePath');
      }
      if (_currentAudioPath == audioFilePath) {
        _currentAudioPath = null;
      }
    } catch (e) {
      debugPrint('[VoiceService] _cleanupFile error: $e');
    }
  }

  void dispose() {
    try {
      _recorder.dispose();
      debugPrint('[VoiceService] Disposed');
    } catch (e) {
      debugPrint('[VoiceService] dispose error: $e');
    }
  }
}