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
    // Fintech-style sizes
    const double barHeight = 80;
    const double iconSize = 32;          // large icons like fintech apps
    const double homeOuter = 80;         // big floating circle
    const double homeInner = 62;         // inner filled circle

    const Color kPrimary = Color(0xFF67AFAC);
    const Color kUnselected = Color(0xFFAAAAAA);

    return SizedBox(
      height: barHeight + 45, // extra room for the bigger floating circle
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          
          // Bottom bar background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    
                    // Left icons
                    Row(
                      children: [
                        _navIcon(
                          asset: "assets/icons/Reward.svg",
                          isSelected: currentIndex == 0,
                          size: iconSize,
                          onTap: () => onTap(0),
                        ),
                        const SizedBox(width: 32),
                        _navIcon(
                          asset: "assets/icons/Game.svg",
                          isSelected: currentIndex == 1,
                          size: iconSize,
                          onTap: () => onTap(1),
                        ),
                      ],
                    ),

                    // Right icons
                    Row(
                      children: [
                        _navIcon(
                          asset: "assets/icons/Card.svg",
                          isSelected: currentIndex == 3,
                          size: iconSize,
                          onTap: () => onTap(3),
                        ),
                        const SizedBox(width: 32),
                        _navIcon(
                          asset: "assets/icons/More.svg",
                          isSelected: currentIndex == 4,
                          size: iconSize,
                          onTap: () => onTap(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Home Button (Fintech-style)
          Positioned(
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
                      color: currentIndex == 2
                          ? kPrimary
                          : const Color(0xFFEFEFEF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        "assets/icons/home.svg",
                        width: iconSize,
                        height: iconSize,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
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

  Widget _navIcon({
    required String asset,
    required bool isSelected,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: SvgPicture.asset(
          asset,
          colorFilter: ColorFilter.mode(
            isSelected ? const Color(0xFF67AFAC) : const Color(0xFFAAAAAA),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
