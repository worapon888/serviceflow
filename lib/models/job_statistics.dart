/// โมเดลข้อมูลสถิติจำนวนงานสำหรับแสดงผลบน Dashboard และ Filter Chips
class JobStatistics {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  const JobStatistics({
    this.total = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  factory JobStatistics.fromJson(Map<String, dynamic> json) {
    return JobStatistics(
      total: (json['total'] ?? json['totalCount'] ?? 0) as int,
      pending: (json['pending'] ?? json['pendingCount'] ?? 0) as int,
      inProgress: (json['inProgress'] ?? json['inProgressCount'] ?? 0) as int,
      completed: (json['completed'] ?? json['completedCount'] ?? 0) as int,
      cancelled: (json['cancelled'] ?? json['cancelledCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
      'cancelled': cancelled,
    };
  }
}
