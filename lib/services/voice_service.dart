import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoiceService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission first
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          debugPrint('Microphone permission denied');
          return false;
        }
      }

      // Check if recording is supported
      if (!await _audioRecorder.hasPermission()) {
        debugPrint('No recording permission');
        return false;
      }

      // Create a temporary file path
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/recording_$timestamp.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      debugPrint('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      debugPrint('Recording stopped: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      await _audioRecorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  /// Transcribe audio using OpenAI Whisper API
  Future<String?> transcribeWithWhisper(
    String audioFilePath,
    String apiKey, {
    String baseUrl = 'https://api.openai.com/v1',
  }) async {
    try {
      final audioFile = File(audioFilePath);
      if (!await audioFile.exists()) {
        debugPrint('Audio file does not exist: $audioFilePath');
        return null;
      }

      // Create multipart request
      final uri = Uri.parse('$baseUrl/audio/transcriptions');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $apiKey';
      
      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFilePath,
          filename: 'audio.m4a',
        ),
      );
      
      // Add model parameter
      request.fields['model'] = 'whisper-1';

      // Send request
      debugPrint('Sending transcription request to Whisper API...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final transcription = jsonResponse['text'] as String?;
        debugPrint('Transcription successful: $transcription');
        return transcription;
      } else {
        debugPrint('Whisper API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error transcribing audio: $e');
      return null;
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }
}