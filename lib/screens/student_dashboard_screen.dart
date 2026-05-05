import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'mood_intro_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isLoading = true;
  String _childName = '';
  String _username = '';
  int _age = 0;
  
  // Today's mood status
  bool _todayCompleted = false;
  String? _todayMood;
  
  // Weekly moods
  List<DailyMood> _weeklyMoods = [];
  
  // Weekly summary
  int _happyCount = 0;
  int _normalCount = 0;
  int _badCount = 0;
  int _missedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentDashboard();
  }

  Future<void> _loadStudentDashboard() async {
    setState(() => _isLoading = true);
    
    try {
      // Load child info
      await _loadChildInfo();
      
      // Load today's mood status
      await _loadTodayMoodStatus();
      
      // Load weekly moods
      await _loadWeeklyMoods();
    } catch (e) {
      print('[DASHBOARD] Error loading dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChildInfo() async {
    try {
      final response = await ApiClient.getChildInfo();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _childName = data['name'] ?? '';
          _username = data['username'] ?? '';
          _age = data['age'] ?? 0;
        });
      }
    } catch (e) {
      print('[DASHBOARD] Error loading child info: $e');
    }
  }

  Future<void> _loadTodayMoodStatus() async {
    try {
      final response = await ApiClient.getTodayMoodStatus();
      print('[DASHBOARD] getTodayMoodStatus - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[DASHBOARD] Today mood data: $data');
        setState(() {
          _todayCompleted = data['completed'] ?? false;
          _todayMood = data['mood'];
        });
      } else {
        print('[DASHBOARD] getTodayMoodStatus failed: ${response.body}');
      }
    } catch (e) {
      print('[DASHBOARD] Error loading today mood status: $e');
    }
  }

  Future<void> _loadWeeklyMoods() async {
    try {
      final response = await ApiClient.getWeeklyMoods();
      print('[DASHBOARD] getWeeklyMoods - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[DASHBOARD] Weekly moods data: $data');
        
        // Backend returns { "days": [...], "summary": {...} }
        final List<dynamic> daysData = data['days'] ?? [];
        final Map<String, dynamic>? summaryData = data['summary'];
        
        setState(() {
          _weeklyMoods = daysData.map((m) => DailyMood.fromJson(m)).toList();
          
          // Use backend summary if available, otherwise calculate from moods
          if (summaryData != null) {
            _happyCount = summaryData['happy'] ?? 0;
            _normalCount = summaryData['normal'] ?? 0;
            _badCount = summaryData['bad'] ?? 0;
            _missedCount = summaryData['missed'] ?? 0;
          } else {
            // Fallback: calculate from moods
            _happyCount = 0;
            _normalCount = 0;
            _badCount = 0;
            _missedCount = 0;
            
            for (var mood in _weeklyMoods) {
              if (mood.mood == null) {
                _missedCount++;
              } else {
                final moodLower = mood.mood!.toLowerCase();
                if (moodLower.contains('happy') || moodLower.contains('joy')) {
                  _happyCount++;
                } else if (moodLower.contains('normal') || moodLower.contains('neutral')) {
                  _normalCount++;
                } else if (moodLower.contains('bad') || moodLower.contains('sad') || moodLower.contains('angry')) {
                  _badCount++;
                }
              }
            }
          }
        });
      } else {
        print('[DASHBOARD] getWeeklyMoods failed: ${response.body}');
      }
    } catch (e) {
      print('[DASHBOARD] Error loading weekly moods: $e');
    }
  }

  Future<void> _handleStartMoodCheck() async {
    // Check if today's mood check is already completed
    if (_todayCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ඔයා අද mood check එක කරලා ඉවරයි!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Navigate to mood check
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MoodIntroScreen(),
      ),
    );
    
    // Refresh dashboard after returning if mood check was completed
    if (mounted && result == true) {
      print('[DASHBOARD] Refreshing after mood check completion');
      await _loadStudentDashboard();
    }
  }

  Color _getMoodColor(String? mood) {
    if (mood == null) return Colors.grey.shade300;
    
    final moodLower = mood.toLowerCase();
    if (moodLower.contains('happy') || moodLower.contains('joy')) {
      return Colors.green.shade400;
    } else if (moodLower.contains('normal') || moodLower.contains('neutral')) {
      return Colors.blue.shade400;
    } else if (moodLower.contains('bad') || moodLower.contains('sad') || moodLower.contains('angry')) {
      return Colors.orange.shade400;
    }
    return Colors.grey.shade400;
  }

  String _getMoodEmoji(String? mood) {
    if (mood == null) return '—';
    
    final moodLower = mood.toLowerCase();
    if (moodLower.contains('happy') || moodLower.contains('joy')) {
      return '😊';
    } else if (moodLower.contains('normal') || moodLower.contains('neutral')) {
      return '🙂';
    } else if (moodLower.contains('bad') || moodLower.contains('sad') || moodLower.contains('angry')) {
      return '😔';
    }
    return '😐';
  }

  String _getMoodLabel(String? mood) {
    if (mood == null) return 'No check-in';
    
    final moodLower = mood.toLowerCase();
    if (moodLower.contains('happy') || moodLower.contains('joy')) {
      return 'Happy';
    } else if (moodLower.contains('normal') || moodLower.contains('neutral')) {
      return 'Normal';
    } else if (moodLower.contains('bad') || moodLower.contains('sad') || moodLower.contains('angry')) {
      return 'Bad';
    }
    return mood;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF4FBF6),
              Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66BB6A).withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66BB6A).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 250,
              right: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66BB6A).withOpacity(0.06),
                ),
              ),
            ),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4EAA57),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadStudentDashboard,
                    child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Card
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    
                    // Today's Status Card
                    _buildTodayStatusCard(),
                    const SizedBox(height: 16),
                    
                    // Weekly History Card
                    _buildWeeklyHistoryCard(),
                    const SizedBox(height: 16),
                    
                    // Weekly Summary Card
                    _buildWeeklySummaryCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4EAA57).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 32,
              color: Color(0xFF4EAA57),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $_childName! 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Username: $_username',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Age: $_age years',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _todayCompleted
              ? [const Color(0xFF4EAA57), const Color(0xFF72B86B)]
              : [const Color(0xFF50C2C9), const Color(0xFF70D5DD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Check-in",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (_todayCompleted)
            ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMoodEmoji(_todayMood),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getMoodLabel(_todayMood),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "✓ Today's mood check is completed",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]
          else
            ...[
              const Text(
                "You have not completed today's mood check yet",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleStartMoodCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF50C2C9),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Start today's mood check",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildWeeklyHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_weeklyMoods.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No mood history available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weeklyMoods.map((dailyMood) {
                return _buildDayCard(dailyMood);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DailyMood dailyMood) {
    final color = _getMoodColor(dailyMood.mood);
    final emoji = _getMoodEmoji(dailyMood.mood);
    
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 4,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dailyMood.dayLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            _getMoodLabel(dailyMood.mood),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryChip('Happy', _happyCount, Colors.green),
              _buildSummaryChip('Normal', _normalCount, Colors.blue),
              _buildSummaryChip('Bad', _badCount, Colors.orange),
              _buildSummaryChip('Missed', _missedCount, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class DailyMood {
  final String date;
  final String? mood;
  final String dayLabel;

  DailyMood({
    required this.date,
    required this.mood,
    required this.dayLabel,
  });

  factory DailyMood.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] ?? '';
    
    // Generate day label locally from date string
    String dayLabel = '';
    if (dateStr.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(dateStr);
        const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dayLabel = weekDays[parsedDate.weekday - 1];
      } catch (e) {
        print('[DailyMood] Error parsing date: $e');
        dayLabel = json['day_label'] ?? '';
      }
    }
    
    return DailyMood(
      date: dateStr,
      mood: json['mood'],
      dayLabel: dayLabel,
    );
  }
}
