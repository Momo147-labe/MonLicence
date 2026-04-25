class Licence {
  final int? id;
  final String key;
  final int? idEcole;
  final bool active;
  final String? deviceId;
  final DateTime? activatedAt;
  final DateTime? createdAt;

  Licence({
    this.id,
    required this.key,
    this.idEcole,
    this.active = false,
    this.deviceId,
    this.activatedAt,
    this.createdAt,
  });

  factory Licence.fromMap(Map<String, dynamic> map) {
    return Licence(
      id: map['id'],
      key: map['key'],
      idEcole: map['id_ecole'],
      active: map['active'] ?? false,
      deviceId: map['device_id'],
      activatedAt: map['activated_at'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'key': key,
      'id_ecole': idEcole,
      'active': active,
      'device_id': deviceId,
      if (activatedAt != null) 'activated_at': activatedAt,
    };
  }
}
