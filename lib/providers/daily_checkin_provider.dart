import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colosynth/services/daily_checkin_service.dart';

final dailyCheckInProvider =
    NotifierProvider<DailyCheckInNotifier, DailyCheckInState>(
        DailyCheckInNotifier.new);

class DailyCheckInNotifier extends Notifier<DailyCheckInState> {
  @override
  DailyCheckInState build() {
    return DailyCheckInService.instance.state;
  }

  void refresh() {
    DailyCheckInService.instance.refreshState();
    state = DailyCheckInService.instance.state;
  }

  Future<bool> claimToday() async {
    final success = await DailyCheckInService.instance.claimToday(ref: ref);
    if (success) {
      state = DailyCheckInService.instance.state;
    }
    return success;
  }

  Future<bool> claimDoubleWithAd() async {
    final success = await DailyCheckInService.instance.claimDoubleWithAd(ref: ref);
    if (success) {
      state = DailyCheckInService.instance.state;
    }
    return success;
  }

  Future<bool> claimTodayWithDoubleAd() async {
    final success = await DailyCheckInService.instance.claimTodayWithDoubleAd(ref: ref);
    if (success) {
      state = DailyCheckInService.instance.state;
    }
    return success;
  }

  Future<bool> makeUpWithAd() async {
    final success = await DailyCheckInService.instance.makeUpWithAd(ref: ref);
    if (success) {
      state = DailyCheckInService.instance.state;
    }
    return success;
  }

  Future<bool> claimTomorrowWithAd() async {
    final success = await DailyCheckInService.instance.claimTomorrowWithAd(ref: ref);
    if (success) {
      state = DailyCheckInService.instance.state;
    }
    return success;
  }
}
