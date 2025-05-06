class Reservation {
  final String id;
  final String deviceId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;

  Reservation({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() => {
        'deviceId': deviceId,
        'userId': userId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      };

  factory Reservation.fromMap(String id, Map<String, dynamic> map) {
    return Reservation(
      id: id,
      deviceId: map['deviceId'],
      userId: map['userId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
    );
  }
}
