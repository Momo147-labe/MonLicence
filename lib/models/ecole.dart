class Ecole {
  final int? id;
  final String nom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? ville;
  final String pays;
  final DateTime? createdAt;

  Ecole({
    this.id,
    required this.nom,
    this.adresse,
    this.telephone,
    this.email,
    this.ville,
    this.pays = 'Guinée',
    this.createdAt,
  });

  factory Ecole.fromMap(Map<String, dynamic> map) {
    return Ecole(
      id: map['id'],
      nom: map['nom'],
      adresse: map['adresse'],
      telephone: map['telephone'],
      email: map['email'],
      ville: map['ville'],
      pays: map['pays'] ?? 'Guinée',
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'ville': ville,
      'pays': pays,
    };
  }
}
