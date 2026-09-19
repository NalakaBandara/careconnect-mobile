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
    id: json['id'].toString(),
    appointmentId: json['appointmentId'].toString(),
    checkedInAt: DateTime.parse(json['checkedInAt'] as String),
    checkedInByUserId: json['checkedInByUserId'].toString(),
    method: json['method'] as String,
    queueNumber: json['queueNumber'] as int?,
  );
}
