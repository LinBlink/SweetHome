import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_config.dart';
import '../models/api_exception.dart';
import '../models/auth_models.dart';
import '../models/moment.dart';
import '../services/auth_service.dart';

/// State for the family-feed sub-screen (§7).
///
/// Owns the family-moments list (cursor-paginated, default
/// newest-first), the publish flow (collects media drafts, uploads
/// them one at a time via `AuthService.uploadVideo/Audio/Image`,
/// then calls `MomentService.publishMoment`), and the per-row like
/// toggling. Per the spec:
///  - §7.4: `POST /moment/liker/{id}` always succeeds — `INSERT ...
///    ON DUPLICATE KEY UPDATE like_count = like_count + 1`. Repeated
///    clicks all increment, so unlike is the explicit remove:
///  - §7.5: `DELETE` clears the entire row (404 if the user never
///    liked).
///
/// We don't have an endpoint to ask the server "did I like this?" —
/// only the toggle endpoint and the count. So the client keeps a
/// `_myLikes` set of momentIds the current user has *expressed*
/// liking (an optimistic intent). That set is the source of truth
/// for the heart icon; on error we remove the id from it.
class MomentProvider extends ChangeNotifier {
  MomentProvider({
    required AuthUser currentUser,
    required this.service,
  }) : _currentUser = currentUser;

  final AuthUser _currentUser;
  final dynamic service; // `MomentService`; dynamic keeps imports
  //   off the constructor's type-checking surface.

  // ── feed state ──────────────────────────────────────────────────
  final List<Moment> _moments = [];
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;
  int _total = 0;
  String? _error;
  String? _loadMoreError;

  /// Server-derived counts, keyed by momentId. Maps to the latest
  /// count we observed (either from feed fetch or from
  /// `fetchLikeCount`). Kept separately so we can render the heart
  /// count without polluting the Moment DTO.
  final Map<int, int> _likeCounts = {};

  /// User's like-intent set (the optimistic source-of-truth for the
  /// heart icon). Membership = "current user has liked this".
  final Set<int> _myLikes = {};

  List<Moment> get moments => List.unmodifiable(_moments);
  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get total => _total;
  String? get error => _error;
  String? get loadMoreError => _loadMoreError;

  /// Authoritative like count or `0` if we haven't fetched yet.
  int likeCountOf(int momentId) => _likeCounts[momentId] ?? 0;

  /// True iff the current user has tapped the heart at least once on
  /// this moment (an optimistic intent flag). Note this is *not* an
  /// authoritative server check — there's no §7 endpoint that returns
  /// "did the current user already like this moment", and the per-user
  /// `moment_liker` row exists only after a successful POST. Used by
  /// the UI to render the heart as filled and to know it can be
  /// long-pressed to clear. Long-press flips it back to false so
  /// re-tapping starts fresh from the cleared count.
  bool hasMyLike(int momentId) => _myLikes.contains(momentId);

