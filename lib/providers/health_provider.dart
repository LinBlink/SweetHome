import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/api_exception.dart';
import '../models/health_record.dart';
import '../services/health_service.dart';

/// State for the family health module (§8).
///
/// Owns the user's own health records (history), visibility settings
/// per metric type, daily reminder config, and the view of family
/// members' public records. Follows the mock/real branching pattern
/// used by [MomentProvider] / [LocationProvider].
class HealthProvider extends ChangeNotifier {
  HealthProvider({
    required this.service,
    required bool mockMode,
  }) : _mockMode = mockMode;

  final HealthService service;
  final bool _mockMode;

  // ── Own records ──────────────────────────────────────────────────
  List<HealthRecord> _ownRecords = [];
  bool _ownRecordsLoading = false;
  String? _ownRecordsError;

  List<HealthRecord> get ownRecords => List.unmodifiable(_ownRecords);
  bool get ownRecordsLoading => _ownRecordsLoading;
  String? get ownRecordsError => _ownRecordsError;

  // ── Family member records ────────────────────────────────────────
  final Map<int, List<HealthRecord>> _familyRecords = {};
  final Map<int, bool> _familyRecordsLoading = {};
  final Map<int, String?> _familyRecordsError = {};

  List<HealthRecord> familyRecordsOf(int memberId) =>
      List.unmodifiable(_familyRecords[memberId] ?? const []);
  bool familyRecordsLoading(int memberId) =>
      _familyRecordsLoading[memberId] ?? false;
  String? familyRecordsError(int memberId) =>
      _familyRecordsError[memberId];

  // ── Visibility settings ──────────────────────────────────────────
  List<HealthVisibility> _visibilities = _defaultVisibilities();
  bool _visibilitiesLoading = false;

  List<HealthVisibility> get visibilities => List.unmodifiable(_visibilities);
  bool get visibilitiesLoading => _visibilitiesLoading;

  bool isMetricVisible(HealthMetricType type) {
    for (final v in _visibilities) {
      if (v.metricType == type) return v.visible;
    }
    return false;
  }

  // ── Reminder ─────────────────────────────────────────────────────
  HealthReminder _reminder = const HealthReminder();
  bool _reminderLoading = false;

  HealthReminder get reminder => _reminder;
  bool get reminderLoading => _reminderLoading;

  // ── Submit state ─────────────────────────────────────────────────
  bool _isSubmitting = false;
  String? _submitError;

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;

  // ── Edit state ──────────────────────────────────────────────────
  bool _isEditing = false;
  String? _editError;
  int? _editErrorCode;

  bool get isEditing => _isEditing;
  String? get editError => _editError;
  int? get editErrorCode => _editErrorCode;

  static List<HealthVisibility> _defaultVisibilities() => const [
    HealthVisibility(metricType: HealthMetricType.height, visible: false),
    HealthVisibility(metricType: HealthMetricType.weight, visible: false),
    HealthVisibility(metricType: HealthMetricType.bloodPressure, visible: false),
  ];

  // ── Public API ───────────────────────────────────────────────────

  /// Load own records + visibility + reminder in parallel on first
  /// screen visit, like [MomentProvider.loadInitial].
  Future<void> loadInitial() async {
    await Future.wait([
      loadOwnRecords(),
      loadVisibilities(),
      loadReminder(),
    ]);
  }

