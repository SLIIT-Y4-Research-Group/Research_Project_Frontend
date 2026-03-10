import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Top'),
              Tab(text: 'All'),
              Tab(text: 'Player'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Score'),
        ),
        body: const TabBarView(
          children: [
            _TopLeaderboardTab(),
            _AllLeaderboardTab(),
            _PlayerLeaderboardTab(),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    final levelController = TextEditingController();
    final timeController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Leaderboard Entry'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Player Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter player name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: scoreController,
                    decoration: const InputDecoration(labelText: 'Score'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null) {
                        return 'Enter a valid score';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: levelController,
                    decoration: const InputDecoration(labelText: 'Level'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null) {
                        return 'Enter a valid level';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Time (seconds)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null) {
                        return 'Enter a valid time';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                try {
                  await LeaderboardService.createEntry(
                    playerName: nameController.text.trim(),
                    score: int.parse(scoreController.text.trim()),
                    level: int.parse(levelController.text.trim()),
                    time: double.parse(timeController.text.trim()),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Create failed: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leaderboard entry created.')),
      );
    }
  }
}

class _TopLeaderboardTab extends StatefulWidget {
  const _TopLeaderboardTab();

  @override
  State<_TopLeaderboardTab> createState() => _TopLeaderboardTabState();
}

class _TopLeaderboardTabState extends State<_TopLeaderboardTab> {
  final TextEditingController _limitController =
      TextEditingController(text: '10');
  bool _isLoading = false;
  String? _error;
  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadTop();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadTop() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final limit = int.tryParse(_limitController.text.trim()) ?? 10;
      final results = await LeaderboardService.getTop(limit: limit);
      if (!mounted) return;
      setState(() {
        _entries = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Limit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _loadTop,
                child: const Text('Load'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No scores found.'))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      return LeaderboardEntryTile(
                        entry: _entries[index],
                        rank: index + 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AllLeaderboardTab extends StatefulWidget {
  const _AllLeaderboardTab();

  @override
  State<_AllLeaderboardTab> createState() => _AllLeaderboardTabState();
}

class _AllLeaderboardTabState extends State<_AllLeaderboardTab> {
  final int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  int _skip = 0;
  List<LeaderboardEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await LeaderboardService.getLeaderboard(
        skip: _skip,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        _entries.addAll(results);
        _skip += results.length;
        _hasMore = results.length == _limit;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _entries.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? const Center(child: Text('No scores found.'))
                    : ListView.builder(
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          return LeaderboardEntryTile(
                            entry: _entries[index],
                            rank: index + 1,
                          );
                        },
                      ),
          ),
          const SizedBox(height: 12),
          if (_isLoading) const LinearProgressIndicator(),
          if (_hasMore)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _loadMore,
                child: const Text('Load More'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerLeaderboardTab extends StatefulWidget {
  const _PlayerLeaderboardTab();

  @override
  State<_PlayerLeaderboardTab> createState() => _PlayerLeaderboardTabState();
}

class _PlayerLeaderboardTabState extends State<_PlayerLeaderboardTab> {
  final TextEditingController _playerController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<LeaderboardEntry> _entries = [];

  Future<void> _search() async {
    final player = _playerController.text.trim();
    if (player.isEmpty) {
      setState(() {
        _error = 'Enter a player name.';
        _entries = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await LeaderboardService.getPlayerEntries(player);
      if (!mounted) return;
      setState(() {
        _entries = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _playerController,
                  decoration: const InputDecoration(
                    labelText: 'Player Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _search,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No scores found.'))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      return LeaderboardEntryTile(
                        entry: _entries[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardEntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int? rank;

  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = entry.time.toStringAsFixed(1);
    final createdLabel = entry.createdAt == null
        ? null
        : '${entry.createdAt!.toLocal()}'.split('.').first;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: rank == null
            ? const Icon(Icons.emoji_events)
            : CircleAvatar(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                child: Text(rank.toString()),
              ),
        title: Text(entry.playerName.isEmpty ? 'Unknown Player' : entry.playerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${entry.score}  Level: ${entry.level}  Time: ${timeLabel}s'),
            if (createdLabel != null) Text('Created: $createdLabel'),
          ],
        ),
      ),
    );
  }
}
