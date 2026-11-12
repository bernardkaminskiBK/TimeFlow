class Activity {
  const Activity({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    this.isArchived = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final bool isArchived;
  final DateTime? createdAt;

  Activity copyWith({
    String? name,
    int? colorValue,
    String? iconKey,
    bool? isArchived,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }
}
