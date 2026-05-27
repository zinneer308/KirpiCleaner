import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/clean_item.dart';
import '../services/cleaner_service.dart';
import '../services/history_service.dart';
import '../widgets/category_card.dart';
import 'result_screen.dart';

enum ScanState { idle, scanning, results, cleaning, done }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  ScanState _state = ScanState.idle;
  List<CleanItem> _items = [];
  final Map<CleanCategory, bool> _expandedCategories = {};
  late AnimationController _scanAnim;
  late Animation<double> _scanRotation;
  double _scanProgress = 0;
  String _scanMessage = '';

  final List<String> _scanMessages = [
    'Сканирую кэш приложений...',
    'Ищу временные файлы...',
    'Проверяю эскизы...',
    'Анализирую APK-файлы...',
    'Поиск пустых папок...',
    'Проверяю лог-файлы...',
    'Завершаю анализ...',
  ];

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanRotation = CurvedAnimation(parent: _scanAnim, curve: Curves.linear);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    super.dispose();
  }

  Map<CleanCategory, List<CleanItem>> get _itemsByCategory {
    final Map<CleanCategory, List<CleanItem>> result = {};
    for (final item in _items) {
      result.putIfAbsent(item.category, () => []).add(item);
    }
    return result;
  }

  int get _selectedSize => _items
      .where((i) => i.isSelected)
      .fold(0, (sum, i) => sum + i.sizeBytes);

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  Future<void> _startScan() async {
    setState(() {
      _state = ScanState.scanning;
      _scanProgress = 0;
      _items = [];
    });

    // Animate scanning progress
    for (int i = 0; i < _scanMessages.length; i++) {
      if (!mounted) return;
      setState(() {
        _scanMessage = _scanMessages[i];
        _scanProgress = (i + 1) / _scanMessages.length;
      });
      await Future.delayed(const Duration(milliseconds: 600));
    }

    // Run actual scan
    final items = await CleanerService.scanForJunk();

    if (mounted) {
      setState(() {
        _items = items;
        _state = ScanState.results;
      });
    }
  }

  Future<void> _startClean() async {
    setState(() => _state = ScanState.cleaning);
    await Future.delayed(const Duration(milliseconds: 400));

    final result = await CleanerService.cleanItems(_items);

    // Save session
    await HistoryService.saveSession(
      CleanSession(
        timestamp: DateTime.now(),
        totalCleaned: result.totalBytesFreed,
        byCategory: result.byCategory,
        itemsCount: result.cleanedItems,
      ),
    );

    if (mounted) {
      setState(() => _state = ScanState.done);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Сканирование'),
        backgroundColor: AppTheme.bgDeep,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ScanState.idle:
        return _buildIdleState();
      case ScanState.scanning:
        return _buildScanningState();
      case ScanState.results:
        return _buildResultsState();
      case ScanState.cleaning:
        return _buildCleaningState();
      case ScanState.done:
        return _buildCleaningState();
    }
  }

  Widget _buildIdleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentCyan.withOpacity(0.3),
                    AppTheme.accentCyan.withOpacity(0),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔍', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Готов к сканированию',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'KirpiCleaner найдёт кэш, временные файлы, пустые папки и другой мусор.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: AppTheme.bgDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Начать сканирование',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _scanRotation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppTheme.accentCyan.withOpacity(0),
                      AppTheme.accentCyan,
                    ],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.bgDeep,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🦔', style: TextStyle(fontSize: 42)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _scanProgress,
                backgroundColor: AppTheme.bgSurface,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accentCyan),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _scanMessage,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(_scanProgress * 100).toInt()}%',
              style: const TextStyle(
                color: AppTheme.accentCyan,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsState() {
    final byCategory = _itemsByCategory;
    final totalSize = _items.fold(0, (sum, i) => sum + i.sizeBytes);

    return Column(
      children: [
        // Summary header
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentOrange.withOpacity(0.15),
                AppTheme.accentPurple.withOpacity(0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.accentOrange.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              const Text('🗑️', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Найдено мусора',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      CleanItem.formatBytes(totalSize),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_items.length} элементов в ${byCategory.length} категориях',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select all bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Выбрано: $_selectedCount (${CleanItem.formatBytes(_selectedSize)})',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _selectAll,
                child: const Text(
                  'Все',
                  style: TextStyle(color: AppTheme.accentCyan),
                ),
              ),
              TextButton(
                onPressed: _deselectAll,
                child: const Text(
                  'Снять',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),

        // Category list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: byCategory.entries.map((entry) {
              final category = entry.key;
              final items = entry.value;
              final isExpanded = _expandedCategories[category] ?? false;

              return CategoryCard(
                category: category,
                items: items,
                isExpanded: isExpanded,
                onToggleExpand: () {
                  setState(() {
                    _expandedCategories[category] = !isExpanded;
                  });
                },
                onToggleItem: (index) {
                  setState(() {
                    items[index].isSelected = !items[index].isSelected;
                  });
                },
              );
            }).toList(),
          ),
        ),

        // Clean button
        _buildCleanBottomBar(),
      ],
    );
  }

  Widget _buildCleanBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppTheme.bgDeep,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _selectedCount > 0 ? _startClean : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            _selectedCount > 0
                ? 'Очистить $_selectedCount файлов (${CleanItem.formatBytes(_selectedSize)})'
                : 'Выберите файлы для очистки',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleaningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RotationTransition(
            turns: _scanRotation,
            child: const Text('🌪️', style: TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Очищаю...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Пожалуйста, подождите',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _selectAll() => setState(() {
    for (final item in _items) item.isSelected = true;
  });

  void _deselectAll() => setState(() {
    for (final item in _items) item.isSelected = false;
  });
}
