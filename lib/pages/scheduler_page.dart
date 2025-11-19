import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'team_scheduler_page.dart';

// --- 개인 일정 모델 ---
class Event {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;
  final String projectId;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.isCompleted,
    required this.projectId,
  });
}

class SchedulerPage extends StatefulWidget {
  const SchedulerPage({Key? key}) : super(key: key);

  @override
  State<SchedulerPage> createState() => _SchedulerPageState();
}

class _SchedulerPageState extends State<SchedulerPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isTeamView = false;
  bool _isLoading = true;

  final GlobalKey<TeamSchedulerPageState> _teamSchedulerKey = GlobalKey();
  final SupabaseClient _client = Supabase.instance.client;

  Map<DateTime, List<Event>> _eventsMap = {};
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  fln.FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // 캘린더 초기화 시 시간 정보 제거 (UTC 자정)
    _selectedDay = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _configureLocalNotifications();
    _loadEvents();
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

  // --- Supabase에서 개인 일정 로드 ---
  Future<void> _loadEvents() async {
    if (_client.auth.currentUser == null) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('personal_events')
          .select('id, title, event_date, status, project_id')
          .eq('user_id', userId);

      final Map<DateTime, List<Event>> tempMap = {};

      for (var data in response) {
        // 💡 FIX: DB(UTC) 시간을 가져와서 내 핸드폰 시간(Local)으로 변환
        final eventDateTime = DateTime.parse(data['event_date'] as String).toLocal();

        // 변환된 로컬 시간을 기준으로 캘린더 키(UTC 자정) 생성
        final dateKey = DateTime.utc(eventDateTime.year, eventDateTime.month, eventDateTime.day);

        final event = Event(
          id: data['id'].toString(),
          title: data['title'] as String,
          date: dateKey,
          isCompleted: data['status'] == 'completed',
          projectId: data['project_id'].toString(),
        );

        if (tempMap[dateKey] == null) {
          tempMap[dateKey] = [];
        }
        tempMap[dateKey]!.add(event);
      }

      if (mounted) {
        setState(() {
          _eventsMap = tempMap;
        });
      }
    } catch (e) {
      debugPrint('일정 로드 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    // 캘린더에서 선택된 날짜에 맞는 이벤트 리스트 반환
    final dateKey = DateTime.utc(day.year, day.month, day.day);
    return _eventsMap[dateKey] ?? [];
  }

  Future<void> _scheduleNotification(Event event) async {
    final scheduledDate = tz.TZDateTime(
        tz.local, event.date.year, event.date.month, event.date.day, 9, 0, 0);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      event.id.hashCode,
      '오늘 일정: ${event.date.month}월 ${event.date.day}일',
      event.title,
      scheduledDate,
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
            'personal_events_channel',
            '개인 일정',
            channelDescription: '개인 일정 알림',
            importance: fln.Importance.max,
            priority: fln.Priority.high
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _showAddEventDialog() {
    if (_client.auth.currentUser == null) return;
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final localSelectedDate = _selectedDay.toLocal().toString().split(' ')[0];
        return AlertDialog(
          title: Text('새 일정 추가 ($localSelectedDate)'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: '일정 제목'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                try {
                  final userId = _client.auth.currentUser!.id;
                  // 저장할 때는 UTC로 변환해서 저장 (표준)
                  final eventDateUtc = _selectedDay.toUtc().toIso8601String();

                  final response = await _client.from('personal_events').insert({
                    'user_id': userId,
                    'project_id': 'default',
                    'title': titleController.text,
                    'event_date': eventDateUtc,
                    'status': 'pending',
                  }).select('id');

                  if (response.isNotEmpty && mounted) {
                    final newId = response.first['id'].toString();
                    final newEvent = Event(
                        id: newId,
                        title: titleController.text,
                        date: _selectedDay,
                        isCompleted: false,
                        projectId: 'default'
                    );
                    _scheduleNotification(newEvent);
                  }

                  await _loadEvents();
                  if (!mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('추가 오류: $e');
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _toggleEventCompletion(DateTime dateKey, Event event) async {
    final newStatus = event.isCompleted ? 'pending' : 'completed';
    try {
      await _client.from('personal_events')
          .update({'status': newStatus})
          .eq('id', event.id);
      await _loadEvents();
    } catch (e) {
      debugPrint('상태 변경 실패: $e');
    }
  }

  void _deleteEvent(DateTime dateKey, Event event) async {
    try {
      await _client.from('personal_events').delete().eq('id', event.id);
      await _loadEvents();
      flutterLocalNotificationsPlugin.cancel(event.id.hashCode);
    } catch (e) {
      debugPrint('삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.grey.shade600;

    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isTeamView ? '팀 스케줄러' : '개인 스케줄러'),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: _isTeamView ? iconColor.withValues(alpha: 0.5) : iconColor),
              onPressed: _isTeamView
                  ? () => _teamSchedulerKey.currentState?.addMilestone()
                  : _showAddEventDialog,
            ),
            Switch(
              value: _isTeamView,
              onChanged: (val) {
                setState(() {
                  _isTeamView = val;
                  if(!val) _loadEvents();
                });
              },
              inactiveTrackColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isTeamView
            ? TeamSchedulerPage(key: _teamSchedulerKey)
            : _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onFormatChanged: (format) => setState(() => _calendarFormat = format),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Divider(),
              if (_getEventsForDay(_selectedDay).isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("일정이 없습니다.", style: TextStyle(color: Colors.grey)),
                ),
              ..._getEventsForDay(_selectedDay).map((event) {
                return ListTile(
                  leading: Icon(
                    event.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: event.isCompleted ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    event.title,
                    style: TextStyle(
                      decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                      color: event.isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteEvent(_selectedDay, event),
                  ),
                  onTap: () => _toggleEventCompletion(_selectedDay, event),
                );
              }),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}