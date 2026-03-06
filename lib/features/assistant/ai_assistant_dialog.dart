import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_colors.dart';
import 'llm_navigation_service.dart';

class AiAssistantDialog extends StatefulWidget {
  const AiAssistantDialog({super.key});

  @override
  State<AiAssistantDialog> createState() => _AiAssistantDialogState();
}

class _AiAssistantDialogState extends State<AiAssistantDialog>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  String _statusMessage = 'Tap the mic or type a command';
  int _listenSession = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening && mounted) {
            final text = _textController.text;
            setState(() => _isListening = false);
            _pulseCtrl.stop();
            _pulseCtrl.reset();
            if (text.isNotEmpty) {
              _processCommand(text);
            }
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusMessage = 'Speech error — try again or type below';
          });
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }
      },
    );
    if (mounted) setState(() {});
  }

  void _listen() async {
    if (_isProcessing) return;

    if (!_isListening) {
      if (!_speechAvailable) {
        setState(() => _statusMessage = 'Speech not available on this device');
        return;
      }
      // Cancel any prior session to avoid stale callbacks
      _speech.cancel();
      _listenSession++;
      final currentSession = _listenSession;
      setState(() {
        _isListening = true;
        _statusMessage = 'Listening\u2026';
        _textController.clear();
      });
      _pulseCtrl.repeat(reverse: true);
      _speech.listen(
        onResult: (val) {
          // Ignore results from a stale/prior session
          if (!mounted || currentSession != _listenSession) return;
          setState(() {
            _textController.text = val.recognizedWords;
            _statusMessage = 'Hearing: "${val.recognizedWords}"';
          });
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
        _statusMessage = 'Processing…';
      });
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      if (_textController.text.isNotEmpty) {
        _processCommand(_textController.text);
      }
    }
  }

  void _processCommand(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Finding "$text"…';      _textController.clear();    });

    final route = await LlmNavigationService.getRouteFromText(text);

    if (!mounted) return;

    if (route != null) {
      // Capture the router before popping
      final router = GoRouter.of(context);
      Navigator.of(context).pop(); // Close dialog
      router.go(route);
    } else {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Couldn\'t find that — try again';
      });
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _textController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(28),
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button row
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 12),
            const Text('Voice Assistant',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              _statusMessage,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Text input
            TextField(
              controller: _textController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. "Go to Inverter 1"',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.primaryLighter,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: AppColors.primary, size: 22),
                  onPressed: () => _processCommand(_textController.text),
                ),
              ),
              onSubmitted: _processCommand,
            ),
            const SizedBox(height: 20),
            // Mic button
            ScaleTransition(
              scale: _isListening ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
              child: GestureDetector(
                onTap: _listen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? AppColors.alert
                        : _isProcessing
                            ? Colors.grey
                            : AppColors.primary,
                    boxShadow: [
                      if (_isListening)
                        BoxShadow(
                          color: AppColors.alert.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                    ],
                  ),
                  child: _isProcessing
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick-action chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _chip('Dashboard'),
                _chip('Inverters'),
                _chip('Alerts'),
                _chip('Sensors'),
                _chip('My Plants'),
                _chip('Exports'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
      backgroundColor: AppColors.primaryLighter,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _processCommand(label),
    );
  }
}