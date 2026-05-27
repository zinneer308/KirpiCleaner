import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/clean_item.dart';
import '../services/cleaner_service.dart';
import '../services/history_service.dart';
import '../widgets/storage_ring_widget.dart';
import '../widgets/category_card.dart';
import 'scan_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  StorageInfo? _storageInfo;
  List<CleanSession> _recentSessions = [];
  bool _loading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final [storage, sessions] = await Future.wait([
      CleanerService.getStorageInfo(),
      HistoryService.getSessions(),
    ]);
    if (mounted) {
      setState(() {
        _storageInfo = storage as StorageInfo;
        _recentSessions = (sessions as List<CleanSession>).take(3).toList();
        _loading = false;
      });
    }
  }

  int get _totalCleaned => _recentSessions.fold(
    0,
    (sum, s) => sum + s.totalCleaned,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: _loading
          ? _buildLoading()
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildBody()),
              ],
            ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.accentCyan),
          SizedBox(height: 16),
          Text(
            'Загрузка...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppTheme.bgDeep,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentCyan, AppTheme.accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('🦔', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'KirpiCleaner',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ).then((_) => _loadData()),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStorageCard(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 24),
          _buildScanButton(),
          const SizedBox(height: 24),
          if (_recentSessions.isNotEmpty) ...[
            _buildSectionTitle('Последние очистки'),
            const SizedBox(height: 12),
            ..._recentSessions.map(_buildSessionCard),
          ],
          const SizedBox(height: 24),
          _buildTipsCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStorageCard() {
    final info = _storageInfo!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF0D1526)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          StorageRingWidget(storageInfo: info),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStorageStat(
                'Всего',
                info.formattedTotal,
                AppTheme.textSecondary,
              ),
              _buildStorageDivider(),
              _buildStorageStat(
                'Занято',
                info.formattedUsed,
                AppTheme.accentOrange,
              ),
              _buildStorageDivider(),
              _buildStorageStat(
                'Свободно',
                info.formattedFree,
                AppTheme.accentGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.borderColor,
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          '🧹',
          CleanItem.formatBytes(_totalCleaned),
          'Очищено всего',
          AppTheme.accentCyan,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          '🔢',
          '${_recentSessions.length}',
          'Сеансов очистки',
          AppTheme.accentPurple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String emoji,
    String value,
    String label,
    Color accent,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: GestureDetector(
        onTap: _openScanScreen,
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentCyan, AppTheme.accentPurple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentCyan.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, color: AppTheme.bgDeep, size: 26),
              SizedBox(width: 10),
              Text(
                'Начать сканирование',
                style: TextStyle(
                  color: AppTheme.bgDeep,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openScanScreen() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const ScanScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
    _loadData();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSessionCard(CleanSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.accentGreen,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.formattedSize} очищено',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${session.itemsCount} элементов · ${_formatDate(session.timestamp)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            session.formattedSize,
            style: const TextStyle(
              color: AppTheme.accentGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    if (diff.inDays == 1) return 'вчера';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Совет',
                  style: TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Регулярная очистка кэша ускоряет работу телефона и освобождает место для фото и приложений.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
