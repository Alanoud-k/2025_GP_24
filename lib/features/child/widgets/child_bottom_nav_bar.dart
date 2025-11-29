// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// class ChildBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   const ChildBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     const double barHeight = 80;
//     const double iconSize = 28; // base icon size
//     const double homeOuter = 80;
//     const double homeInner = 62;

//     const Color kPrimary = Color(0xFF67AFAC);
//     const Color kUnselected = Color(0xFF555555);

//     return SizedBox(
//       height: barHeight + 50,
//       child: Stack(
//         alignment: Alignment.bottomCenter,
//         clipBehavior: Clip.none,
//         children: [
//           // bottom bar background
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               height: barHeight,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(26),
//                   topRight: Radius.circular(26),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 10,
//                     offset: Offset(0, -2),
//                   )
//                 ],
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 28),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // left section
//                     Row(
//                       children: [
//                         _NavItem(
//                           asset: "assets/icons/Reward.svg",
//                           label: "Prizes",
//                           isSelected: currentIndex == 0,
//                           iconSize: iconSize,
//                           onTap: () => onTap(0),
//                         ),
//                         // const SizedBox(width: 20),
//                         // _NavItem(
//                         //   asset: "assets/icons/Game.svg",
//                         //   label: "Game",
//                         //   isSelected: currentIndex == 1,
//                         //   iconSize: iconSize,
//                         //   onTap: () => onTap(1),
//                         // ),
//                       ],
//                     ),

//                     // right section
//                     Row(
//                       children: [
//                         _NavItem(
//                           asset: "assets/icons/Card.svg",
//                           label: "Card",
//                           isSelected: currentIndex == 3,
//                           iconSize: iconSize,
//                           onTap: () => onTap(3),
//                         ),
//                         const SizedBox(width: 20),
//                         _NavItem(
//                           asset: "assets/icons/More.svg",
//                           label: "More",
//                           isSelected: currentIndex == 4,
//                           iconSize: iconSize,
//                           onTap: () => onTap(4),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           // home floating button
//           Positioned(
//             top: 10,
//             child: GestureDetector(
//               onTap: () => onTap(2),
//               child: Container(
//                 width: homeOuter,
//                 height: homeOuter,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.12),
//                       blurRadius: 12,
//                       offset: const Offset(0, 5),
//                     ),
//                   ],
//                 ),
//                 child: Center(
//                   child: Container(
//                     width: homeInner,
//                     height: homeInner,
//                     decoration: BoxDecoration(
//                       color: currentIndex == 2
//                           ? kPrimary
//                           : const Color(0xFFCCCCCC),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Center(
//                       child: SvgPicture.asset(
//                         "assets/icons/home.svg",
//                         width: iconSize,
//                         height: iconSize,
//                         colorFilter: const ColorFilter.mode(
//                           Colors.white,
//                           BlendMode.srcIn,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // nav item with icon + label
// class _NavItem extends StatelessWidget {
//   final String asset;
//   final String label;
//   final bool isSelected;
//   final double iconSize;
//   final VoidCallback onTap;

//   const _NavItem({
//     required this.asset,
//     required this.label,
//     required this.isSelected,
//     required this.iconSize,
//     required this.onTap,
//   });

//   static const Color kPrimary = Color(0xFF67AFAC);
//   static const Color kUnselected = Color(0xFF555555);

//   @override
//   Widget build(BuildContext context) {
//     final Color color = isSelected ? kPrimary : kUnselected;

//     // adjust Game icon only
//     double adjustedSize = iconSize;
//     if (asset.contains("Game")) {
//       adjustedSize = iconSize - 4; // fix visual size
//     }

//     return GestureDetector(
//       onTap: onTap,
//       child: SizedBox(
//         width: 60, // fixed width for stable layout
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             SizedBox(
//               height: 32,
//               child: Center(
//                 child: SvgPicture.asset(
//                   asset,
//                   width: adjustedSize,
//                   height: adjustedSize,
//                   colorFilter: ColorFilter.mode(
//                     color,
//                     BlendMode.srcIn,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    const double barHeight = 80; // ارتفاع الشريط
    const double iconSize = 28;

    return Container(
      height: barHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // توزيع المسافات بالتساوي
          children: [
            // 1. Prizes Button
            _NavItem(
              asset: "assets/icons/Reward.svg",
              label: "Prizes",
              isSelected: currentIndex == 0,
              iconSize: iconSize,
              onTap: () => onTap(0),
            ),

            // زر Game تم إلغاؤه حسب طلبك

            // 2. Home Button (مميز ومدمج في الشريط)
            _HomeNavItem(
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),

            // 3. Card Button
            _NavItem(
              asset: "assets/icons/Card.svg",
              label: "Card",
              isSelected: currentIndex == 3,
              iconSize: iconSize,
              onTap: () => onTap(3),
            ),

            // 4. More Button
            _NavItem(
              asset: "assets/icons/More.svg",
              label: "More",
              isSelected: currentIndex == 4,
              iconSize: iconSize,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

// ويدجت خاصة لزر الهوم لجعله مميزاً
class _HomeNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _HomeNavItem({
    required this.isSelected,
    required this.onTap,
  });

  static const Color kPrimary = Color(0xFF67AFAC);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // التعديل هنا: تحديد عرض ثابت 60 مثل بقية الأزرار
      child: SizedBox( 
        width: 60, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: kPrimary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  "assets/icons/home.svg",
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Home",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? kPrimary : const Color(0xFF555555),
              ),
            )
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
      child: Container(
        color: Colors.transparent, // لتسهيل الضغط
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: SvgPicture.asset(
                  asset,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(
                    color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
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