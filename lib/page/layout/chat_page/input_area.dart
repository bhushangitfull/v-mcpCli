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

  // Voice recording simulation for Linux
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _focusNode.addListener(() {
      setState(() {
        _isTextFieldFocused = _focusNode.hasFocus;
      });
    });
    
    // Auto focus on desktop when autoFocus is true
    if (!kIsMobile && widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(InputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto focus on desktop when autoFocus changes to true
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
    super.dispose();
  }

  void _toggleMode(InputMode mode) {
    if (_currentMode == mode) return;
    
    setState(() {
      _currentMode = mode;
    });
    
    if (mode == InputMode.text) {
      _animationController.reverse();
      if (_isRecording) {
        _stopRecording();
      }
    } else {
      _animationController.forward();
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = [..._selectedFiles, ...result.files];
        });
        widget.onFilesSelected?.call(_selectedFiles);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio file attached: ${result.files.first.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
  }

  void _startRecording() {
    // On Linux, we'll just show UI simulation
    // In production, you could use external recording tool or service
    setState(() {
      _isRecording = true;
    });
    
    // Show info dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Recording on Linux'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isRecording = false;
              });
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isRecording = false;
              });
              _pickAudioFile();
            },
            child: const Text('Start Listening'),
          ),
        ],
      ),
    );
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
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
          // Mode selector tabs
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
          
          // Animated content area
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Text input area
                  Opacity(
                    opacity: 1.0 - _slideAnimation.value,
                    child: Transform.translate(
                      offset: Offset(-50 * _slideAnimation.value, 0),
                      child: _buildTextInputArea(context, l10n),
                    ),
                  ),
                  // Voice input area
                  Opacity(
                    opacity: _slideAnimation.value,
                    child: Transform.translate(
                      offset: Offset(50 * (1.0 - _slideAnimation.value), 0),
                      child: _buildVoiceInputArea(context, l10n),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Action buttons at bottom
          if (_currentMode == InputMode.text) _buildTextActionButtons(context, l10n),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF77E2D7).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF77E2D7)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? const Color(0xFF77E2D7)
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.5,
                  color: isSelected 
                      ? const Color(0xFF77E2D7)
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
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
                      file.extension?.toLowerCase() == 'aac';

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
                                  isImage ? Icons.image : 
                                  isAudio ? Icons.audiotrack : Icons.insert_drive_file,
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
      child: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Icon(
              CupertinoIcons.mic_circle,
              size: 80,
              color: const Color(0xFF77E2D7).withOpacity(0.5),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Voice Input',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 12),

            const SizedBox(height: 24),

            // Upload audio button
            FilledButton.icon(
              onPressed: widget.disabled ? null : _pickAudioFile,
              icon: const Icon(CupertinoIcons.music_note, size: 20),
              label: const Text('Start Listening'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF77E2D7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Submit button if audio is attached
            if (_selectedFiles.any((f) => ['mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'].contains(f.extension?.toLowerCase())))
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: FilledButton.icon(
                  onPressed: () {
                    if (textController.text.trim().isEmpty) {
                      textController.text = 'Voice message';
                    }
                    widget.onSubmitted(SubmitData(textController.text, _selectedFiles));
                    _afterSubmitted();
                    _toggleMode(InputMode.text);
                  },
                  icon: const Icon(CupertinoIcons.paperplane_fill, size: 18),
                  label: Text(l10n.send),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF77E2D7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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