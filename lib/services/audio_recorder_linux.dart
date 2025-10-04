import 'package:flutter/services.dart';

class AudioRecorderLinux {
  static const platform = MethodChannel('com.yourapp/audio_recorder');

  static Future<String?> startRecording() async {
    try {
      final String result = await platform.invokeMethod('startRecording');
      return result;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final String path = await platform.invokeMethod('stopRecording');
      return path;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}