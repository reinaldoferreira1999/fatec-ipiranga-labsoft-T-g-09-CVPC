import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final resultados = <String, String>{};

  // 1. .flutter-plugins-dependencies
  final pluginsFile = File('.flutter-plugins-dependencies');
  if (await pluginsFile.exists()) {
    try {
      final data = jsonDecode(await pluginsFile.readAsString());
      if (data is Map && data.containsKey('flutterVersion')) {
        resultados['.flutter-plugins-dependencies'] =
            data['flutterVersion'].toString();
      }
    } catch (_) {}
  }

  // 2. pubspec.lock
  final lockFile = File('pubspec.lock');
  if (await lockFile.exists()) {
    final linhas = await lockFile.readAsLines();
    for (final linha in linhas) {
      if (linha.toLowerCase().contains('flutter') &&
          linha.toLowerCase().contains('version')) {
        resultados['pubspec.lock'] = linha.trim();
      }
    }
  }

  // 3. Arquivo "version" dentro do SDK do Flutter (se disponível)
  final caminhosPossiveis = [
    '${Platform.environment['HOME']}/flutter/bin/internal/version',
    'C:/src/flutter/bin/internal/version',
  ];

  for (final caminho in caminhosPossiveis) {
    final file = File(caminho);
    if (await file.exists()) {
      resultados['sdk_version_file'] = (await file.readAsString()).trim();
    }
  }

  // Exibir resultado
  if (resultados.isNotEmpty) {
    print('✅ Versões encontradas:');
    resultados.forEach((origem, versao) {
      print(' - $origem: $versao');
    });
  } else {
    print('⚠️ Nenhuma informação de versão encontrada nos arquivos comuns.');
  }
}