import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_update.dart';

class UpdateService {
  UpdateService({
    http.Client? client,
    String repository = const String.fromEnvironment('UPDATE_REPOSITORY'),
  })  : _client = client ?? http.Client(),
        _repository = repository;

  final http.Client _client;
  final String _repository;
  static const _installer = MethodChannel('br.com.fluxoplus.app/installer');

  bool get isConfigured => _repository.contains('/');

  Future<String> currentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  Future<AppUpdate?> check() async {
    if (!isConfigured) return null;

    final response = await _client.get(
      Uri.https('api.github.com', '/repos/$_repository/releases/latest'),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw StateError(
        'Servidor de atualizações indisponível (${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
    final current = await currentVersion();
    if (!_isNewer(tag, current)) return null;

    final assets = (data['assets'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final wantedExtension = Platform.isWindows ? '.zip' : '.apk';
    final asset = assets.cast<Map<String, dynamic>?>().firstWhere(
          (item) => (item?['name'] as String? ?? '').endsWith(wantedExtension),
          orElse: () => null,
        );
    final releaseUrl = Uri.tryParse(data['html_url'] as String? ?? '');
    final downloadUrl = Uri.tryParse(
      asset?['browser_download_url'] as String? ?? '',
    );
    if (releaseUrl == null || downloadUrl == null) return null;

    return AppUpdate(
      version: tag,
      releaseUrl: releaseUrl,
      downloadUrl: downloadUrl,
      notes: data['body'] as String? ?? '',
      mandatory: (data['body'] as String? ?? '').contains('[mandatory]'),
    );
  }

  Future<bool> openDownload(AppUpdate update) => launchUrl(
        update.downloadUrl,
        mode: LaunchMode.externalApplication,
      );

  Future<InstallResult> downloadAndInstall(
    AppUpdate update, {
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isAndroid) {
      return await openDownload(update)
          ? InstallResult.externalDownload
          : InstallResult.failed;
    }

    final response = await _client
        .send(http.Request('GET', update.downloadUrl))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw StateError(
        'Não foi possível baixar a atualização (${response.statusCode}).',
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'fluxo-plus-${update.version}.apk',
    );
    final sink = file.openWrite();
    var received = 0;
    final total = response.contentLength ?? 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
    } finally {
      await sink.close();
    }
    onProgress?.call(1);

    final result = await _installer.invokeMethod<String>(
      'installApk',
      {'path': file.path},
    );
    return switch (result) {
      'started' => InstallResult.installerStarted,
      'permission_required' => InstallResult.permissionRequired,
      _ => InstallResult.failed,
    };
  }

  bool _isNewer(String candidate, String current) {
    final next = _parts(candidate);
    final installed = _parts(current);
    for (var index = 0; index < 3; index++) {
      if (next[index] != installed[index]) {
        return next[index] > installed[index];
      }
    }
    return false;
  }

  List<int> _parts(String value) {
    final values = value.split('.').take(3).map(
          (part) => int.tryParse(RegExp(r'\d+').stringMatch(part) ?? '') ?? 0,
        );
    return [...values, 0, 0, 0].take(3).toList();
  }

  void close() => _client.close();
}

enum InstallResult {
  installerStarted,
  permissionRequired,
  externalDownload,
  failed,
}
