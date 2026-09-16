import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colosynth/game_data/store_data.dart';
import 'package:colosynth/providers/service_providers.dart';
import 'package:colosynth/providers/store_provider.dart';
import 'package:colosynth/providers/navigation_provider.dart';
import 'package:colosynth/services/iap_service.dart';
import 'package:colosynth/screens/store/daily_free_section.dart';
import 'package:colosynth/screens/store/ink_shop_section.dart';
import 'package:colosynth/screens/store/paint_shop_section.dart';
import 'package:colosynth/screens/store/restore_button.dart';
import 'package:colosynth/screens/store/recruit_tab_screen.dart';
import 'package:colosynth/screens/store/exp_shop_section.dart';
import 'package:colosynth/screens/store/synth_shop_section.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/guide/guide_anchor.dart';

const double _kSlant = 30.0;

class _SlopedClipper extends CustomClipper<Path> {
  const _SlopedClipper({this.reverse = false, this.referenceWidth});
  final bool reverse;
  final double? referenceWidth;

  @override
  Path getClip(Size size) {
    final rw = referenceWidth ?? size.width;
    final slant = (size.width / rw) * _kSlant;

    if (reverse) {
      return Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, slant)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height - slant)
        ..close();
    }
    return Path()
      ..moveTo(0, slant)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - slant)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_SlopedClipper old) =>
      old.reverse != reverse || old.referenceWidth != referenceWidth;
}

class _SlantedSkew extends StatelessWidget {
  const _SlantedSkew({
    required this.child,
    required this.reverse,
  });

  final Widget child;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final skewY = (reverse ? _kSlant : -_kSlant) / screenWidth;
        return Transform(
          transform: Matrix4.skewY(skewY),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  }
}

class _LedScroller extends StatefulWidget {
  const _LedScroller({
    required this.label,
    this.ledColor = Colors.white,
    this.reverse = false,
  });

  final String label;
  final Color ledColor;
  final bool reverse;

  @override
  State<_LedScroller> createState() => _LedScrollerState();
}

