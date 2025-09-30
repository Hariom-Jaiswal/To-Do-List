class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? color;
  final bool isAllDay;
  final String? location;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    this.color,
    this.isAllDay = false,
    this.location,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? color,
    bool? isAllDay,
    String? location,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'color': color,
      'isAllDay': isAllDay,
      'location': location,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      color: json['color'],
      isAllDay: json['isAllDay'] ?? false,
      location: json['location'],
    );
  }
}
