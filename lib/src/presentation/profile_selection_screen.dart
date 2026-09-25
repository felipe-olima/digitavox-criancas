import 'package:flutter/material.dart';

import '../domain/progress/profile_repository.dart';

final class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({
    required this.profileRepository,
    required this.onProfileSelected,
    super.key,
  });

  final ProfileRepository profileRepository;
  final ValueChanged<StudentProfile> onProfileSelected;

  @override
  State<ProfileSelectionScreen> createState() =>
      _ProfileSelectionScreenState();
}

final class _ProfileSelectionScreenState
    extends State<ProfileSelectionScreen> {
  final controller = TextEditingController();

  List<StudentProfile> _profiles = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await widget.profileRepository.loadProfiles();

      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível carregar os perfis.';
      });
    }
  }

  Future<void> _createProfile() async {

  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Criar perfil'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nome',
          hintText: 'Digite seu nome',
        ),
        onSubmitted: (value) {
          Navigator.of(dialogContext).pop(value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(controller.text);
          },
          child: const Text('Criar'),
        ),
      ],
    ),
  );

  if (!mounted || name == null || name.trim().isEmpty) return;

  try {
    final profile = await widget.profileRepository.createProfile(name);

    if (!mounted) return;

    setState(() {
      _profiles = [..._profiles, profile];
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onProfileSelected(profile);
      }
    });
  } on ArgumentError catch (error) {
    if (!mounted) return;

    setState(() {
      _errorMessage = error.message.toString();
    });
  }
}

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quem vai aprender?'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Escolha um perfil',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  for (final profile in _profiles)
                    Card(
                      child: ListTile(
                        title: Text(profile.name),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => widget.onProfileSelected(profile),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _createProfile,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Criar novo perfil'),
                  ),
                ],
              ),
      ),
    );
  }
}