  /// §8.2 — Fetch own health record history.
  Future<void> loadOwnRecords({
    HealthMetricType? metricType,
    String? from,
    String? to,
  }) async {
    _ownRecordsLoading = true;
    _ownRecordsError = null;
    notifyListeners();

    try {
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        var records = MockHealthData.ownRecords;
        if (metricType != null) {
          records = records.where((r) => r.metricType == metricType).toList();
        }
        _ownRecords = records;
      } else {
        _ownRecords = await service.queryOwnRecords(
          metricType: metricType,
          from: from,
          to: to,
          pageSize: 100,
        );
      }
    } catch (e) {
      _ownRecordsError = e.toString();
    } finally {
      _ownRecordsLoading = false;
      notifyListeners();
    }
  }

  /// §8.1 — Submit (or update) a health record.
  Future<HealthRecord?> submitRecord({
    required HealthMetricType metricType,
    required double value,
    double? valueSecondary,
    String? recordedAt,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      HealthRecord record;
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        record = HealthRecord(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: 1,
          metricType: metricType,
          value: value,
          valueSecondary: valueSecondary,
          recordedAt: recordedAt ?? _todayString(),
        );
        MockHealthData.addOrUpdateRecord(record);
      } else {
        record = await service.submitRecord(
          metricType: metricType,
          value: value,
          valueSecondary: valueSecondary,
          recordedAt: recordedAt,
        );
      }
      // Refresh own records after successful submit.
      _upsertLocal(record);
      return record;
    } catch (e) {
      _submitError = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// §8.3 — Manually edit an existing record.
  ///
  /// Distinct from [submitRecord] in two ways:
  /// - It addresses a record by `id`, not by `(userId, metricType,
  ///   recordedAt)`. The local cache is updated by `id` rather than
  ///   by upsert key, so a date change doesn't accidentally collide
  ///   with the key used by §8.1.
  /// - Errors are propagated, not swallowed, so the edit sheet can
  ///   show the specific failure (409 conflict / 404 not-found /
  ///   403 not-owner). The submit path swallows into `_submitError`
  ///   because that flow only has a single all-purpose error slot.
  Future<HealthRecord?> updateRecord({
    required int recordId,
    required double value,
    double? valueSecondary,
    String? recordedAt,
  }) async {
    _isEditing = true;
    _editError = null;
    _editErrorCode = null;
    notifyListeners();

    try {
      HealthRecord updated;
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        updated = MockHealthData.updateRecord(
          recordId: recordId,
          value: value,
          valueSecondary: valueSecondary,
          recordedAt: recordedAt,
        );
      } else {
        updated = await service.updateRecord(
          recordId: recordId,
          value: value,
          valueSecondary: valueSecondary,
          recordedAt: recordedAt,
        );
      }
      _replaceLocalById(updated);
      return updated;
    } on ApiException catch (e) {
      _editError = e.message;
      _editErrorCode = e.code;
      return null;
    } catch (e) {
      _editError = e.toString();
      return null;
    } finally {
      _isEditing = false;
      notifyListeners();
    }
  }

  /// Clear the edit error after the sheet consumes it (e.g. user
  /// dismisses the error banner and re-edits).
  void clearEditError() {
    if (_editError == null && _editErrorCode == null) return;
    _editError = null;
    _editErrorCode = null;
    notifyListeners();
  }

  /// §8.3 — Fetch a family member's public health records.
  Future<void> loadFamilyRecords(int memberId, {HealthMetricType? metricType}) async {
    _familyRecordsLoading[memberId] = true;
    _familyRecordsError[memberId] = null;
    notifyListeners();

    try {
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        _familyRecords[memberId] =
            MockHealthData.familyRecordsFor(memberId);
      } else {
        _familyRecords[memberId] = await service.queryFamilyRecords(
          memberId: memberId,
          metricType: metricType,
          pageSize: 100,
        );
      }
    } catch (e) {
      _familyRecordsError[memberId] = e.toString();
    } finally {
      _familyRecordsLoading[memberId] = false;
      notifyListeners();
    }
  }

  /// §8.4 — Load visibility settings.
  Future<void> loadVisibilities() async {
    _visibilitiesLoading = true;
    notifyListeners();

    try {
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _visibilities = MockHealthData.visibilities;
      } else {
        _visibilities = await service.queryVisibility();
      }
    } catch (_) {
      // Default to all-private on error.
      _visibilities = _defaultVisibilities();
    } finally {
      _visibilitiesLoading = false;
      notifyListeners();
    }
  }

  /// §8.5 — Toggle one metric type's visibility.
  Future<void> toggleVisibility(HealthMetricType type, bool visible) async {
    try {
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        MockHealthData.setVisibility(type, visible);
        _visibilities = MockHealthData.visibilities;
      } else {
        await service.updateVisibility(metricType: type, visible: visible);
      }
      // Update local cache.
      for (var i = 0; i < _visibilities.length; i++) {
        if (_visibilities[i].metricType == type) {
          _visibilities[i] = HealthVisibility(metricType: type, visible: visible);
          break;
        }
      }
      notifyListeners();
    } catch (_) {
      // Revert on failure — reload from server.
      await loadVisibilities();
    }
  }

  /// §8.6 — Load reminder settings.
  Future<void> loadReminder() async {
    _reminderLoading = true;
    notifyListeners();

    try {
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        _reminder = MockHealthData.reminder;
      } else {
        _reminder = await service.queryReminder();
      }
    } catch (_) {
      _reminder = const HealthReminder();
    } finally {
      _reminderLoading = false;
      notifyListeners();
    }
  }

  /// §8.7 — Update reminder settings.
  Future<void> updateReminder({
    required String remindTime,
    required bool enabled,
  }) async {
    try {
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        MockHealthData.setReminder(remindTime, enabled);
        _reminder = MockHealthData.reminder;
      } else {
        await service.updateReminder(remindTime: remindTime, enabled: enabled);
        _reminder = _reminder.copyWith(remindTime: remindTime, enabled: enabled);
      }
      notifyListeners();
    } catch (_) {
      await loadReminder();
    }
  }

  /// Insert or update a record in the local [_ownRecords] list,
  /// maintaining [recordedAt] DESC order. Same-date same-metric
  /// replaces the existing entry (identical to server's upsert).
  void _upsertLocal(HealthRecord record) {
    final idx = _ownRecords.indexWhere(
      (r) => r.metricType == record.metricType && r.recordedAt == record.recordedAt,
    );
    if (idx >= 0) {
      _ownRecords[idx] = record;
    } else {
      _ownRecords.add(record);
      _ownRecords.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    notifyListeners();
  }

  /// Replace a record by `id` (not by `(metricType, recordedAt)` as
  /// [_upsertLocal] does). Used by §8.3's edit flow, where the date
  /// may have moved — matching by upsert key would orphan the old
  /// row when the new date collides with another record, and miss
  /// the original entirely when the new date is novel.
  ///
  /// Re-sorts the list by `recordedAt` DESC after replacement so the
  /// timeline order stays consistent with the submit path.
  void _replaceLocalById(HealthRecord record) {
    final idx = _ownRecords.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      _ownRecords[idx] = record;
      _ownRecords.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    } else {
      _ownRecords.add(record);
      _ownRecords.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    }
    notifyListeners();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
