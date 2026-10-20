import 'package:flutter/material.dart';

/// แถบเมนูด้านล่าง (CustomBottomNavigation) พร้อมปุ่ม + ตรงกลางสำหรับสร้างงานใหม่
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onCreateJobPressed;
  final bool showCreateJobButton;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onCreateJobPressed,
    this.showCreateJobButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. หน้าหลัก
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'หน้าหลัก',
                isSelected: currentIndex == 0,
                onTap: () => onItemSelected(0),
              ),

              // 2. งาน
              _buildNavItem(
                icon: Icons.assignment_outlined,
                label: 'งาน',
                isSelected: currentIndex == 1,
                onTap: () => onItemSelected(1),
              ),

              // 3. ปุ่ม + ตรงกลาง (สร้างงานใหม่ - เฉพาะบทบาทที่มีสิทธิ์สร้างงาน)
              if (showCreateJobButton)
                GestureDetector(
                  onTap: onCreateJobPressed,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066E6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066E6).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),

              // 4. แจ้งเตือน
              _buildNavItem(
                icon: Icons.notifications_none_rounded,
                label: 'แจ้งเตือน',
                isSelected: currentIndex == 2,
                onTap: () => onItemSelected(2),
              ),

              // 5. โปรไฟล์
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'โปรไฟล์',
                isSelected: currentIndex == 3,
                onTap: () => onItemSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? const Color(0xFF0066E6) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
