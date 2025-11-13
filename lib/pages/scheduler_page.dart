import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

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

  bool _isLoading = true;
  late final SupabaseClient _client;

  Map<DateTime, List<Event>> _eventsMap = {};

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = _client.auth.currentUser!.id;
      final response = await _client
          .from('personal_events')
          .select('id, title, date, status, project_id')
          .eq('user_id', userId);

      final Map<DateTime, List<Event>> tempMap = {};

      for (var data in response) {
        final eventDate = DateTime.parse(data['date']).toUtc();
        final dateKey = DateTime.utc(eventDate.year, eventDate.month, eventDate.day);

        final event = Event(
          id: data['id'].toString(),
          title: data['title'] as String,
          date: dateKey,
          isCompleted: data['status'] == 'completed',
          projectId: data['project_id'] as String,
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
      _showErrorSnackBar('일정 로드 실패: $e');
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

  Future<void> _toggleEventStatus(Event event) async {
    final newStatus = event.isCompleted ? 'pending' : 'completed';

    try {
      await _client
          .from('personal_events')
          .update({'status': newStatus})
          .eq('id', event.id);

      if (!mounted) return; // 💥 Context 경고 해결

      await _loadEvents();

      // SnackBar 호출 직전 mounted 체크
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 상태가 변경되었습니다.'))
      );

    } catch (e) {
      _showErrorSnackBar('상태 변경 실패: $e');
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('새 일정 추가 (${_selectedDay.toLocal().toString().split(' ')[0]})'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: '일정 내용'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                try {
                  final userId = _client.auth.currentUser!.id;
                  final eventDate = _selectedDay.toUtc().toIso8601String();

                  await _client.from('personal_events').insert({
                    'user_id': userId,
                    'project_id': 'default-project-id',
                    'title': titleController.text,
                    'date': eventDate,
                    'status': 'pending',
                  });

                  if (!mounted) return; // 💥 Context 경고 해결

                  await _loadEvents();
                  Navigator.pop(context);
                } catch (e) {
                  _showErrorSnackBar('일정 추가 실패: $e');
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }


  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color appBarColor = Colors.white;
    const Color textColor = Colors.black;
    final Color iconColor = Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: const Text('스케줄러', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: iconColor),
            onPressed: _showAddEventDialog,
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 1. Table Calendar 위젯
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              // 💥 const 제거 (오류 해결)
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,

                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },

                // 이벤트 표시 마커 스타일 (null 체크 추가)
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final nonNullEvents = events.whereType<Event>();
                    if (nonNullEvents.isEmpty) return const SizedBox();

                    final pendingCount = nonNullEvents.where((e) => !e.isCompleted).length;

                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: pendingCount > 0 ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        width: 10.0,
                        height: 10.0,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. 선택된 날짜의 이벤트 목록
            Text(
              '${_selectedDay.toLocal().toString().split(' ')[0]} 일정 (${_getEventsForDay(_selectedDay).length}개)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const Divider(),

            // 이벤트 리스트
            ..._getEventsForDay(_selectedDay).map((event) {
              return ListTile(
                key: ValueKey(event.id),
                leading: Icon(
                  event.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: event.isCompleted ? Colors.green : Colors.red,
                ),
                title: Text(
                  event.title,
                  style: TextStyle(
                      decoration: event.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      color: textColor
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => _toggleEventStatus(event),
                  tooltip: '진행 상태 변경',
                ),
                onTap: () {
                  _showErrorSnackBar('프로젝트 ID: ${event.projectId}');
                },
              );
            }),

            const SizedBox(height: 50),

            // 3. 진행률 시각화 Placeholder (Const 제거)
            const Text(
              '프로젝트 진행률 시각화 (MVP)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const Divider(),
            // 💥 Const 제거 (오류 해결)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('프로젝트 매칭 시스템 개발', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    // 가짜 진행률 바
                    LinearProgressIndicator(
                      value: 0.70, // 70% 진행
                      backgroundColor: Colors.grey,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 8),
                    Text('70% 완료 (12월 19일 마감)', style: TextStyle(fontSize: 12, color: iconColor)),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}