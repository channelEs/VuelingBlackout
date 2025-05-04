import 'package:flutter/material.dart';

void showCustomNotification(BuildContext context) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder:
        (_) => Positioned(
          bottom: 32,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0B6),
                border: Border.all(color: const Color(0xFFFFF0B6)),
                borderRadius: BorderRadius.circular(12),
              ),

              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: const Color(0xFFAC8100),
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Your connection is too weak.',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF8C6900),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You might not receive critical messages, please look for a more populated zone.',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Color(0xFF8C6900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  // Insert it
  overlay.insert(overlayEntry);

  // Remove it after some duration
  //Future.delayed(const Duration(seconds: 3)).then((_) => overlayEntry.remove());
}
