import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/ecole.dart';
import 'models/licence.dart';
import 'services/neon_service.dart';
import 'utils/licence_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (_) => NeonService()..init(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Licence Admin Pro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final neon = context.watch<NeonService>();
    if (neon.isAuthenticated) {
      return const MainScreen();
    }
    return const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final neon = context.watch<NeonService>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 80, color: Colors.teal),
              const SizedBox(height: 12),
              const Text(
                'Admin Licences',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Utilisateur',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (neon.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    neon.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (neon.isAuthLoading)
                      ? null
                      : () => neon.login(
                          _userController.text,
                          _passController.text,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: neon.isAuthLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Se connecter'),
                ),
              ),
              if (neon.error != null && neon.error!.contains('Timeout'))
                TextButton(
                  onPressed: () => neon.init(),
                  child: const Text('Réessayer la connexion'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final neon = context.watch<NeonService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => neon.refreshAll(),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.password, size: 20),
                    SizedBox(width: 8),
                    Text('Changer MDP'),
                  ],
                ),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => _showChangePasswordDialog(context, neon),
                ),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
                onTap: () => neon.logout(),
              ),
            ],
          ),
        ],
      ),
      body: neon.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
          ? const EcoleListView()
          : const LicenceListView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Écoles',
          ),
          NavigationDestination(
            icon: Icon(Icons.key_outlined),
            selectedIcon: Icon(Icons.vpn_key),
            label: 'Licences',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _handleGenerateLicence(context, neon),
              icon: const Icon(Icons.add),
              label: const Text('Générer'),
            )
          : null,
    );
  }

  void _showChangePasswordDialog(BuildContext context, NeonService neon) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nouveau mot de passe',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                neon.changePassword(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe mis à jour !')),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _handleGenerateLicence(BuildContext context, NeonService neon) {
    final newKey = LicenceGenerator.generate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Licence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Clé générée :'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                newKey,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context); // Fermer immédiatement
              await neon.createLicence(Licence(key: newKey));
              if (neon.error != null && context.mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(neon.error!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

class EcoleListView extends StatelessWidget {
  const EcoleListView({super.key});

  @override
  Widget build(BuildContext context) {
    final neon = context.watch<NeonService>();
    final ecoles = neon.ecoles;
    if (ecoles.isEmpty)
      return const Center(child: Text('Aucune école enregistrée'));

    return RefreshIndicator(
      onRefresh: () => neon.refreshAll(),
      child: ListView.builder(
        itemCount: ecoles.length,
        itemBuilder: (context, index) {
          final ecole = ecoles[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.school, color: Colors.teal),
              title: Text(
                ecole.nom,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${ecole.ville}, ${ecole.pays}'),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer l\'établissement ?'),
                      content: const Text(
                        'Toutes les licences associées resteront mais ne seront plus liées à cette école.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(context);
                            final neon = context.read<NeonService>();
                            await neon.deleteEcole(ecole.id!);
                            if (context.mounted) {
                              if (neon.error != null) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(neon.error!),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Établissement supprimé'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class LicenceListView extends StatelessWidget {
  const LicenceListView({super.key});

  @override
  Widget build(BuildContext context) {
    final neon = context.watch<NeonService>();
    final licences = neon.licences;
    if (licences.isEmpty)
      return const Center(child: Text('Pool de licences vide'));

    return RefreshIndicator(
      onRefresh: () => neon.refreshAll(),
      child: ListView.builder(
        itemCount: licences.length,
        itemBuilder: (context, index) {
          final licence = licences[index];
          final ecole = licence.idEcole != null
              ? neon.ecoles.firstWhere(
                  (e) => e.id == licence.idEcole,
                  orElse: () => Ecole(nom: 'Inconnue'),
                )
              : null;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: SelectableText(
                licence.key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ecole != null)
                    Row(
                      children: [
                        const Icon(Icons.link, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Assignée: ${ecole.nom}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Disponible',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    licence.active ? 'État: Active' : 'État: Non activée',
                    style: TextStyle(
                      color: licence.active ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 20,
                      color: Colors.blueGrey,
                    ),
                    tooltip: 'Copier',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: licence.key));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Licence copiée !'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Supprimer ?'),
                          content: const Text('Cette action est irréversible.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(context);
                                await neon.deleteLicence(licence.id!);
                                if (context.mounted) {
                                  if (neon.error != null) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(neon.error!),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Licence supprimée'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
