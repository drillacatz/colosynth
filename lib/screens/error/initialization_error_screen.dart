import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colosynth/screens/theme/tokens.dart';

class InitializationErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  const InitializationErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const cyan = AppColors.pureWhite;
    const violet = AppColors.sketchGray;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: violet,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'INITIALIZATION FAILED',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'System initialization interrupted. We encountered a critical error during startup.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildErrorBox(context),
                const SizedBox(height: 40),
                _buildRetryButton(),
                const SizedBox(height: 16),
                _buildExitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sketchGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TECHNICAL DETAILS',
            style: TextStyle(
              color: AppColors.sketchGray,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return InkWell(
      onTap: onRetry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.sketchGray),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'RETRY INITIALIZATION',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitButton() {
    return TextButton(
      onPressed: () => SystemNavigator.pop(),
      child: Text(
        'EXIT TO DESKTOP',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
