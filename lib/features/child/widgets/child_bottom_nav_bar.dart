import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_app/l10n/app_localizations.dart';

class ChildBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ChildBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const double barHeight = 80;
    const double iconSize = 26;
    const double homeOuter = 80;
    const double homeInner = 62;

    const Color kPrimary = Color(0xFF37C4BE); // لون الطفل
    const Color kUnselected = Color(0xFF555555);

    return SizedBox(
      height: barHeight + 50,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // خلفية الشريط بتصميم الأب
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: Container(
              height: barHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 28), // تطابق مع الأب
                child: Row(
                  children: [
                    // القسم الأيسر
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NavItem(
                            asset: "assets/icons/More.svg",
                            label: l10n.more,
                            isSelected: currentIndex == 0,
                            iconSize: iconSize,
                            onTap: () => onTap(0),
                          ),
                          _NavItem(
                            asset: "assets/icons/qr.svg",
                            label: l10n.pay,
                            isSelected: currentIndex == 1,
                            iconSize: iconSize,
                            onTap: () => onTap(1),
                          ),
                        ],
                      ),
                    ),

                    // القسم الأيمن
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NavItem(
                            iconData: Icons.payments_rounded,
                            label: l10n.requestMoney,
                            isSelected: currentIndex == 3,
                            iconSize: iconSize,
                            onTap: () => onTap(3),
                          ),
                          _NavItem(
                            iconData: Icons.emoji_events_rounded, // كأس البطولة
                            label: l10n.prizes,
                            isSelected: currentIndex == 4,
                            iconSize: iconSize,
                            onTap: () => onTap(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // زر الهوم العائم (رقم 2)
          PositionedDirectional(
            top: 10,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: homeOuter,
                height: homeOuter,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: homeInner,
                    height: homeInner,
                    decoration: BoxDecoration(
                      color: currentIndex == 2 ? kPrimary : const Color(0xFFCCCCCC),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/icons/home.svg",
                        width: iconSize,
                        height: iconSize,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String? asset;
  final IconData? iconData;
  final String label;
  final bool isSelected;
  final double iconSize;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    this.asset,
    this.iconData,
    required this.label,
    required this.isSelected,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? const Color(0xFF37C4BE) : const Color(0xFF555555);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75, // زيادة العرض قليلاً لاستيعاب النصوص الطويلة مثل Request Money
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconData != null)
              Icon(iconData, size: iconSize, color: color)
            else if (asset != null)
              SvgPicture.asset(
                asset!,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2, // جعل النص ينزل لسطر ثاني إذا كان طويلاً
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.1, // تقليل المسافة بين السطرين ليكون الشكل أجمل
              ),
            ),
          ],
        ),
      ),
    );
  }
}