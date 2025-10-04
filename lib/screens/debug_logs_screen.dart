import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/debug_logger.dart';

/// Экран для отображения логов отладки
class DebugLogsScreen extends StatefulWidget {
  const DebugLogsScreen({super.key});

  @override
  State<DebugLogsScreen> createState() => _DebugLogsScreenState();
}

class _DebugLogsScreenState extends State<DebugLogsScreen> {
  List<String> _logs = [];
  String _searchText = '';
  String _selectedTag = 'Все';
  final List<String> _availableTags = ['Все', 'RSA', 'Steam', 'Auth', 'HTTP', 'Error'];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      if (_selectedTag == 'Все') {
        _logs = DebugLogger.getAllLogs();
      } else {
        _logs = DebugLogger.getLogsByTag(_selectedTag);
      }
      
      if (_searchText.isNotEmpty) {
        _logs = _logs.where((log) => 
          log.toLowerCase().contains(_searchText.toLowerCase())
        ).toList();
      }
    });
  }

  void _copyLogsToClipboard() {
    final logsText = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: logsText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Логи скопированы в буфер обмена',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    DebugLogger.clearLogs();
    _refreshLogs();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Логи очищены',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи отладки'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
            tooltip: 'Обновить логи',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Копировать логи',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Очистить логи',
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[800],
            child: Column(
              children: [
                // Поиск
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Поиск в логах...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                    _refreshLogs();
                  },
                ),
                const SizedBox(height: 12),
                // Теги
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTag = tag;
                            });
                            _refreshLogs();
                          },
                          selectedColor: Colors.blue[300],
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Логи
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Логи не найдены',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.toLowerCase().contains('error') ||
                                     log.toLowerCase().contains('exception') ||
                                     log.toLowerCase().contains('failed');
                      final isRsa = log.toLowerCase().contains('rsa');
                      final isSteam = log.toLowerCase().contains('steam');
                      
                      Color? backgroundColor;
                      if (isError) {
                        backgroundColor = Colors.red[50];
                      } else if (isRsa) {
                        backgroundColor = Colors.blue[50];
                      } else if (isSteam) {
                        backgroundColor = Colors.green[50];
                      }
                      
                      return Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isError ? Colors.red : Colors.grey[300]!,
                            width: isError ? 1 : 0.5,
                          ),
                        ),
                        child: SelectableText(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isError ? Colors.red[800] : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Статистика
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Всего логов: ${_logs.length}'),
                Text('Тег: $_selectedTag'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

