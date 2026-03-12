import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class StarOverlayLoading extends StatefulWidget {
  final bool isLoading;

  const StarOverlayLoading({
    super.key,
    required this.isLoading,
  });

  @override
  State<StarOverlayLoading> createState() => _StarOverlayLoadingState();
}

class _StarOverlayLoadingState extends State<StarOverlayLoading> {
  final List<String> messages = [
    "Analyzing your body stats...",
    "Calculating BMI...",
    "Estimating muscle & fat ratio...",
    "Checking hydration & bone mass...",
    "Finalizing health insights...",
  ];

  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) {
      _startMessageRotation();
    }
  }

  @override
  void didUpdateWidget(covariant StarOverlayLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _startMessageRotation();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _stopMessageRotation();
    }
  }

  void _startMessageRotation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1300), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % messages.length;
      });
    });
  }

  void _stopMessageRotation() {
    _timer?.cancel();
    _currentIndex = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Lottie.asset(
                "images/Star.json",
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),
          ),

          Positioned.fill(
            child: Lottie.asset(
              "images/Star.json",
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),

          // Rotating message at center
          Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  messages[_currentIndex],
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
