import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_app/l10n/app_localizations.dart';

class ParentBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ParentBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const double barHeight = 70;
    const double iconSize = 26;

    const Color kPrimary = Color(0xFF67AFAC);
    const Color kUnselected = Color(0xFF555555);

    return Container(
      height: barHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        // Converted to BorderRadiusDirectional for RTL support (topStart / topEnd)
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(26),
          topEnd: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        // EdgeInsets.symmetric is directional-agnostic, safe for RTL/LTR
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              asset: "assets/icons/home.svg",
              label: l10n.home,
              isSelected: currentIndex == 0,
              iconSize: iconSize,
              onTap: () => onTap(0),
            ),

            // Temporary icon until chores.svg is added
            _NavItem(
              asset: "assets/icons/Reward.svg",
              label: l10n.chores_action,
              isSelected: currentIndex == 1,
              iconSize: iconSize,
              onTap: () => onTap(1),
            ),

            _NavItem(
              asset: "assets/icons/Gift.svg",
              label: l10n.rewards,
              isSelected: currentIndex == 2,
              iconSize: iconSize,
              onTap: () => onTap(2),
            ),

            _NavItem(
              asset: "assets/icons/More.svg",
              label: l10n.more,
              isSelected: currentIndex == 3,
              iconSize: iconSize,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String asset;
  final String label;
  final bool isSelected;
  final double iconSize;
  final VoidCallback onTap;

  const _NavItem({
    required this.asset,
    required this.label,
    required this.isSelected,
    required this.iconSize,
    required this.onTap,
  });

  static const Color kPrimary = Color(0xFF67AFAC);
  static const Color kUnselected = Color(0xFF555555);

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? kPrimary : kUnselected;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              asset,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}