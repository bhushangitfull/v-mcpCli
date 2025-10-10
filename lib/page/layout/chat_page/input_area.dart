import 'package:chatmcp/page/layout/widgets/mcp_tools.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chatmcp/utils/platform.dart';
import 'package:file_picker/file_picker.dart';
import 'package:chatmcp/widgets/upload_menu.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:chatmcp/widgets/ink_icon.dart';
import 'package:chatmcp/utils/color.dart';
import 'package:chatmcp/page/layout/widgets/conv_setting.dart';
import 'dart:io';
import 'dart:async';

class SubmitData {
  final String text;
  final List<PlatformFile> files;

  SubmitData(this.text, this.files);

  @override
  String toString() {
    return 'SubmitData(text: $text, files: $files)';
  }
}

enum InputMode { text, voice }

class InputArea extends StatefulWidget {
  final bool isComposing;
  final bool disabled;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<SubmitData> onSubmitted;
  final VoidCallback? onCancel;
  final ValueChanged<List<PlatformFile>>? onFilesSelected;
  final bool autoFocus;

  const InputArea({
    super.key,
    required this.isComposing,
    required this.disabled,
    required this.onTextChanged,
    required this.onSubmitted,
    this.onFilesSelected,
    this.onCancel,
    this.autoFocus = false,
  });

  @override
  State<InputArea> createState() => InputAreaState();
}

