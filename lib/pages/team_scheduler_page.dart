import 'package:flutter/material.dart';
// 'gantt' 접두사를 사용하도록 명시
import 'package:gantt_chart/gantt_chart.dart' as gantt;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// --- 팀 마일스톤 모델 ---
class Milestone {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;
  bool isCompleted;

  Milestone({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.color,
    this.isCompleted = false,
  });
}

// 💡 FIX: State 클래스 이름을 Public으로 변경 (SchedulerPage와의 연동을 위함)
class TeamSchedulerPage extends StatefulWidget {
  const TeamSchedulerPage({Key? key}) : super(key: key);

  @override
  State<TeamSchedulerPage> createState() => TeamSchedulerPageState();
}

class TeamSchedulerPageState extends State<TeamSchedulerPage> {
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  fln.FlutterLocalNotificationsPlugin();

  final List<Milestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _configureLocalNotifications();
    _initDummyMilestones();
  }

  void _configureLocalNotifications() {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const androidSettings = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = fln.InitializationSettings(android: androidSettings);

    flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  void _initDummyMilestones() {
    final today = DateTime.now();
    _milestones.addAll([
      Milestone(
        id: '1',
        title: 'API 개발',
        startDate: today,
        endDate: today.add(const Duration(days: 5)),
        color: Colors.blue,
      ),
      Milestone(
        id: '2',
        title: 'UI 디자인 완료',
        startDate: today.add(const Duration(days: 2)),
        endDate: today.add(const Duration(days: 10)),
        color: Colors.green,
      ),
    ]);
  }

  Future<void> _scheduleNotification(Milestone m) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      m.endDate.year,
      m.endDate.month,
      m.endDate.day,
      9, // 오전 9시 알림
      0,
      0,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      m.id.hashCode,
      '마일스톤 마감: ${m.endDate.month}월 ${m.endDate.day}일',
      m.title,
      scheduledDate,
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'team_milestones_channel',
          '팀 마일스톤',
          channelDescription: '팀 마일스톤 알림',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 💡 FIX: SchedulerPage에서 호출할 수 있도록 공개 메서드로 유지
  void addMilestone() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 마일스톤 추가'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: '마일스톤 제목'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final startDate = DateTime.now();
              final endDate = startDate.add(const Duration(days: 7));
              final newM = Milestone(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                startDate: startDate,
                endDate: endDate,
                color: Colors.purple,
              );
              setState(() {
                _milestones.add(newM);
              });
              _scheduleNotification(newM);
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _deleteMilestone(Milestone m) {
    setState(() {
      _milestones.removeWhere((element) => element.id == m.id);
    });
    flutterLocalNotificationsPlugin.cancel(m.id.hashCode);
  }

  double _calculateProgress() {
    if (_milestones.isEmpty) return 0;
    return _milestones.where((m) => m.isCompleted).length / _milestones.length;
  }

  // 💡 Deprecated된 withOpacity 대신 Color.withAlpha()를 사용하는 헬퍼 함수
  Color _withAlpha(Color color, double opacity) {
    return color.withAlpha((255 * opacity).round());
  }

  @override
  Widget build(BuildContext context) {
    // 💡 FIX: GanttAbsoluteEvent 리스트로 마일스톤을 매핑합니다. (공식 예제 클래스)
    final ganttEvents = _milestones.map((m) => gantt.GanttAbsoluteEvent(
      displayName: m.title,
      startDate: m.startDate,
      endDate: m.endDate,
    )).toList();

    // 차트 시작/최대 기간 계산
    final minDate = _milestones.isEmpty
        ? DateTime.now()
        : _milestones.map((m) => m.startDate).reduce((a, b) => a.isBefore(b) ? a : b).subtract(const Duration(days: 7));

    const maxDuration = Duration(days: 60);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ❌ REMOVE: "마일스톤 추가" 버튼은 App Bar로 이동했습니다.
          const SizedBox(height: 16),

          // --- 1. 간트 차트 (GanttChartView 위젯 사용) ---
          const Text('팀 간트 차트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          SizedBox(
            height: 300,
            // 💡 FIX: GanttChartView 위젯 사용
            child: gantt.GanttChartView(
              events: ganttEvents,
              startDate: minDate,
              maxDuration: maxDuration,

              dayWidth: 30,
              eventHeight: 40,
              showStickyArea: true,
              stickyAreaWidth: 150,

              // eventBuilder를 사용하여 색상과 상태를 시각화
              stickyAreaEventBuilder: (context, eventIndex, event, eventColor) {
                final Milestone m = _milestones[eventIndex];

                return Container(
                    decoration: BoxDecoration(
                      // 💡 FIX: withOpacity 경고 해결 (withAlpha 헬퍼 함수 사용)
                        color: m.isCompleted ? _withAlpha(Colors.green, 0.5) : _withAlpha(m.color, 0.7),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Center(
                        child: Text(
                            m.title,
                            style: const TextStyle(fontSize: 12, color: Colors.white)
                        )
                    )
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          // --- 2. 진행률 표시 ---
          const Text('프로젝트 진행률', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          LinearProgressIndicator(
            value: _calculateProgress(),
            color: Colors.blue,
            backgroundColor: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text('진행률: ${(_calculateProgress() * 100).toInt()}% 완료'),

          const SizedBox(height: 24),
          // --- 3. 마일스톤 목록 ---
          const Text('마일스톤 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Column(
            children: _milestones.map((m) {
              return ListTile(
                title: Text(
                  m.title,
                  style: TextStyle(
                    decoration: m.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: m.isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Text('기간: ${m.startDate.month}/${m.startDate.day} ~ ${m.endDate.month}/${m.endDate.day}', style: const TextStyle(color: Colors.black54)),
                leading: Icon(
                  m.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: m.color,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteMilestone(m),
                ),
                onTap: () {
                  setState(() {
                    m.isCompleted = !m.isCompleted;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}