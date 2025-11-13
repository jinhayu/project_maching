import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'team_scheduler_page.dart';

// --- 개인 일정 모델 ---
class Event {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.isCompleted,
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

  final GlobalKey<TeamSchedulerPageState> _teamSchedulerKey = GlobalKey();

  Map<DateTime, List<Event>> _eventsMap = {};
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  fln.FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _initDummyEvents();
    _configureLocalNotifications();
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

  void _initDummyEvents() {
    final today = DateTime.now();
    final todayKey = DateTime.utc(today.year, today.month, today.day);

    _eventsMap = {
      todayKey: [
        Event(id: '1', title: '회의', date: todayKey, isCompleted: false)
      ]
    };
  }

  List<Event> _getEventsForDay(DateTime day) {
    final dateKey = DateTime.utc(day.year, day.month, day.day);
    return _eventsMap[dateKey] ?? [];
  }

  Future<void> _scheduleNotification(Event event) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      event.date.year,
      event.date.month,
      event.date.day,
      9, // 오전 9시로 예약
      0,
      0,
    );

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
          priority: fln.Priority.high,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _showAddEventDialog() {
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
            TextButton(
              onPressed: () {
                if (titleController.text.isEmpty) return;

                final dateKey = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);

                final newEvent = Event(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  date: dateKey,
                  isCompleted: false,
                );

                setState(() {
                  _eventsMap[dateKey] ??= [];
                  _eventsMap[dateKey]!.add(newEvent);
                });

                // 비동기 알림 예약
                _scheduleNotification(newEvent);

                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _toggleEventCompletion(DateTime dateKey, Event event) {
    final key = DateTime.utc(dateKey.year, dateKey.month, dateKey.day);
    if (_eventsMap.containsKey(key)) {
      final index = _eventsMap[key]!.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        setState(() {
          _eventsMap[key]![index] = Event(
            id: event.id,
            title: event.title,
            date: event.date,
            isCompleted: !event.isCompleted,
          );
        });
      }
    }
  }

  void _deleteEvent(DateTime dateKey, Event event) {
    setState(() {
      final key = DateTime.utc(dateKey.year, dateKey.month, dateKey.day);
      if (_eventsMap.containsKey(key)) {
        _eventsMap[key]!.removeWhere((e) => e.id == event.id);
        if (_eventsMap[key]!.isEmpty) {
          _eventsMap.remove(key);
        }
      }
    });
    flutterLocalNotificationsPlugin.cancel(event.id.hashCode);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.grey.shade600;

    // ❌ 강제 Theme 제거
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTeamView ? '팀 스케줄러' : '개인 스케줄러', style: const TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: iconColor),
            onPressed: _isTeamView
                ? () => _teamSchedulerKey.currentState?.addMilestone()
                : _showAddEventDialog, // 개인 일정 추가
            tooltip: _isTeamView ? '마일스톤 추가' : '일정 추가',
          ),
          Switch(
            value: _isTeamView,
            onChanged: (val) {
              setState(() {
                _isTeamView = val;
              });
            },
            inactiveTrackColor: Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isTeamView
          ? TeamSchedulerPage(key: _teamSchedulerKey)
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
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
            ),
            const Divider(height: 1),
            // 선택된 날짜의 일정 목록
            ..._getEventsForDay(_selectedDay).map((event) {
              return ListTile(
                title: Text(
                  event.title,
                  style: TextStyle(
                    decoration: event.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: event.isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                onTap: () => _toggleEventCompletion(_selectedDay, event),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    event.isCompleted
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                    const SizedBox(width: 8),

                    // 삭제 버튼
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteEvent(_selectedDay, event),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}