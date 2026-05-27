enum CleanCategory {
  cache,
  temp,
  thumbnails,
  apkFiles,
  emptyFolders,
  logs,
}

class CleanItem {
  final String name;
  final String path;
  final int sizeBytes;
  final CleanCategory category;
  bool isSelected;

  CleanItem({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.category,
    this.isSelected = true,
  });

  String get formattedSize => formatBytes(sizeBytes);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class CleanSession {
  final DateTime timestamp;
  final int totalCleaned;
  final Map<CleanCategory, int> byCategory;
  final int itemsCount;

  CleanSession({
    required this.timestamp,
    required this.totalCleaned,
    required this.byCategory,
    required this.itemsCount,
  });

  String get formattedSize => CleanItem.formatBytes(totalCleaned);
}

class StorageInfo {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;

  StorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });

  double get usedPercent => totalBytes > 0 ? usedBytes / totalBytes : 0.0;
  double get freePercent => totalBytes > 0 ? freeBytes / totalBytes : 0.0;

  String get formattedTotal => CleanItem.formatBytes(totalBytes);
  String get formattedUsed => CleanItem.formatBytes(usedBytes);
  String get formattedFree => CleanItem.formatBytes(freeBytes);
}

extension CleanCategoryName on CleanCategory {
  String get displayName {
    switch (this) {
      case CleanCategory.cache:
        return 'Кэш приложений';
      case CleanCategory.temp:
        return 'Временные файлы';
      case CleanCategory.thumbnails:
        return 'Эскизы';
      case CleanCategory.apkFiles:
        return 'APK-файлы';
      case CleanCategory.emptyFolders:
        return 'Пустые папки';
      case CleanCategory.logs:
        return 'Лог-файлы';
    }
  }

  String get iconEmoji {
    switch (this) {
      case CleanCategory.cache:
        return '🗃️';
      case CleanCategory.temp:
        return '⏱️';
      case CleanCategory.thumbnails:
        return '🖼️';
      case CleanCategory.apkFiles:
        return '📦';
      case CleanCategory.emptyFolders:
        return '📁';
      case CleanCategory.logs:
        return '📋';
    }
  }
}
