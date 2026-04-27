import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';
import '../models/ecole.dart';
import '../models/licence.dart';
import '../models/user.dart';

class NeonService extends ChangeNotifier {
  Connection? _connection;
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthLoading = false;
  String? _error;

  // Data
  List<Ecole> _ecoles = [];
  List<Licence> _licences = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthLoading => _isAuthLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<Ecole> get ecoles => _ecoles;
  List<Licence> get licences => _licences;

  Future<void> init() async {
    if (_connection != null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = dotenv.env['NEAN_URL'];
      if (url == null) throw Exception('NEAN_URL non trouvé');

      final uri = Uri.parse(url);
      final userInfo = uri.userInfo.split(':');

      _connection = await Connection.open(
        Endpoint(
          host: uri.host,
          port: uri.port > 0 ? uri.port : 5432,
          database: uri.pathSegments.isNotEmpty
              ? uri.pathSegments.first
              : 'postgres',
          username: userInfo.isNotEmpty ? userInfo[0] : null,
          password: userInfo.length > 1 ? userInfo[1] : null,
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: Duration(
            seconds: 30,
          ), // Timeout plus long pour cold start
        ),
      );

      if (isAuthenticated) await refreshAll();
    } catch (e) {
      _error = _formatError(e);
      debugPrint("Erreur init: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auth Logic
  Future<bool> login(String username, String password) async {
    if (_connection == null) await init();
    if (_connection == null) return false;

    _isAuthLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connection!.execute(
        Sql.named(
          'SELECT * FROM users WHERE username = @username AND password = @password',
        ),
        parameters: {'username': username, 'password': password},
      );

      if (result.isNotEmpty) {
        _currentUser = User.fromMap(result.first.toColumnMap());
        await refreshAll();
        return true;
      } else {
        _error = "Identifiants incorrects";
        return false;
      }
    } catch (e) {
      _error = _formatError(e);
      return false;
    } finally {
      _isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (_currentUser == null || _connection == null) return;
    try {
      await _connection!.execute(
        Sql.named('UPDATE users SET password = @newPassword WHERE id = @id'),
        parameters: {'newPassword': newPassword, 'id': _currentUser!.id},
      );
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _ecoles = [];
    _licences = [];
    notifyListeners();
  }

  // Data Logic
  Future<void> refreshAll() async {
    if (_connection == null) return;
    try {
      final resEcoles = await _connection!.execute(
        'SELECT * FROM ecole ORDER BY nom',
      );
      _ecoles = resEcoles
          .map((row) => Ecole.fromMap(row.toColumnMap()))
          .toList();

      final resLicences = await _connection!.execute(
        'SELECT * FROM licence ORDER BY created_at DESC',
      );
      _licences = resLicences
          .map((row) => Licence.fromMap(row.toColumnMap()))
          .toList();
      notifyListeners();
    } catch (e) {
      _error = _formatError(e);
      notifyListeners();
    }
  }

  Future<void> createLicence(Licence licence) async {
    if (_connection == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _connection!.execute(
        Sql.named(
          'INSERT INTO licence (key, id_ecole, active, device_id) VALUES (@key, @idEcole, @active, @deviceId)',
        ),
        parameters: {
          'key': licence.key,
          'idEcole': licence.idEcole,
          'active': licence.active,
          'deviceId': licence.deviceId,
        },
      );
      await refreshAll();
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLicence(int id) async {
    if (_connection == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _connection!.execute(
        Sql.named('DELETE FROM licence WHERE id = @id'),
        parameters: {'id': id},
      );
      await refreshAll();
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLicenceStatus(int id, bool currentStatus) async {
    if (_connection == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newStatus = !currentStatus;
      await _connection!.execute(
        Sql.named(
          'UPDATE licence SET active = @active, activated_at = @activatedAt WHERE id = @id',
        ),
        parameters: {
          'id': id,
          'active': newStatus,
          'activatedAt': newStatus ? DateTime.now() : null,
        },
      );
      await refreshAll();
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEcole(int id) async {
    if (_connection == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _connection!.execute(
        Sql.named('DELETE FROM ecole WHERE id = @id'),
        parameters: {'id': id},
      );
      await refreshAll();
    } catch (e) {
      _error = _formatError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connection?.close();
    super.dispose();
  }

  String _formatError(dynamic e) {
    if (e is ServerException) {
      final code = e.code;
      switch (code) {
        case '23505':
          return "Cette information existe déjà (doublon détecté).";
        case '23503':
          return "Impossible de supprimer cet élément car il est lié à d'autres données.";
        case '08001':
        case '08006':
        case '08003':
        case '08004':
        case '08P01':
          return "Problème de connexion au serveur de base de données.";
        case '28P01':
          return "Authentification échouée sur le serveur.";
        case '42P01':
          return "Erreur système : Table introuvable.";
        default:
          return "Erreur serveur ($code) : ${e.message}";
      }
    }
    final errorStr = e.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection failed') ||
        errorStr.contains('TimeoutException')) {
      return "Impossible de contacter le serveur. Vérifiez votre connexion internet.";
    }
    return "Une erreur inattendue est survenue.";
  }
}
