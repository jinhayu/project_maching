import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // 날짜 포맷팅용
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
  final String projectId;

  Milestone({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.color,
    required this.isCompleted,
    required this.projectId,
  });
}

class TeamSchedulerPage extends StatefulWidget {
  const TeamSchedulerPage({Key? key}) : super(key: key);

  @override
  State<TeamSchedulerPage> createState() => TeamSchedulerPageState();
}

// SchedulerPage에서 접근할 수 있도록 public class로 유지
class TeamSchedulerPageState extends State<TeamSchedulerPage> {
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  fln.FlutterLocalNotificationsPlugin();
  final SupabaseClient _client = Supabase.instance.client;

  List<Milestone> _milestones = [];
  bool _isLoading = true;

  // 🎨 커스텀 간트 차트 디자인 설정
  final double _dayWidth = 60.0; // 하루 칸의 너비
  final double _rowHeight = 50.0; // 행 높이
  final double _headerHeight = 40.0; // 날짜 헤더 높이

  @override
  void initState() {
    super.initState();
    _configureLocalNotifications();
    _loadMilestones();
  }

  void _configureLocalNotifications() {
    tz.initializeTimeZones();
    try { tz.setLocalLocation(tz.getLocation('Asia/Seoul')); } catch (_) { tz.setLocalLocation(tz.local); }
    const androidSettings = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = fln.InitializationSettings(android: androidSettings);
    flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  // --- Supabase 로드 ---
  Future<void> _loadMilestones() async {
    if (_client.auth.currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('team_milestones')
          .select()
          .eq('user_id', userId)
          .order('start_date', ascending: true);

      final List<Milestone> loaded = [];
      for (var data in response) {
        loaded.add(Milestone(
          id: data['id'].toString(),
          title: data['title'] ?? '제목 없음',
          startDate: DateTime.parse(data['start_date']).toLocal(),
          endDate: DateTime.parse(data['end_date']).toLocal(),
          color: _hexToColor(data['color_hex'] ?? '#2196F3'),
          isCompleted: data['is_completed'] ?? false,
          projectId: data['project_id'] ?? 'default',
        ));
      }
      if (mounted) setState(() => _milestones = loaded);
    } catch (e) {
      debugPrint('Error loading milestones: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // 💡 경고 해결: 이 함수가 이제 addMilestone 내부에서 호출됩니다.
  Future<void> _scheduleNotification(Milestone m) async {
    final scheduledDate = tz.TZDateTime(
        tz.local, m.endDate.year, m.endDate.month, m.endDate.day, 9, 0, 0);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      m.id.hashCode, '마일스톤 마감: ${m.title}',
      '${DateFormat('MM/dd').format(m.endDate)} 마감입니다.',
      scheduledDate,
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails('team_channel', '팀 알림', importance: fln.Importance.max, priority: fln.Priority.high),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // --- 마일스톤 추가 (외부 호출용) ---
  void addMilestone() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 마일스톤 추가'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: '마일스톤 제목'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;

              // Navigator.pop을 위해 context를 미리 저장할 필요는 없으나,
              // 비동기 작업 후 사용을 위해 mounted 체크가 필수입니다.

              try {
                final userId = _client.auth.currentUser!.id;
                final start = DateTime.now();
                final end = start.add(const Duration(days: 7));

                final res = await _client.from('team_milestones').insert({
                  'user_id': userId,
                  'project_id': 'row1',
                  'title': titleController.text,
                  'start_date': start.toUtc().toIso8601String(),
                  'end_date': end.toUtc().toIso8601String(),
                  'is_completed': false,
                  'color_hex': '#2196F3',
                }).select();

                if (res.isNotEmpty && mounted) {
                  // 💡 수정: 여기서 _scheduleNotification을 호출하여 경고를 해결하고 기능을 동작시킵니다.
                  final newM = Milestone(
                      id: res[0]['id'].toString(),
                      title: titleController.text,
                      startDate: start,
                      endDate: end,
                      color: const Color(0xFF2196F3),
                      isCompleted: false,
                      projectId: 'row1'
                  );
                  _scheduleNotification(newM);
                }

                await _loadMilestones();

                // 💡 수정: 비동기 작업 후 context 사용 전 mounted 체크
                if (!mounted) return;
                Navigator.pop(ctx);
              } catch (e) {
                debugPrint('Error adding: $e');
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _deleteMilestone(Milestone m) async {
    try {
      await _client.from('team_milestones').delete().eq('id', m.id);
      await _loadMilestones();
      flutterLocalNotificationsPlugin.cancel(m.id.hashCode);
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }

  void _toggleCompletion(Milestone m) async {
    try {
      await _client.from('team_milestones').update({'is_completed': !m.isCompleted}).eq('id', m.id);
      await _loadMilestones();
    } catch (e) {
      debugPrint('Error toggling: $e');
    }
  }

  // 🖌️ 직접 구현한 간트 차트 위젯
  Widget _buildCustomGanttChart() {
    if (_milestones.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('등록된 마일스톤이 없습니다.')));
    }

    DateTime minDate = DateTime.now().subtract(const Duration(days: 7));
    DateTime maxDate = DateTime.now().add(const Duration(days: 21));

    if (_milestones.isNotEmpty) {
      final earliest = _milestones.map((e) => e.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
      final latest = _milestones.map((e) => e.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
      minDate = earliest.subtract(const Duration(days: 2));
      maxDate = latest.add(const Duration(days: 5));
    }

    final int totalDays = maxDate.difference(minDate).inDays + 1;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. 날짜 헤더
            Container(
              height: _headerHeight,
              color: Colors.grey.shade100,
              child: Row(
                children: List.generate(totalDays, (index) {
                  final date = minDate.add(Duration(days: index));
                  final isToday = DateUtils.isSameDay(date, DateTime.now());
                  return Container(
                    width: _dayWidth,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      // 💡 수정: withOpacity 대신 withValues 사용
                      color: isToday ? Colors.blue.withValues(alpha: 0.1) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.blue : Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('E', 'ko_KR').format(date),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // B. 간트 바 (Stack 사용)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  height: (_milestones.isEmpty ? 1 : _milestones.length) * _rowHeight,
                  width: totalDays * _dayWidth,
                  child: Stack(
                    children: [
                      // B-1. 배경 그리드
                      Row(
                        children: List.generate(totalDays, (index) {
                          final date = minDate.add(Duration(days: index));
                          final isToday = DateUtils.isSameDay(date, DateTime.now());
                          return Container(
                            width: _dayWidth,
                            decoration: BoxDecoration(
                              border: Border(right: BorderSide(color: Colors.grey.shade200)),
                              // 💡 수정: withValues 사용
                              color: isToday ? Colors.blue.withValues(alpha: 0.05) : null,
                            ),
                          );
                        }),
                      ),

                      // B-2. 마일스톤 바 렌더링
                      if (_milestones.isEmpty)
                        const Center(child: Text("등록된 마일스톤이 없습니다.", style: TextStyle(color: Colors.grey)))
                      else
                        ..._milestones.asMap().entries.map((entry) {
                          final index = entry.key;
                          final m = entry.value;

                          final startOffset = m.startDate.difference(minDate).inDays * _dayWidth;
                          final durationDays = m.endDate.difference(m.startDate).inDays + 1;
                          final barWidth = durationDays * _dayWidth;

                          return Positioned(
                            top: index * _rowHeight + 10,
                            left: startOffset,
                            width: barWidth > 0 ? barWidth : _dayWidth,
                            height: _rowHeight - 20,
                            child: GestureDetector(
                              onTap: () => _toggleCompletion(m),
                              child: Tooltip(
                                message: "${m.title}\n${DateFormat('MM/dd').format(m.startDate)} ~ ${DateFormat('MM/dd').format(m.endDate)}",
                                child: Container(
                                  decoration: BoxDecoration(
                                    // 💡 수정: withValues 사용
                                    color: m.isCompleted ? Colors.grey : m.color.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      // 💡 수정: withValues 사용
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(1, 1))
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    m.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        overflow: TextOverflow.ellipsis
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;
    if (_milestones.isNotEmpty) {
      progress = _milestones.where((m) => m.isCompleted).length / _milestones.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          const Text('팀 간트 차트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildCustomGanttChart(),

          const SizedBox(height: 24),

          const Text('프로젝트 진행률', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          LinearProgressIndicator(value: progress, color: Colors.blue, backgroundColor: Colors.grey[300], minHeight: 10),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% 완료'),

          const SizedBox(height: 24),
          const Text('마일스톤 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          if (_milestones.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('목록이 비어있습니다.')))
          else
            Column(
              children: _milestones.map((m) => ListTile(
                title: Text(m.title, style: TextStyle(decoration: m.isCompleted ? TextDecoration.lineThrough : null, color: m.isCompleted ? Colors.grey : Colors.black)),
                subtitle: Text('${DateFormat('MM/dd').format(m.startDate)} ~ ${DateFormat('MM/dd').format(m.endDate)}'),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteMilestone(m)),
                onTap: () => _toggleCompletion(m),
              )).toList(),
            )
        ],
      ),
    );
  }
}