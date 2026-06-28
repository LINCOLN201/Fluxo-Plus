import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import 'premium_entitlement.dart';

class PremiumService {
  PremiumService(this._database, this._client);

  static const _cacheKey = 'premium_entitlement';

  final AppDatabase _database;
  final SupabaseClient? _client;

  Future<PremiumEntitlement> load({bool refresh = false}) async {
    final user = _client?.auth.currentUser;
    if (user == null) return const PremiumEntitlement.free();

    if (!refresh) {
      final cached = await _readCache(user.id);
      if (cached != null) return cached;
    }

    try {
      final row = await _client!
          .from('premium_subscriptions')
          .select(
            'plan, status, current_period_end, trial_ends_at, updated_at',
          )
          .eq('user_id', user.id)
          .maybeSingle();
      final entitlement = row == null
          ? const PremiumEntitlement.free()
          : _fromMap(Map<String, dynamic>.from(row));
      await _writeCache(user.id, entitlement);
      return entitlement;
    } catch (_) {
      return await _readCache(user.id) ?? const PremiumEntitlement.free();
    }
  }

  Future<void> clearCache() => _database.db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [_cacheKey],
      );

  PremiumEntitlement _fromMap(Map<String, dynamic> map) {
    final plan = switch (map['plan']) {
      'premium' => PremiumPlan.premium,
      'lifetime' => PremiumPlan.lifetime,
      _ => PremiumPlan.free,
    };
    return PremiumEntitlement(
      plan: plan,
      status: map['status'] as String? ?? 'inactive',
      currentPeriodEnd: _date(map['current_period_end']),
      trialEndsAt: _date(map['trial_ends_at']),
    );
  }

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  Future<PremiumEntitlement?> _readCache(String userId) async {
    final rows = await _database.db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_cacheKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final data = jsonDecode(rows.first['value'] as String);
      if (data is! Map || data['user_id'] != userId) return null;
      return _fromMap(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    String userId,
    PremiumEntitlement entitlement,
  ) =>
      _database.db.insert(
        'settings',
        {
          'key': _cacheKey,
          'value': jsonEncode({
            'user_id': userId,
            'plan': entitlement.plan.name,
            'status': entitlement.status,
            'current_period_end':
                entitlement.currentPeriodEnd?.toUtc().toIso8601String(),
            'trial_ends_at': entitlement.trialEndsAt?.toUtc().toIso8601String(),
          }),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}
