import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/toast_provider.dart';
import 'package:tired_agent_app/theme.dart';

class ToastOverlay extends StatelessWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final toasts = context.watch<ToastProvider>();
    return Stack(
      children: toasts.toasts.map((toast) {
        Color backgroundColor;
        switch (toast.type) {
          case ToastType.success:
            backgroundColor = c.success;
          case ToastType.error:
            backgroundColor = c.danger;
          case ToastType.info:
            backgroundColor = c.surface;
        }
        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.three),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppSpacing.two),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        toast.message,
                        style: TextStyle(color: c.text, fontSize: 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.read<ToastProvider>().dismiss(toast.id),
                      child: Icon(Icons.close, color: c.text, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