  Future<void> loadInitial() async {
    if (AppConfig.mockMode) {
      // Per the chosen scope, no mock-data fixtures for moments —
      // an empty-feed behaviour in mock mode is the source of truth.
      _isInitialLoading = false;
      _moments.clear();
      _likeCounts.clear();
      _myLikes.clear();
      _hasMore = false;
      notifyListeners();
      return;
    }
    _isInitialLoading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await service.fetchFamilyMoments(page: 1);
      _moments
        ..clear()
        ..addAll(_sortedDesc(page.moments));
      _total = page.total;
      _hasMore = _moments.length < page.total;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = "Couldn't load the feed — pull to refresh.";
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final page = await service.fetchFamilyMoments(page: 1);
      _moments
        ..clear()
        ..addAll(_sortedDesc(page.moments));
      _total = page.total;
      _hasMore = _moments.length < page.total;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = "Couldn't refresh the feed.";
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _loadMoreError = null;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _moments.length ~/ 10 + 1;
      final page = await service.fetchFamilyMoments(page: nextPage);
      _moments.addAll(_sortedDesc(page.moments));
      _sortInPlaceDesc();
      _hasMore = _moments.length < page.total;
    } on ApiException catch (e) {
      _loadMoreError = e.message;
    } catch (_) {
      _loadMoreError = "Couldn't load more.";
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  static List<Moment> _sortedDesc(List<Moment> input) {
    final copy = List<Moment>.from(input);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  void _sortInPlaceDesc() {
    _moments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// One-shot like increment. Bound to the heart's *tap* gesture.
  /// Per §7.4 each call is `INSERT ... ON DUPLICATE KEY UPDATE
  /// like_count = like_count + 1` — there is no server-side notion
  /// of "first like vs. another click", so repeated taps simply
  /// keep accumulating for the current user. The local count is
  /// updated optimistically and reconciled against the authoritative
  /// `fetchLikeCount` reply so the UI catches up if other family
  /// members also like while this tap is in flight.
  Future<void> addLike(int momentId) async {
    final previous = _likeCounts[momentId] ?? 0;
    _likeCounts[momentId] = previous + 1;
    _myLikes.add(momentId);
    notifyListeners();
    try {
      await service.likeMoment(momentId);
      final real = await service.fetchLikeCount(momentId);
      _likeCounts[momentId] = real;
      notifyListeners();
    } catch (_) {
      _likeCounts[momentId] = previous;
      _myLikes.remove(momentId);
      notifyListeners();
    }
  }

  /// Clear the current user's likes on this moment. Bound to the
  /// heart's *long-press* gesture. Per §7.5 the server removes the
  /// caller's entire `moment_liker` row (one row per
  /// `(moment, user)`); after that the count drops by however many
  /// taps this user contributed. We optimistically zero the local
  /// count (under the assumption this user was the only contributor)
  /// and reconcile against `fetchLikeCount` so the truth wins if
  /// other family members had also tapped. A 404 from the server
  /// (`NO_SUCH_LIKE_RECORD`) is treated as a no-op success — the
  /// user's row already wasn't there.
  Future<void> cancelLike(int momentId) async {
    final previous = _likeCounts[momentId] ?? 0;
    _myLikes.remove(momentId);
    _likeCounts[momentId] = 0;
    notifyListeners();
    try {
      await service.unlikeMoment(momentId);
    } on ApiException catch (e) {
      if (e.code != 404) {
        _likeCounts[momentId] = previous;
        notifyListeners();
        rethrow;
      }
    } catch (_) {
      _likeCounts[momentId] = previous;
      notifyListeners();
      rethrow;
    }
    try {
      final real = await service.fetchLikeCount(momentId);
      _likeCounts[momentId] = real;
      notifyListeners();
    } catch (_) {
      // even if the second round fails, the delete has happened;
      // leave whatever the optimistic write left in place.
    }
  }

  /// Delete the current user's own moment. Per §7.3 only the owner
  /// can delete; on 403 the screen surfaces the error and we
  /// rollback the optimistic removal.
  Future<void> deleteMoment(int momentId) async {
    final idx = _moments.indexWhere((m) => m.id == momentId);
    if (idx < 0) return;
    final removed = _moments.removeAt(idx);
    _likeCounts.remove(momentId);
    _myLikes.remove(momentId);
    _total = _total > 0 ? _total - 1 : 0;
    notifyListeners();
    try {
      await service.deleteMoment(momentId);
    } on ApiException catch (e) {
      _moments.insert(idx.clamp(0, _moments.length), removed);
      _total = _total + 1;
      _error = e.message;
      notifyListeners();
      rethrow;
    } catch (_) {
      _moments.insert(idx.clamp(0, _moments.length), removed);
      _total = _total + 1;
      _error = "Couldn't delete — please try again.";
      notifyListeners();
      rethrow;
    }
  }

  Future<MomentLikeDetail> fetchLikeDetail(int momentId) {
    return service.fetchLikeDetail(momentId);
  }

  /// Refresh just the like count of one row — useful after the
  /// detail screen's like-list sheet closes, since `fetchLikeDetail`
  /// is more expensive than `fetchLikeCount`.
  Future<void> refreshLikeCount(int momentId) async {
    try {
      _likeCounts[momentId] = await service.fetchLikeCount(momentId);
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── publish flow ────────────────────────────────────────────────
  bool _isPublishing = false;
  int _publishUploaded = 0;
  int _publishTotal = 0;
  String? _publishError;

  bool get isPublishing => _isPublishing;
  int get publishUploaded => _publishUploaded;
  int get publishTotal => _publishTotal;
  String? get publishError => _publishError;

  /// Publish a new family moment. Order: upload every draft through
  /// §2.4/§2.5/§2.6 (in input order) so we can show per-file
  /// progress, then fire §7.1 once with the full URL list. The
  /// optimistic first-page refresh happens on success.
  Future<void> publish({
    String? content,
    required List<MomentDraft> drafts,
  }) async {
    if (_isPublishing) return;
    if ((content == null || content.trim().isEmpty) && drafts.isEmpty) {
      _publishError = 'Add a photo or write something to post.';
      notifyListeners();
      return;
    }
    _isPublishing = true;
    _publishError = null;
    _publishUploaded = 0;
    _publishTotal = drafts.length;
    notifyListeners();

    final wireMedia = <Map<String, String>>[];
    try {
      for (final draft in drafts) {
        final url = await _upload(draft);
        wireMedia.add({'type': _wireType(draft.kind), 'content': url});
        _publishUploaded++;
        notifyListeners();
      }
      final trimmed = content?.trim();
      await service.publishMoment(
        content: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        media: wireMedia,
      );
      _isPublishing = false;
      _publishUploaded = 0;
      _publishTotal = 0;
      notifyListeners();
      await refresh();
    } on ApiException catch (e) {
      _isPublishing = false;
      _publishError = e.message;
      notifyListeners();
    } catch (_) {
      _isPublishing = false;
      _publishError = "Couldn't post — please try again.";
      notifyListeners();
    }
  }

  Future<String> _upload(MomentDraft draft) async {
    if (draft.fromPicked != null) {
      final picked = draft.fromPicked!;
      final bytes = await picked.readAsBytes();
      if (draft.kind == MomentDraftKind.video) {
        return AuthService.uploadVideo(
          _currentUser,
          bytes: bytes,
          filename: picked.name,
          contentType: 'video/mp4',
        );
      }
      return AuthService.uploadImage(
        _currentUser,
        bytes: bytes,
        filename: picked.name,
        contentType: 'image/jpeg',
      );
    }
    final recorded = draft.fromRecorded!;
    return AuthService.uploadAudio(
      _currentUser,
      bytes: recorded.bytes,
      filename: recorded.filename,
      contentType: 'audio/ogg',
    );
  }

  String _wireType(MomentDraftKind kind) {
    switch (kind) {
      case MomentDraftKind.photo:
        return 'image';
      case MomentDraftKind.video:
        return 'video';
      case MomentDraftKind.audio:
        return 'audio';
    }
  }
}

/// Wire-shape kind of a media draft (drives the §2.x upload
/// endpoint selector and the §7.1 `media[].type` value).
enum MomentDraftKind { photo, video, audio }

/// One pending piece of media in the publish composer. Exactly one
/// of [fromPicked] / [fromRecorded] is non-null per draft.
class MomentDraft {
  final MomentDraftKind kind;
  final XFile? fromPicked;
  final MomentRecordedAudio? fromRecorded;

  const MomentDraft._({
    required this.kind,
    this.fromPicked,
    this.fromRecorded,
  }) : assert(fromPicked != null || fromRecorded != null,
            'MomentDraft requires one source');

  factory MomentDraft.fromXFile(XFile file, MomentDraftKind kind) {
    return MomentDraft._(kind: kind, fromPicked: file);
  }

  factory MomentDraft.fromAudio(MomentRecordedAudio audio) {
    return MomentDraft._(kind: MomentDraftKind.audio, fromRecorded: audio);
  }
}

/// Locally-recorded audio clip ready for §2.6 upload. The recorder
/// writes opus bytes ([bytes]) and a hint filename; [durationSec]
/// is purely for the composer's UI display.
class MomentRecordedAudio {
  final Uint8List bytes;
  final String filename;
  final int? durationSec;

  const MomentRecordedAudio({
    required this.bytes,
    required this.filename,
    this.durationSec,
  });
}