class InputAreaState extends State<InputArea> with SingleTickerProviderStateMixin {
  List<PlatformFile> _selectedFiles = [];
  final TextEditingController textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTextFieldFocused = false;
  bool _isImeComposing = false;
  InputMode _currentMode = InputMode.text;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Voice recording state
  Process? _recordProcess;
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Transcription state
  bool _isTranscribing = false;
  bool _whisperAvailable = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _focusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _focusNode.hasFocus;
      });
    });

    if (!kIsMobile && widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }

    _checkWhisperAvailability();
  }

  @override
  void didUpdateWidget(InputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!kIsMobile && widget.autoFocus && !oldWidget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    _recordingTimer?.cancel();
    _stopRecording();
    super.dispose();
  }

  Future<void> _checkWhisperAvailability() async {
    try {
      final result = await Process.run('which', ['whisper']);
      setState(() {
        _whisperAvailable = result.exitCode == 0;
      });
      debugPrint('Whisper available: $_whisperAvailable');
    } catch (e) {
      debugPrint('Error checking Whisper: $e');
      setState(() {
        _whisperAvailable = false;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check if arecord is available
      final checkArecord = await Process.run('which', ['arecord']);
      if (checkArecord.exitCode != 0) {
        _showError('arecord not found. Please install alsa-utils');
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '/tmp/recording_$timestamp.wav';

      // Start recording with arecord
      _recordProcess = await Process.start('arecord', [
        '-f', 'cd', // CD quality (44.1kHz, 16-bit, stereo)
        '-t', 'wav', // WAV format
        _currentRecordingPath!,
      ]);

      // Listen to errors
      _recordProcess!.stderr.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('arecord stderr: $data');
      });

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });

      _showSuccess('Recording started');
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showError('Failed to start recording: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    if (_recordProcess != null) {
      _recordProcess!.kill(ProcessSignal.sigint);
      await _recordProcess!.exitCode;
      _recordProcess = null;
    }

    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (_isRecording) {
      setState(() {
        _isRecording = false;
      });

      // Check if file was created
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('Recording saved: $_currentRecordingPath (${fileSize} bytes)');

          if (fileSize > 0) {
            // Transcribe if Whisper is available
            if (_whisperAvailable) {
              await _transcribeAudio(_currentRecordingPath!);
            } else {
              // Just attach the audio file
              await _attachAudioFile(_currentRecordingPath!);
            }
          } else {
            _showError('Recording is empty');
          }
        } else {
          _showError('Recording file not found');
        }
      }
    }
  }

  Future<void> _attachAudioFile(String audioPath) async {
    try {
      final file = File(audioPath);
      final platformFile = PlatformFile(
        name: 'voice_recording_${DateTime.now().millisecondsSinceEpoch}.wav',
        size: await file.length(),
        path: audioPath,
      );

      setState(() {
        _selectedFiles = [..._selectedFiles, platformFile];
      });
      widget.onFilesSelected?.call(_selectedFiles);

      _showInfo('Audio recording attached. Install Whisper for auto-transcription.');
      _toggleMode(InputMode.text);
    } catch (e) {
      _showError('Failed to attach audio: ${e.toString()}');
    }
  }

  Future<void> _transcribeAudio(String audioPath) async {
    setState(() {
      _isTranscribing = true;
    });

    try {
      debugPrint('Starting transcription of: $audioPath');

      final tempDir = Directory.systemTemp.createTempSync('whisper_');
      final outputPath = '${tempDir.path}/transcription';

      final result = await Process.run('whisper', [
        audioPath,
        '--model',
        'base',
        '--output_format',
        'txt',
        '--output_dir',
        tempDir.path,
        '--language',
        'en',
      ]);

      debugPrint('Whisper exit code: ${result.exitCode}');

      if (result.exitCode == 0) {
        final transcriptionFile = File('$outputPath.txt');
        if (await transcriptionFile.exists()) {
          final transcription = await transcriptionFile.readAsString();

          await tempDir.delete(recursive: true);

          if (transcription.trim().isNotEmpty) {
            textController.text = transcription.trim();
            widget.onTextChanged(transcription.trim());

            _showSuccess('Transcription completed!');
            _toggleMode(InputMode.text);
          } else {
            _showError('No speech detected in recording');
          }
        } else {
          _showError('Transcription file not found');
        }
      } else {
        _showError('Transcription failed');
      }
    } catch (e) {
      debugPrint('Error transcribing: $e');
      _showError('Transcription error: ${e.toString()}');
    } finally {
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _toggleMode(InputMode mode) {
    if (_currentMode == mode) return;

    // Stop recording if switching away from voice mode
    if (_currentMode == InputMode.voice && _isRecording) {
      _stopRecording();
    }

    setState(() {
      _currentMode = mode;
    });

    if (mode == InputMode.text) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void requestFocus() {
    if (!kIsMobile && mounted) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.any);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = [..._selectedFiles, ...result.files];
        });
        widget.onFilesSelected?.call(_selectedFiles);
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = [..._selectedFiles, ...result.files];
        });
        widget.onFilesSelected?.call(_selectedFiles);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onFilesSelected?.call(_selectedFiles);
  }

  void _afterSubmitted() {
    textController.clear();
    _selectedFiles.clear();
    _currentRecordingPath = null;
  }

  String _truncateFileName(String fileName) {
    const int maxLength = 20;
    if (fileName.length <= maxLength) return fileName;

    final extension = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
    final nameWithoutExt = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;

    if (nameWithoutExt.length <= maxLength - extension.length - 3) {
      return fileName;
    }

    final truncatedLength = (maxLength - extension.length - 3) ~/ 2;
    return '${nameWithoutExt.substring(0, truncatedLength)}'
        '...'
        '${nameWithoutExt.substring(nameWithoutExt.length - truncatedLength)}'
        '$extension';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getInputAreaBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isTextFieldFocused && _currentMode == InputMode.text
              ? const Color(0xFF77E2D7)
              : AppColors.getInputAreaBorderColor(context).withOpacity(0.3),
          width: _isTextFieldFocused && _currentMode == InputMode.text ? 2.5 : 1.5,
        ),
      ),
      margin: const EdgeInsets.only(left: 12.0, right: 12.0, top: 2.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeTab(
                    label: 'TEXT INPUT',
                    icon: CupertinoIcons.chat_bubble_text,
                    isSelected: _currentMode == InputMode.text,
                    onTap: () => _toggleMode(InputMode.text),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModeTab(
                    label: 'VOICE INPUT',
                    icon: CupertinoIcons.mic,
                    isSelected: _currentMode == InputMode.voice,
                    onTap: () => _toggleMode(InputMode.voice),
                  ),
                ),
              ],
            ),
          ),

          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Opacity(
                    opacity: 1.0 - _slideAnimation.value,
                    child: Transform.translate(offset: Offset(-50 * _slideAnimation.value, 0), child: _buildTextInputArea(context, l10n)),
                  ),
                  Opacity(
                    opacity: _slideAnimation.value,
                    child: Transform.translate(offset: Offset(50 * (1.0 - _slideAnimation.value), 0), child: _buildVoiceInputArea(context, l10n)),
                  ),
                ],
              );
            },
          ),

          if (_currentMode == InputMode.text) _buildTextActionButtons(context, l10n),
        ],
      ),
    );
  }

  Widget _buildModeTab({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF77E2D7).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFF77E2D7) : Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? const Color(0xFF77E2D7) : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.5,
                  color: isSelected ? const Color(0xFF77E2D7) : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInputArea(BuildContext context, AppLocalizations l10n) {
    if (_currentMode != InputMode.text && _slideAnimation.value > 0.5) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_selectedFiles.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0),
            constraints: const BoxConstraints(maxHeight: 65),
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  final isImage =
                      file.extension?.toLowerCase() == 'jpg' ||
                      file.extension?.toLowerCase() == 'jpeg' ||
                      file.extension?.toLowerCase() == 'png' ||
                      file.extension?.toLowerCase() == 'gif';

                  final isAudio =
                      file.extension?.toLowerCase() == 'm4a' ||
                      file.extension?.toLowerCase() == 'mp3' ||
                      file.extension?.toLowerCase() == 'wav' ||
                      file.extension?.toLowerCase() == 'ogg' ||
                      file.extension?.toLowerCase() == 'flac' ||
                      file.name.startsWith('voice_recording');

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.getInputAreaFileItemBackgroundColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.getInputAreaBorderColor(context), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            child: Row(
                              children: [
                                Icon(
                                  isImage
                                      ? Icons.image
                                      : isAudio
                                      ? Icons.mic
                                      : Icons.insert_drive_file,
                                  size: 16,
                                  color: AppColors.getInputAreaFileIconColor(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _truncateFileName(file.name),
                                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _removeFile(index),
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                                child: Icon(Icons.close, size: 14, color: AppColors.getInputAreaIconColor(context)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: AppColors.getInputAreaBackgroundColor(context)),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  if (HardwareKeyboard.instance.isShiftPressed) {
                    return KeyEventResult.ignored;
                  }

                  if (_isImeComposing) {
                    return KeyEventResult.ignored;
                  }

                  if (widget.isComposing && textController.text.trim().isNotEmpty) {
                    widget.onSubmitted(SubmitData(textController.text, _selectedFiles));
                    _afterSubmitted();
                  }
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                enabled: !widget.disabled,
                controller: textController,
                focusNode: _focusNode,
                onChanged: widget.onTextChanged,
                maxLines: 5,
                minLines: 1,
                onAppPrivateCommand: (value, map) {
                  debugPrint('onAppPrivateCommand: $value');
                },
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return null;
                },
                textInputAction: kIsMobile ? TextInputAction.newline : TextInputAction.done,
                onSubmitted: null,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    _isImeComposing = newValue.composing != TextRange.empty;
                    return newValue;
                  }),
                ],
                keyboardType: TextInputType.multiline,
                style: TextStyle(fontSize: 14.0, color: AppColors.getInputAreaTextColor(context)),
                scrollPhysics: const BouncingScrollPhysics(),
                decoration: InputDecoration(
                  hintText: l10n.askMeAnything,
                  hintStyle: TextStyle(fontSize: 14.0, color: AppColors.getInputAreaHintTextColor(context)),
                  filled: true,
                  fillColor: AppColors.getInputAreaBackgroundColor(context),
                  hoverColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                  isDense: true,
                ),
                cursorColor: AppColors.getInputAreaCursorColor(context),
                mouseCursor: WidgetStateMouseCursor.textable,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInputArea(BuildContext context, AppLocalizations l10n) {
    if (_currentMode != InputMode.voice && _slideAnimation.value < 0.5) {
      return const SizedBox.shrink();
    }

    return Center(
      // Add this wrapper
      child: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Add this
          children: [
            if (_isTranscribing) ...[
              // Transcribing animation
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF77E2D7))),
              ),
              const SizedBox(height: 24),
              Text(
                'Transcribing audio...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 8),
              Text('This may take a moment', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
            ] else ...[
              // Waveform animation when recording
              if (_isRecording) SizedBox(height: 80, child: Center(child: _buildWaveform())),

              const SizedBox(height: 24),

              // Recording timer
              if (_isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_recordingSeconds),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              const SizedBox(height: 24),

              // Record button
              GestureDetector(
                onTap: widget.disabled ? null : _toggleRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red.withOpacity(0.2) : const Color(0xFF77E2D7).withOpacity(0.2),
                    border: Border.all(color: _isRecording ? Colors.red : const Color(0xFF77E2D7), width: 3),
                  ),
                  child: Icon(
                    _isRecording ? CupertinoIcons.stop_fill : CupertinoIcons.mic_fill,
                    size: 36,
                    color: _isRecording ? Colors.red : const Color(0xFF77E2D7),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Instructions
              Text(
                _isRecording ? 'Tap to stop Listening' : 'Tap to start Listening',
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),

              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Recording from microphone...',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(15, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 10.0, end: 30.0 + (index % 4) * 10.0),
          builder: (context, value, child) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 50)),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: value,
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2)),
            );
          },
          onEnd: () {
            // Loop the animation
            if (mounted && _isRecording) {
              setState(() {});
            }
          },
        );
      }),
    );
  }

  Widget _buildTextActionButtons(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 10.0, top: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!widget.disabled)
            Row(
              children: [
                FutureBuilder<int>(
                  future: ProviderManager.mcpServerProvider.installedServersCount,
                  builder: (context, snapshot) {
                    return const McpTools();
                  },
                ),
                const SizedBox(width: 10),
                if (kIsMobile) ...[
                  UploadMenu(disabled: widget.disabled, onPickImages: _pickImages, onPickFiles: _pickFiles),
                ] else ...[
                  InkIcon(
                    icon: CupertinoIcons.plus_app,
                    onTap: () {
                      if (widget.disabled) return;
                      _pickFiles();
                    },
                    disabled: widget.disabled,
                    hoverColor: Theme.of(context).hoverColor,
                    tooltip: l10n.uploadFile,
                  ),
                ],
                const SizedBox(width: 10),
                const ConvSetting(),
              ],
            ),
          if (!widget.disabled) ...[
            const Spacer(),
            InkIcon(
              icon: CupertinoIcons.arrow_up_circle,
              onTap: () {
                if (widget.disabled || textController.text.trim().isEmpty) {
                  return;
                }
                widget.onSubmitted(SubmitData(textController.text, _selectedFiles));
                _afterSubmitted();
              },
              tooltip: l10n.send,
            ),
          ] else ...[
            const Spacer(),
            InkIcon(
              icon: CupertinoIcons.stop,
              onTap: widget.onCancel != null
                  ? () {
                      widget.onCancel!();
                    }
                  : null,
              tooltip: l10n.cancel,
            ),
          ],
        ],
      ),
    );
  }
}
