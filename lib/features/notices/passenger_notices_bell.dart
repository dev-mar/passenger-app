import 'package:flutter/material.dart';

import '../../core/theme/app_ui_tokens.dart';
import '../home/widgets/passenger_home_look.dart';

class PassengerNoticesBell extends StatelessWidget {
  const PassengerNoticesBell({
    super.key,
    required this.unread,
    required this.tooltip,
    required this.onPressed,
  });

  final int unread;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final count = unread < 0 ? 0 : unread;
    final label = count > 99 ? '99+' : '$count';
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.circleButton,
              minHeight: AppSizes.circleButton,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Semantics(
                      label: label,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: PassengerHomeLook.gps,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0xF2070605),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF1A1200),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
