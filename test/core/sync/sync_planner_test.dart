import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/sync/cloud_sync_service.dart';

void main() {
  final cloud = DateTime.utc(2026, 9, 20, 10);

  test('sem backup na nuvem, envia', () {
    expect(
      SyncPlanner.decide(
        cloudUpdatedAt: null,
        hasLocalData: true,
        knownCloudVersion: null,
      ),
      SyncAction.upload,
    );
  });

  test('aparelho vazio recebe o backup', () {
    expect(
      SyncPlanner.decide(
        cloudUpdatedAt: cloud,
        hasLocalData: false,
        knownCloudVersion: null,
      ),
      SyncAction.download,
    );
  });

  test('nuvem inalterada desde a última sincronização: envia', () {
    expect(
      SyncPlanner.decide(
        cloudUpdatedAt: cloud,
        hasLocalData: true,
        knownCloudVersion: cloud.toLocal(),
      ),
      SyncAction.upload,
    );
  });

  test('segundo aparelho com dados próprios: pede decisão', () {
    expect(
      SyncPlanner.decide(
        cloudUpdatedAt: cloud,
        hasLocalData: true,
        knownCloudVersion: null,
      ),
      SyncAction.conflict,
    );
  });

  test('outro aparelho enviou depois: pede decisão', () {
    expect(
      SyncPlanner.decide(
        cloudUpdatedAt: cloud,
        hasLocalData: true,
        knownCloudVersion: cloud.subtract(const Duration(hours: 1)),
      ),
      SyncAction.conflict,
    );
  });

  test('escolha do usuário resolve o conflito', () {
    expect(
      SyncPlanner.decide(
        cloudUpdatedAt: cloud,
        hasLocalData: true,
        knownCloudVersion: null,
        resolution: SyncResolution.keepLocal,
      ),
      SyncAction.upload,
    );
    expect(
      SyncPlanner.decide(
        cloudUpdatedAt: cloud,
        hasLocalData: true,
        knownCloudVersion: null,
        resolution: SyncResolution.useCloud,
      ),
      SyncAction.download,
    );
  });

  test('saudação usa só o primeiro nome', () {
    expect(CloudSyncService.firstName('Lincoln Queiroz'), 'Lincoln');
    expect(CloudSyncService.firstName('lincolnqueiroz201'), 'Lincolnqueiroz');
    expect(CloudSyncService.firstName('ana.maria_99'), 'Ana');
    expect(CloudSyncService.firstName('  '), isNull);
    expect(CloudSyncService.firstName('2024'), isNull);
  });
}
