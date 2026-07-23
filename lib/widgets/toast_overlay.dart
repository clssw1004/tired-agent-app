import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/toast_provider.dart';
import 'package:tired_agent_app/theme.dart';

class ToastOverlay extends StatelessWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final toasts = context.watch<ToastProvider>();
    return Stack(
      children: toasts.toasts.map((toast) {
        Color backgroundColor;
        switch (toast.type) {
          case ToastType.success:
            backgroundColor = AppColors.success;
          case ToastType.error:
            backgroundColor = AppColors.danger;
          case ToastType.info:
            backgroundColor = AppColors.backgroundElement;
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
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<ToastProvider>().dismiss(toast.id),
                      child: const Icon(Icons.close, color: AppColors.text, size: 18),
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
