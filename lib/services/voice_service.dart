import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
 
class VoiceService {
  // ─── Paths (your second partition) ──────────────────────────────────────────
  static const String _whisperLibs =
      '/media/admin-s/A8C21512C214E67A/whisper-env';
  static const String _whisperModels =
      '/media/admin-s/A8C21512C214E67A/whisper-models';
 
  // ─── Internal state ──────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentAudioPath;
 
  // ─── Permission ──────────────────────────────────────────────────────────────
 
  /// On Linux, mic permission is managed by PulseAudio/system, not Flutter.
  /// Returns true if the mic is accessible to the app.
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }
 
  /// Attempts to request mic permission. On Linux this is effectively the
  /// same as hasPermission() since there is no permission dialog.
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }
 
  // ─── Recording ───────────────────────────────────────────────────────────────
 
  /// Starts recording from the microphone.
  /// Returns true if recording started successfully.
  Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('[VoiceService] No microphone permission');
        return false;
      }
 
      // Audio saved to system temp dir — only a few MB, safe for full partition
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
 
  /// Stops recording and returns the path to the saved .wav file.
  /// Returns null if recording failed or was never started.
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
 
  /// Cancels recording and deletes the audio file without transcribing.
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
 
  /// Returns true if currently recording.
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }
 
  // ─── Local Whisper Transcription ─────────────────────────────────────────────
 
  /// Transcribes [audioFilePath] using local Whisper running as a subprocess.
  ///
  /// [model]    — whisper model size: tiny | base | small | medium | large
  ///              'base' is recommended: good accuracy, fast on CPU, ~140MB
  /// [language] — ISO language code e.g. 'en', 'hi', 'fr', 'de'
  ///              pass null to let Whisper auto-detect the language
  ///
  /// Returns the transcript string, or null if transcription failed.
Future<String?> transcribeLocally(
    String audioFilePath, {
    String model = 'base',
    String language = 'en',
  }) async {
    try {
      // Verify the audio file exists before calling Python
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        debugPrint('[VoiceService] Audio file not found: $audioFilePath');
        return null;
      }
 
      debugPrint('[VoiceService] Transcribing: $audioFilePath');
      debugPrint('[VoiceService] Model: $model | Language: $language');
 
      final pythonScript = '''
import sys
import warnings
warnings.filterwarnings("ignore")
 
try:
    import whisper
except ImportError:
    print("ERR_IMPORT: openai-whisper not found. Check PYTHONPATH.", file=sys.stderr)
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
        'python3',
        ['-c', pythonScript],
        environment: {
          ...Platform.environment,
          'PYTHONPATH': _whisperLibs,
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
 
      // Clean up audio file after successful transcription
      _cleanupFile(audioFilePath);
 
      return transcript.isEmpty ? null : transcript;
    } catch (e) {
      debugPrint('[VoiceService] transcribeLocally error: $e');
      return null;
    }
  }
  /// Deletes a temporary audio file if present.
  void _cleanupFile(String audioFilePath) {
    try {
      final file = File(audioFilePath);
      if (file.existsSync()) {
        file.deleteSync();
        debugPrint('[VoiceService] Deleted temp audio file: $audioFilePath');
      }
      if (_currentAudioPath == audioFilePath) {
        _currentAudioPath = null;
      }
    } catch (e) {
      debugPrint('[VoiceService] _cleanupFile error: $e');
    }
  }
}