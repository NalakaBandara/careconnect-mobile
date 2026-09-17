class CheckInRecord {
  const CheckInRecord({
    required this.id,
    required this.appointmentId,
    required this.checkedInAt,
    required this.checkedInByUserId,
    required this.method,
    this.queueNumber,
  });

  final String id;
  final String appointmentId;
  final DateTime checkedInAt;
  final String checkedInByUserId;
  final String method;
  final int? queueNumber;

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
    id: json['id'] as String,
    appointmentId: json['appointmentId'] as String,
    checkedInAt: DateTime.parse(json['checkedInAt'] as String),
    checkedInByUserId: json['checkedInByUserId'] as String,
    method: json['method'] as String,
    queueNumber: json['queueNumber'] as int?,
  );
}
