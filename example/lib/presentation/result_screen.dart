import 'dart:io';
import 'package:flutter/material.dart';
import 'package:opencv_edge_detection_example/presentation/choose_options_screen.dart';
import 'package:opencv_edge_detection_example/utils/util.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    this.croppedFilePath,
    this.borderRadius = 10,
    this.borderColor = const Color(0xFF34B6FF),
    this.width = 3,
  });

  final String? croppedFilePath;
  final double borderRadius;
  final Color borderColor;
  final double width;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late String? _croppedFilePath;
  int _reloadKey = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _croppedFilePath = widget.croppedFilePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _croppedFilePath == null
              ? const SizedBox.shrink()
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Stack(
                      children: [
                        Image.file(
                          File(_croppedFilePath!),
                          fit: BoxFit.contain,
                          key: ValueKey(_reloadKey),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                widget.borderRadius,
                              ),
                              border: Border.all(
                                color: widget.borderColor,
                                width: widget.width,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: _rotate,
                      child: const Text('Rotate'),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: () => _onTap(context),
                      child: const Text('Retry'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _isLoading
              ? SizedBox.expand(
                child: Center(child: CircularProgressIndicator()),
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> _rotate() async {
    try {
      if (_croppedFilePath == null || _isLoading) {
        return;
      }
      _isLoading = true;
      setState(() {});
      await rotateImage(File(_croppedFilePath!), angle: 90);

      if (!mounted) {
        return;
      }

      imageCache.clear();
      imageCache.clearLiveImages();

      setState(() {
        _reloadKey++;
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTap(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ChooseOptionsScreen()),
      (_) => false,
    );
  }
}
