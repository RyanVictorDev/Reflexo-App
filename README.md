# Reflexo

Arcade casual em retrato: uma esfera luminosa troca de faixa com um toque, desvia de obstáculos e coleta energia.

Esta versão tem partida jogável, três dificuldades, rank, desafios do dia, moedas, recorde local, cores da bola e áudio. Ainda não há anúncios.

## Requisitos

O Flutter do PATH desta máquina é antigo e não serve para este projeto. Use o SDK separado:

`C:\Users\vryan\sdks\flutter`

Ele é o Flutter 3.47.7 com Dart 3.13.5. O SDK antigo em `Downloads\framework\flutter` não foi alterado.

O identificador Android provisório é `com.reflexo.game`. Troque antes de publicar na Play Store se você tiver um pacote próprio.

## Rodar

No PowerShell, na pasta do projeto:

```powershell
& "C:\Users\vryan\sdks\flutter\bin\flutter.bat" devices
& "C:\Users\vryan\sdks\flutter\bin\flutter.bat" emulators --launch Pixel_8_API_36
& "C:\Users\vryan\sdks\flutter\bin\flutter.bat" run -d emulator-5554
```

Testes:

```powershell
& "C:\Users\vryan\sdks\flutter\bin\flutter.bat" test
```

O Cursor está apontado para esse SDK em `.vscode/settings.json`.

## Como jogar

Toque na tela para trocar a esfera entre as duas faixas. A rolagem acelera aos poucos e a barra de ritmo mostra o quanto a partida já esquentou. Colidir encerra a partida depois de uma animação curta. Coletar um orbe soma 25 pontos e solta partículas. O tempo sobrevivido soma 10 pontos por segundo.

Na tela inicial dá para escolher Calmo, Normal ou Intenso. O Calmo dá mais folga e mais orbes, com 0,6x de moedas e XP. O Normal é a curva de sempre. O Intenso começa mais rápido, aperta o vão e paga 1,5x. Cada modo guarda o próprio recorde.

Toda partida soma XP. O rank vai de Iniciante até Lenda. Três desafios do dia pagam moedas extras uma vez; no dia seguinte o trio muda.

## Decisões

- A esfera fica na base e o cenário desce. O toque durante a troca é ignorado.
- A pontuação, a dificuldade, o rank, os desafios e o spawn justo ficam em `lib/domain`, fora do Flame.
- Nunca há obstáculo nas duas faixas dentro da distância `velocidade * 0,28 s`. A folga usa a velocidade 3 segundos à frente, porque a rolagem ainda acelera enquanto o obstáculo está na tela. A dificuldade muda a velocidade e o vão, não essa regra.
- Partículas, rastro e o anel de coleta são só visuais. A colisão continua no tamanho real da esfera e dos obstáculos.
- Não há pool de objetos: poucos componentes na tela, e os que saem são removidos.
- Ao ir para segundo plano, a partida pausa.
# Reflexo-App