class _LedScrollerState extends State<_LedScroller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late double _tileWidth;

  static const double _kFontSize = 20.0;
  static const double _kSpeedPxPerMs = 55.0 / 1000.0;

  static const _textStyle = TextStyle(
    fontSize: _kFontSize,
    fontFamily: 'Bangers',
    letterSpacing: 2.5,
    height: 1.0,
  );

  @override
  void initState() {
    super.initState();
    _calcMetrics();
    final durationMs = math.max(1, (_tileWidth / _kSpeedPxPerMs).round());

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat();
  }

  void _calcMetrics() {
    final tileText = '   ${widget.label}   ';
    final painter = TextPainter(
      text: TextSpan(text: tileText, style: _textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _tileWidth = painter.width;
  }

  @override
  void didUpdateWidget(covariant _LedScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) {
      _calcMetrics();
      final durationMs = math.max(1, (_tileWidth / _kSpeedPxPerMs).round());
      _ctrl.duration = Duration(milliseconds: durationMs);
      if (!_ctrl.isAnimating) _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tileText = '   ${widget.label}   ';

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final slantWidth = math.max(screenWidth * 2.5, 1200.0);
        final slantHeight = (slantWidth / screenWidth) * _kSlant;
        final repeatCount = (_tileWidth > 0 ? (slantWidth / _tileWidth).ceil() : 10) + 4;
        final fullText = tileText * repeatCount;

        return SizedBox(
          height: 26 + _kSlant,
          child: RepaintBoundary(
            child: OverflowBox(
              maxWidth: slantWidth,
              maxHeight: 26 + slantHeight,
              alignment: Alignment.center,
              child: ClipPath(
                clipper: _SlopedClipper(
                  reverse: widget.reverse,
                  referenceWidth: screenWidth,
                ),
                child: Container(
                  width: slantWidth,
                  height: 26 + slantHeight,
                  color: const Color(0xFF0D0D0D),
                  alignment: Alignment.center,
                  child: _SlantedSkew(
                    reverse: widget.reverse,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, child) {
                        final dx = widget.reverse
                            ? -_tileWidth + (_ctrl.value * _tileWidth)
                            : -(_ctrl.value * _tileWidth);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: Text(
                        fullText,
                        maxLines: 1,
                        softWrap: false,
                        style: _textStyle.copyWith(
                          color: widget.ledColor,
                          shadows: [
                            Shadow(
                              color: widget.ledColor.withValues(alpha: 0.40),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlopedBanner extends StatelessWidget {
  const _SlopedBanner({
    required this.label,
    this.ledColor = Colors.white,
    required this.child,
    this.bgColor = const Color(0xFFFDFDFB),
    this.reverse = false,
  });

  final String label;
  final Color ledColor;
  final Widget child;
  final Color bgColor;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: _SlopedClipper(reverse: reverse),
            child: ColoredBox(color: bgColor),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LedScroller(label: label, ledColor: ledColor, reverse: reverse),
            _SlantedSkew(
              reverse: reverse,
              child: child,
            ),
            _LedScroller(label: label, ledColor: ledColor, reverse: reverse),
          ],
        ),
      ],
    );
  }
}

class _AdRemoverRow extends StatelessWidget {
  const _AdRemoverRow({required this.prices});
  final Map<String, String> prices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'REMOVE ADS',
                style: TextStyle(
                  color: const Color(0xFF888888).withValues(alpha: 0.70),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Bangers',
                  letterSpacing: 2.5,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 84,
          child: AdFreeShopCard(prices: prices),
        ),
      ],
    );
  }
}

class _StoreTabBar extends StatelessWidget {
  const _StoreTabBar({
    required this.activeTab,
    required this.onTabChanged,
  });

  final int activeTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              alignment:
                  activeTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 0.48,
                heightFactor: 0.9,
                child: Image.asset(
                  'assets/images/t1.png',
                  fit: BoxFit.fill,
                  opacity: const AlwaysStoppedAnimation(0.85),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'ITEM',
                    isSelected: activeTab == 0,
                    activeColor: Colors.white,
                    onTap: () => onTabChanged(0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'RECRUIT',
                    isSelected: activeTab == 1,
                    activeColor: Colors.white,
                    onTap: () => onTabChanged(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ComicButton.playButtonSfx();
        onTap();
      },
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 0.94,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: isSelected ? activeColor : const Color(0xFF888888),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Bangers',
              letterSpacing: 2.0,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  int _activeTab = 0;
  final _scrollCtrl = ScrollController();
  final _dailySectionKey = GlobalKey();
  final _inkSectionKey = GlobalKey();
  final _expSectionKey = GlobalKey();
  final _paintSectionKey = GlobalKey();
  final _synthSectionKey = GlobalKey();
  bool _showFloatingFreeInk = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final shouldShow = _scrollCtrl.offset > 320;
    if (shouldShow != _showFloatingFreeInk) {
      setState(() => _showFloatingFreeInk = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToDailyFree() {
    ComicButton.playButtonSfx();
    final ctx = _dailySectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        350,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _maybeScrollToSection(StoreSection section) {
    if (section == StoreSection.recruit) {
      if (_activeTab != 1) {
        setState(() => _activeTab = 1);
      }
      return;
    }

    if (_activeTab != 0) {
      setState(() => _activeTab = 0);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (section == StoreSection.daily) {
        final ctx = _dailySectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      } else if (section == StoreSection.ink) {
        final ctx = _inkSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      } else if (section == StoreSection.paint) {
        final ctx = _paintSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      } else if (section == StoreSection.exp) {
        final ctx = _expSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      } else if (section == StoreSection.synth) {
        final ctx = _synthSectionKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      } else {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Widget _animated(int index, Widget child) {
    final fromX = index.isEven ? -1.0 : 1.0;
    return child
        .animate(delay: (index * 100).ms)
        .slideX(
          begin: fromX,
          end: 0,
          duration: 460.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: 300.ms);
  }

  Widget _storeSection({
    required int index,
    required String label,
    Color ledColor = Colors.white,
    required Widget child,
    Color bgColor = const Color(0xFF141414),
    bool reverse = false,
    GlobalKey? key,
    String? anchorId,
  }) {
    Widget content = _SlopedBanner(
      label: label,
      ledColor: ledColor,
      bgColor: bgColor,
      reverse: reverse,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: child,
      ),
    );

    if (anchorId != null) {
      content = GuideAnchor(id: anchorId, child: content);
    }

    return SliverToBoxAdapter(
      key: key,
      child: _animated(index, content),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StoreSection>(storeSectionProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _maybeScrollToSection(next);
        }
      });
    });

    final prices = ref.watch(iapPricesProvider).value ?? {};
    final isSelected = ref.watch(navigationProvider) == 0;
    final dailyInk = ref.watch(dailyInkProvider).value;
    final isAdFree = ref.watch(adFreeProvider).value ?? false;
    final hasClaimableDailyInk = dailyInk != null &&
        dailyInk.slots.isNotEmpty &&
        (!dailyInk.slots[0].claimed || (isAdFree && !dailyInk.allClaimed));

    return Column(
      children: [
        const SizedBox(height: 74),
        _StoreTabBar(
          activeTab: _activeTab,
          onTabChanged: (index) {
            setState(() {
              _activeTab = index;
            });
          },
        ),
        Expanded(
          child: IndexedStack(
            index: _activeTab,
            children: [
              Stack(
                children: [
                  CustomScrollView(
                    key: ValueKey('store_screen_shop_$isSelected'),
                    controller: _scrollCtrl,
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      _storeSection(
                        key: _synthSectionKey,
                        index: 0,
                        label: 'SYNTH CRATE',
                        ledColor: Colors.white,
                        bgColor: const Color(0xFF141414),
                        reverse: true,
                        anchorId: 'store_section_synth',
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SynthSlot3Section(),
                            SizedBox(height: 20),
                            SynthCrateSection(),
                          ],
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: _AdRemoverRow(prices: prices),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      _storeSection(
                        key: _expSectionKey,
                        index: 1,
                        label: 'EXP SHOP',
                        ledColor: Colors.white,
                        bgColor: const Color(0xFF181818),
                        reverse: true,
                        anchorId: 'store_section_exp',
                        child: const ExpShopSection(),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      _storeSection(
                        key: _dailySectionKey,
                        index: 2,
                        label: 'DAILY FREE',
                        ledColor: const Color(0xFF00E5FF),
                        bgColor: const Color(0xFF141414),
                        reverse: false,
                        child: const DailyFreeSection(),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      _storeSection(
                        key: _inkSectionKey,
                        index: 3,
                        label: 'INK SHOP',
                        ledColor: Colors.white,
                        bgColor: const Color(0xFF181818),
                        reverse: true,
                        anchorId: 'store_section_ink',
                        child: InkShopSection(prices: prices),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 10)),

                      _storeSection(
                        key: _paintSectionKey,
                        index: 4,
                        label: 'PAINT SHOP',
                        ledColor: Colors.white,
                        bgColor: const Color(0xFF141414),
                        reverse: false,
                        anchorId: 'store_section_paint',
                        child: PaintShopSection(prices: prices),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Text(
                                'Purchases are non-refundable.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF888888)
                                      .withValues(alpha: 0.45),
                                  fontSize: 10,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const RestorePurchaseButton(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 20,
                    right: 18,
                    child: AnimatedScale(
                      scale: (_showFloatingFreeInk && hasClaimableDailyInk) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: GestureDetector(
                        onTap: _scrollToDailyFree,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.ink, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.ink,
                                offset: Offset(2, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.card_giftcard, size: 16, color: Color(0xFF141414)),
                              SizedBox(width: 6),
                              Text(
                                'FREE INK',
                                style: TextStyle(
                                  fontFamily: 'Bangers',
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF141414),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF141414)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const RecruitTabScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
