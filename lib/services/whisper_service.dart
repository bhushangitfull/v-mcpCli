import 'dart:io';
import 'dart:convert';

class WhisperService {
  // Transcribe a wav file using local whisper
  Future<String> transcribe(String audioFilePath) async {
    try {
      final result = await Process.run(
        'python3',
        [
          '-c',
          '''
import whisper, sys, json
model = whisper.load_model("base")
result = model.transcribe("$audioFilePath")
print(result["text"].strip())
          '''
        ],
      );

      if (result.exitCode != 0) {
        throw Exception('Whisper error: ${result.stderr}');
      }

      return result.stdout.toString().trim();
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }
}