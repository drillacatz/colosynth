import 'package:flutter/material.dart';
import 'package:colosynth/screens/theme/tokens.dart';
import 'package:colosynth/services/sprite_repository.dart';

enum StoreSection { recruit, shop, daily, ink, paint, exp, synth }

@immutable
class InkBundle {
  const InkBundle({
    required this.ink,
    required this.label,
    required this.productId,
    required this.style,
    required this.usdFallback,
  });

  final int ink;
  final String label;
  final String productId;
  final PBStyle style;
  final String usdFallback;
}

@immutable
class PaintBundle {
  const PaintBundle({
    required this.paint,
    required this.label,
    required this.productId,
    required this.style,
    required this.usdFallback,
  });

  final int paint;
  final String label;
  final String productId;
  final PBStyle style;
  final String usdFallback;
}

@immutable
class AdFreeBundle {
  const AdFreeBundle({
    required this.productId,
    required this.label,
    required this.usdFallback,
  });

  final String productId;
  final String label;
  final String usdFallback;
}

@immutable
class ComboBundle {
  const ComboBundle({
    required this.productId,
    required this.label,
    required this.ink,
    required this.paint,
    required this.style,
    required this.usdFallback,
  });

  final String productId;
  final String label;
  final int ink;
  final int paint;
  final PBStyle style;
  final String usdFallback;
}

@immutable
class StarterBundle {
  const StarterBundle({
    required this.productId,
    required this.label,
    required this.ink,
    required this.paint,
    required this.usdFallback,
  });

  final String productId;
  final String label;
  final int ink;
  final int paint;
  final String usdFallback;
}

@immutable
class ExpItemBundle {
  const ExpItemBundle({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.quantity,
    this.usePaint = false,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
  final int quantity;
  final bool usePaint;

  String get assetPath => SpriteRepository.storeItem(id);
}

class StoreData {
  static const List<InkBundle> inkBundles = [
    InkBundle(
      ink: 12000,
      label: '12,000 INK',
      productId: 'colosynth_ink_12000',
      style: PBStyle.white,
      usdFallback: r'$0.99',
    ),
    InkBundle(
      ink: 70000,
      label: '70,000 INK',
      productId: 'colosynth_ink_70000',
      style: PBStyle.dark,
      usdFallback: r'$4.99',
    ),
    InkBundle(
      ink: 160000,
      label: '160,000 INK',
      productId: 'colosynth_ink_160000',
      style: PBStyle.dark,
      usdFallback: r'$9.99',
    ),
    InkBundle(
      ink: 380000,
      label: '380,000 INK',
      productId: 'colosynth_ink_380000',
      style: PBStyle.dark,
      usdFallback: r'$19.99',
    ),
    InkBundle(
      ink: 1100000,
      label: '1,100,000 INK',
      productId: 'colosynth_ink_1100000',
      style: PBStyle.dark,
      usdFallback: r'$49.99',
    ),
    InkBundle(
      ink: 2500000,
      label: '2,500,000 INK',
      productId: 'colosynth_ink_2500000',
      style: PBStyle.dark,
      usdFallback: r'$99.99',
    ),
  ];

  static const List<PaintBundle> paintBundles = [
    PaintBundle(
      paint: 15,
      label: '15 PAINT',
      productId: 'colosynth_paint_15',
      style: PBStyle.white,
      usdFallback: r'$0.99',
    ),
    PaintBundle(
      paint: 85,
      label: '85 PAINT',
      productId: 'colosynth_paint_85',
      style: PBStyle.dark,
      usdFallback: r'$4.99',
    ),
    PaintBundle(
      paint: 190,
      label: '190 PAINT',
      productId: 'colosynth_paint_190',
      style: PBStyle.dark,
      usdFallback: r'$9.99',
    ),
    PaintBundle(
      paint: 420,
      label: '420 PAINT',
      productId: 'colosynth_paint_420',
      style: PBStyle.dark,
      usdFallback: r'$19.99',
    ),
    PaintBundle(
      paint: 1150,
      label: '1,150 PAINT',
      productId: 'colosynth_paint_1150',
      style: PBStyle.dark,
      usdFallback: r'$49.99',
    ),
    PaintBundle(
      paint: 2500,
      label: '2,500 PAINT',
      productId: 'colosynth_paint_2500',
      style: PBStyle.dark,
      usdFallback: r'$99.99',
    ),
  ];

  static const List<ComboBundle> comboBundles = [
    ComboBundle(
      productId: 'colosynth_combo_gearup',
      label: 'GEARUP BUNDLE',
      ink: 30000,
      paint: 300,
      style: PBStyle.dark,
      usdFallback: r'$29.99',
    ),
    ComboBundle(
      productId: 'colosynth_combo_deep',
      label: 'DEEP BUNDLE',
      ink: 120000,
      paint: 800,
      style: PBStyle.dark,
      usdFallback: r'$69.99',
    ),
  ];

  static const starterBundle = StarterBundle(
    productId: 'colosynth_starter_bundle',
    label: 'STARTER BUNDLE',
    ink: 8000,
    paint: 350,
    usdFallback: r'$9.99',
  );

  static const int synthKeyPaintPrice = 50;

  static const adFreeBundle = AdFreeBundle(
    productId: 'colosynth_ad_free',
    label: 'AD FREE',
    usdFallback: r'$4.99',
  );

  static const List<int> dailyInkStepAmounts = [200, 700, 1050, 1050];


  static const List<ExpItemBundle> expItemBundles = [

    ExpItemBundle(
      id: 'exp_book_common',
      name: 'COMMON BOOK',
      description: 'Used to level up characters.',
      cost: 500,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_book_rare',
      name: 'RARE BOOK',
      description: 'Standard character upgrade.',
      cost: 1500,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_book_epic',
      name: 'EPIC BOOK',
      description: 'High grade character upgrade.',
      cost: 4000,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_book_legendary',
      name: 'MYTHIC BOOK',
      description: 'Ultimate character upgrade.',
      cost: 15,
      quantity: 1,
      usePaint: true,
    ),


    ExpItemBundle(
      id: 'exp_hammer_common',
      name: 'IRON HAMMER',
      description: 'Basic equipment upgrade.',
      cost: 400,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_hammer_rare',
      name: 'STEEL HAMMER',
      description: 'Reliable equipment upgrade.',
      cost: 1200,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_hammer_epic',
      name: 'TITAN HAMMER',
      description: 'Powerful equipment upgrade.',
      cost: 3000,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_hammer_legendary',
      name: 'GOD HAMMER',
      description: 'Peak equipment upgrade.',
      cost: 12,
      quantity: 1,
      usePaint: true,
    ),


    ExpItemBundle(
      id: 'exp_note_common',
      name: 'COMMON NOTE',
      description: 'Basic Synth level upgrade.',
      cost: 300,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_note_rare',
      name: 'RARE NOTE',
      description: 'Reliable Synth enhancement.',
      cost: 900,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_note_epic',
      name: 'EPIC NOTE',
      description: 'Powerful Synth amplifier.',
      cost: 2500,
      quantity: 1,
    ),
    ExpItemBundle(
      id: 'exp_note_legendary',
      name: 'MYTHIC NOTE',
      description: 'Ultimate Synth mastery.',
      cost: 10,
      quantity: 1,
      usePaint: true,
    ),
  ];
}
