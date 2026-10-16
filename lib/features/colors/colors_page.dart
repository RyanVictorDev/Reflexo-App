import 'package:flutter/material.dart';
import 'package:reflexo/data/player_repository.dart';
import 'package:reflexo/domain/ball_style.dart';
import 'package:reflexo/domain/player_profile.dart';
import 'package:reflexo/features/customize/shop_chrome.dart';

class ColorsPage extends StatelessWidget {
  const ColorsPage({
    super.key,
    required this.profile,
    required this.onProfile,
    required this.onNotice,
  });

  final PlayerProfile profile;
  final ValueChanged<PlayerProfile> onProfile;
  final void Function(String message, bool stars) onNotice;

  Future<void> _choose(BuildContext context, BallStyle style) async {
    if (!profile.owns(style.id) && profile.totalStars < style.minStars) {
      onNotice(
        'Precisa de ${style.minStars} estrelas para ${style.name}.',
        true,
      );
      return;
    }
    final next = await PlayerRepository.instance.purchase(style);
    if (!context.mounted) {
      return;
    }
    if (next == null) {
      onNotice('Faltam moedas para ${style.name}.', false);
      return;
    }
    onProfile(next);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 214,
      ),
      itemCount: BallStyle.catalog.length,
      itemBuilder: (context, index) {
        final style = BallStyle.catalog[index];
        return _ColorChoice(
          style: style,
          owned: profile.owns(style.id),
          selected: profile.selectedColorId == style.id,
          onTap: () => _choose(context, style),
        );
      },
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          if (selected)
            BoxShadow(color: style.mid.withValues(alpha: 0.28), blurRadius: 18),
        ],
      ),
      child: Material(
        color: const Color(0xE60B1C32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? style.mid : const Color(0x22FFFFFF),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
            child: Column(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: style.glow,
                    border: Border.all(color: style.mid, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: style.mid.withValues(
                          alpha: selected ? 0.55 : 0.3,
                        ),
                        blurRadius: selected ? 18 : 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: style.core,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  style.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                ShopAction(
                  label: label,
                  filled: selected,
                  accent: style.mid,
                  icon: owned ? null : Icons.monetization_on_rounded,
                ),
                SizedBox(
                  height: 18,
                  child: !owned && style.minStars > 0
                      ? Text(
                          '${style.minStars} estrelas',
                          style: const TextStyle(
                            color: Color(0xFFF5C542),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
