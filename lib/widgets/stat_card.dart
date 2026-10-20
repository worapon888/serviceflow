import 'package:flutter/material.dart';

/// การ์ดสรุปสถิติจำนวนงาน (StatCard) สำหรับแสดงผลในแถวแนวนอน 4 ใบ
class StatCard extends StatelessWidget {
  final String label;
  final String count;
  final String trend;
  final bool isTrendPositive;
  final IconData icon;
  final Color themeColor;

  const StatCard({
    super.key,
    required this.label,
    required this.count,
    required this.trend,
    required this.isTrendPositive,
    required this.icon,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ไอคอนประจำสถานะ
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 17,
                  color: themeColor,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ป้ายชื่อสถานะ (ใช้ FittedBox ป้องกัน Text Overflow)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ตัวเลขจำนวนงาน
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: themeColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),

            // เปอร์เซ็นต์ Trend พร้อมลูกศรขึ้น/ลง
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: (isTrendPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isTrendPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                    size: 13,
                    color: isTrendPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isTrendPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
