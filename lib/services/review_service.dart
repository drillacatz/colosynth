import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _kSpKey = 'colosynth_review_requested';
  static const _kTriggerLevel = 3;
  static const _kDelay = Duration(milliseconds: 2500);

  final _review = InAppReview.instance;

  Future<void> maybeRequestReview(int accountLevel) async {
    if (accountLevel < _kTriggerLevel) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSpKey) ?? false) return;

    await Future.delayed(_kDelay);

    if (!await _review.isAvailable()) return;

    await _review.requestReview();
    await prefs.setBool(_kSpKey, true);
  }

  Future<void> requestTutorialCompletionReview() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSpKey) ?? false) return;

    await prefs.setBool(_kSpKey, true);

    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
      } else {
        await _review.openStoreListing();
      }
    } catch (_) {
      try {
        await _review.openStoreListing();
      } catch (_) {}
    }
  }
}

final reviewServiceProvider =
    Provider<ReviewService>((_) => ReviewService.instance);
