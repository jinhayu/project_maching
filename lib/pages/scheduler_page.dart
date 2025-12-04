import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'team_scheduler_page.dart'; // TeamSchedulerPage import

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

  // 뷰 모드 (false: 개인, true: 팀)
  bool _isTeamView = false;
  bool _isLoading = true;

  // 🆕 내 프로젝트 목록 및 선택된 프로젝트 정보
  List<Map<String, dynamic>> _myProjects = [];
  String? _selectedProjectId;
  String _selectedProjectName = '';

  // TeamSchedulerPage의 상태에 접근하기 위한 GlobalKey
  final GlobalKey<TeamSchedulerPageState> _teamSchedulerKey = GlobalKey();

  final SupabaseClient _client = Supabase.instance.client;
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  fln.FlutterLocalNotificationsPlugin();

  Map<DateTime, List<Event>> _eventsMap = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _configureLocalNotifications();
    _loadEvents(); // 초기엔 개인 일정 로드
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

  // --- 🆕 내가 속한 프로젝트 목록 불러오기 ---
  Future<void> _loadMyProjects() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _client
          .from('team_members')
          .select('projects(id, title)')
          .eq('user_id', userId);

      final List<Map<String, dynamic>> loaded = [];
      for (var item in response) {
        if (item['projects'] != null) {
          loaded.add({
            'id': item['projects']['id'].toString(),
            'title': item['projects']['title'] as String,
          });
        }
      }

      if (mounted) {
        setState(() {
          _myProjects = loaded;
          if (_myProjects.isNotEmpty && _selectedProjectId == null) {
            _selectedProjectId = _myProjects[0]['id'];
            _selectedProjectName = _myProjects[0]['title'];
          }
        });
      }
    } catch (e) {
      debugPrint('내 프로젝트 로드 실패: $e');
    }
  }

  // --- 개인 일정 로드 ---
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
        final eventDateTime = DateTime.parse(data['event_date'] as String).toLocal();
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
      debugPrint('개인 일정 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
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
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')
            ),
            TextButton(
              onPressed: () async {
                // 💡 FIX: Navigator 객체를 비동기 작업 시작 전에 미리 캡처합니다.
                // 이렇게 하면 await 이후에 context를 직접 참조하지 않아 경고가 사라집니다.
                final navigator = Navigator.of(context);

                if (titleController.text.isEmpty) return;
                try {
                  final userId = _client.auth.currentUser!.id;
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

                  // 💡 FIX: 캡처해둔 navigator를 사용하여 팝업을 닫습니다.
                  navigator.pop();

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
          title: _isTeamView && _myProjects.isNotEmpty
              ? DropdownButton<String>(
            value: _selectedProjectId,
            dropdownColor: Colors.white,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'NotoSansKR',
            ),
            items: _myProjects.map((project) {
              return DropdownMenuItem<String>(
                value: project['id'],
                child: Text(project['title']),
              );
            }).toList(),
            onChanged: (newId) {
              setState(() {
                _selectedProjectId = newId;
                _selectedProjectName = _myProjects.firstWhere((p) => p['id'] == newId)['title'];
              });
            },
          )
              : Text(
            _isTeamView ? (_myProjects.isEmpty ? '참여중인 프로젝트 없음' : '팀 스케줄러') : '개인 스케줄러',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: _isTeamView ? iconColor.withValues(alpha: 0.5) : iconColor),
              onPressed: () {
                if (_isTeamView) {
                  if (_selectedProjectId != null) {
                    _teamSchedulerKey.currentState?.addMilestone();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('선택된 프로젝트가 없습니다.')));
                  }
                } else {
                  _showAddEventDialog();
                }
              },
            ),
            Switch(
              value: _isTeamView,
              onChanged: (val) {
                setState(() {
                  _isTeamView = val;
                  if (_isTeamView) {
                    _loadMyProjects();
                  } else {
                    _loadEvents();
                  }
                });
              },
              inactiveTrackColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isTeamView
            ? (_selectedProjectId != null
            ? TeamSchedulerPage(
          key: _teamSchedulerKey,
          projectId: _selectedProjectId!,
          projectName: _selectedProjectName,
        )
            : const Center(
          child: Text(
            "참여 중인 프로젝트가 없습니다.\n프로젝트를 생성하거나 지원해보세요.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ))
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