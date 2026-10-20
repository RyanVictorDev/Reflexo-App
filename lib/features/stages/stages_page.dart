import 'package:flutter/material.dart';
import 'package:reflexo/app/app_route_observer.dart';
import 'package:reflexo/audio/audio_controller.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/domain/run_variety.dart';
import 'package:reflexo/domain/stage_catalog.dart';
import 'package:reflexo/features/gameplay/gameplay_page.dart';

class StagesPage extends StatefulWidget {
  const StagesPage({super.key});

  @override
  State<StagesPage> createState() => _StagesPageState();
}

class _StagesPageState extends State<StagesPage> with RouteAware {
  PlayerProfile _profile = PlayerProfile.initial();
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! ModalRoute<void> || route == _route) {
      return;
    }
    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }
    _route = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _reload();
  }

  Future<void> _reload() async {
    final profile = await PlayerRepository.instance.load();
    if (!mounted) {
      return;
    }
    setState(() => _profile = profile);
  }

  Future<void> _play(Stage stage) async {
    await AudioController.instance.playEffect('ui');
    if (!mounted) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GameplayPage(stage: stage)));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Fases',
                          textAlign: TextAlign.center,
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estrelas ${_profile.totalStars}',
                          textAlign: TextAlign.center,
                          style: text.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  for (var i = 0; i < StageCatalog.stages.length; i++) ...[
                    if (i == 0 ||
                        StageCatalog.stages[i].arc !=
                            StageCatalog.stages[i - 1].arc)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 4),
                        child: Text(
                          StageCatalog.stages[i].arc,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    _StageTile(
                      stage: StageCatalog.stages[i],
                      stars: _profile.starsFor(StageCatalog.stages[i].id),
                      open: StageCatalog.isOpen(
                        StageCatalog.stages[i],
                        _profile.stageStars,
                      ),
                      onPlay: () => _play(StageCatalog.stages[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.stage,
    required this.stars,
    required this.open,
    required this.onPlay,
  });

  final Stage stage;
  final int stars;
  final bool open;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Opacity(
      opacity: open ? 1 : 0.45,
      child: InkWell(
        onTap: open ? onPlay : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${stage.lanes} faixas · ${stage.objective}',
                      style: text.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      RunVariety.forStage(stage).hint,
                      style: text.bodySmall?.copyWith(color: Colors.white54),
                    ),
                    if (!open)
                      Text(
                        'Conclua a fase anterior',
                        style: text.bodySmall?.copyWith(color: Colors.white54),
                      ),
                  ],
                ),
              ),
              if (open)
                _StarRow(count: stars)
              else
                const Icon(Icons.lock, size: 18, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < count ? Icons.star : Icons.star_border,
            size: 16,
            color: const Color(0xFFF5C542),
          ),
      ],
    );
  }
}
