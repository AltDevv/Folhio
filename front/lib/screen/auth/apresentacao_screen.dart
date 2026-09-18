import 'package:flutter/material.dart';

import '../../config/rotas_folhio.dart';
import '../../style/estilo_folhio.dart';
import '../../repository/local/persistencia_local_repository.dart';
import '../../widget/cards.dart';
import '../../widget/folhio_scaffold.dart';

class ApresentacaoScreen extends StatefulWidget {
  const ApresentacaoScreen({super.key});

  @override
  State<ApresentacaoScreen> createState() => _ApresentacaoScreenState();
}

class _ApresentacaoScreenState extends State<ApresentacaoScreen> {
  final _name = TextEditingController();
  final _repo = PersistenciaLocalRepository.instance;
  String _subject = 'Matemática';
  String _schoolYear = 'Ensino Fundamental II';
  String _materialType = 'Atividade';
  String _language = 'Normal';
  bool _acceptedLogs = false;
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    if (!_acceptedLogs) {
      setState(
        () => _message =
            'Marque o consentimento de coleta de logs para continuar.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    final displayName = _name.text.trim().isEmpty
        ? 'Professor'
        : _name.text.trim();
    await _repo.definirConfiguracao('profile.name', displayName);
    await _repo.definirConfiguracao('profile.subject', _subject);
    await _repo.definirConfiguracao('profile.schoolYear', _schoolYear);
    await _repo.definirConfiguracao('profile.materialType', _materialType);
    await _repo.definirConfiguracao('profile.language', _language);
    await _repo.definirConfiguracao('privacy.logsAccepted', 'true');
    await _repo.definirConfiguracao(
      'privacy.logsAcceptedAt',
      DateTime.now().toIso8601String(),
    );
    await _repo.definirConfiguracao('privacy.logsPolicyVersion', '2026-06-12');
    await _repo.definirConfiguracao('onboarding.completed', 'true');

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(RotasFolhio.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresFolhio.background,
      body: SafeArea(
        child: FolhioCorpoPagina(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Image.asset(
                'assets/images/folhio_icon_transparent.png',
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Vamos deixar o Folhio com a sua cara',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: CoresFolhio.cream,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sua conta mantém materiais e preferências na nuvem. O Folhio registra eventos técnicos mínimos para segurança e diagnóstico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CoresFolhio.muted,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            FolhioCard(
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Como quer ser chamado?',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CampoEscolha(
                    label: 'Disciplina padrão',
                    value: _subject,
                    values: const [
                      'Matemática',
                      'Português',
                      'História',
                      'Ciências',
                      'Geografia',
                      'Inglês',
                      'Artes',
                    ],
                    onChanged: (value) => setState(() => _subject = value),
                  ),
                  _CampoEscolha(
                    label: 'Ano/série mais usado',
                    value: _schoolYear,
                    values: const [
                      '1º ano',
                      '2º ano',
                      '5º ano',
                      'Ensino Fundamental II',
                      'Ensino Médio',
                    ],
                    onChanged: (value) => setState(() => _schoolYear = value),
                  ),
                  _CampoEscolha(
                    label: 'Material mais comum',
                    value: _materialType,
                    values: const [
                      'Atividade',
                      'Prova',
                      'Revisão',
                      'Plano de aula',
                    ],
                    onChanged: (value) => setState(() => _materialType = value),
                  ),
                  _CampoEscolha(
                    label: 'Linguagem preferida',
                    value: _language,
                    values: const ['Simples', 'Normal', 'Mais formal'],
                    onChanged: (value) => setState(() => _language = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FolhioCard(
              child: CheckboxListTile(
                value: _acceptedLogs,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _acceptedLogs = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Concordo com a coleta de logs técnicos mínimos',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  'Para diagnóstico, gráficos, segurança e controle de custos de APIs pagas, o Folhio registra eventos técnicos mínimos por até 10 dias.',
                  style: TextStyle(color: CoresFolhio.muted, height: 1.3),
                ),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CoresFolhio.coral),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _concluir,
              child: Text(_saving ? 'Salvando...' : 'Começar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoEscolha extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _CampoEscolha({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
