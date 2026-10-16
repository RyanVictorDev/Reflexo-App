import 'package:flutter/material.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/shared/widgets/centered_menu.dart';

class ColorsPage extends StatefulWidget {
  const ColorsPage({super.key});

  @override
  State<ColorsPage> createState() => _ColorsPageState();
}

class _ColorsPageState extends State<ColorsPage> {
  PlayerProfile _profile = PlayerProfile.initial();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() => _profile = profile);
  }

  Future<void> _choose(BallStyle style) async {
    final next = await PlayerRepository.instance.purchase(style);
    if (!mounted) {
      return;
    }
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faltam moedas para ${style.name}.')),
      );
      return;
    }
    setState(() => _profile = next);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return CenteredMenu(
      children: [
        Text(
          'Cores da bola',
          textAlign: TextAlign.center,
          style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Moedas ${_profile.coins}',
          textAlign: TextAlign.center,
          style: text.titleMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final style in BallStyle.catalog)
              _ColorChoice(
                style: style,
                owned: _profile.owns(style.id),
                selected: _profile.selectedColorId == style.id,
                onTap: () => _choose(style),
              ),
          ],
        ),
        const SizedBox(height: 28),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
      ],
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.style,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  final BallStyle style;
  final bool owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selected
        ? 'Equipada'
        : owned
        ? 'Equipar'
        : '${style.price}';
    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.glow,
                  border: Border.all(
                    color: selected ? Colors.white : style.mid,
                    width: selected ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: style.core,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(style.name, textAlign: TextAlign.center),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
