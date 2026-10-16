# Reflexo

Arcade casual em retrato: uma esfera luminosa troca de faixa com um toque, desvia de obstáculos e coleta energia.

Esta versão tem partida jogável, moedas, recorde local, cores da bola e áudio. Ainda não há anúncios.

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

Toque na tela para trocar a esfera entre as duas faixas. A rolagem acelera aos poucos. Colidir encerra a partida depois de uma animação curta. Coletar um orbe soma 25 pontos e solta partículas. O tempo sobrevivido soma 10 pontos por segundo.

## Decisões

- A esfera fica na base e o cenário desce. O toque durante a troca é ignorado.
- A pontuação e o spawn justo ficam em `lib/domain`, fora do Flame.
- Nunca há obstáculo nas duas faixas dentro da distância `velocidade * 0,28 s`. A folga usa a velocidade 3 segundos à frente, porque a rolagem ainda acelera enquanto o obstáculo está na tela.
- Partículas, rastro e o anel de coleta são só visuais. A colisão continua no tamanho real da esfera e dos obstáculos.
- Não há pool de objetos: poucos componentes na tela, e os que saem são removidos.
- Ao ir para segundo plano, a partida pausa.
# Reflexo-App
