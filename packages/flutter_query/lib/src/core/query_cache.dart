import 'package:collection/collection.dart';

import 'query.dart';
import 'query_cache_event.dart';
import 'query_key.dart';
import 'query_state.dart';
import 'subscribable.dart';

/// Signature for listeners that are notified whenever the `QueryCache`
/// emits a [QueryCacheEvent].
typedef QueryCacheListener = void Function(QueryCacheEvent event);

/// In–memory store for all active [Query] instances.
///
/// The cache is responsible for:
/// - indexing queries by their [QueryKey]
/// - finding queries that match a given key or predicate
/// - dispatching [QueryCacheEvent]s when queries are added, removed or updated.
class QueryCache with Subscribable<QueryCacheListener> {
  final Map<QueryKey, Query> _queries = {};

  /// Returns the cached query for the given [queryKey], or `null` if none
  /// exists or the generic types do not match.
  Query<TData, TError>? get<TData, TError>(List<Object?> queryKey) {
    final key = QueryKey(queryKey);
    return _queries[key] as Query<TData, TError>?;
  }

  /// Returns a snapshot list of all queries currently stored in the cache.
  List<Query> getAll() {
    return _queries.values.toList();
  }

  /// Adds [query] to the cache and notifies subscribers with a
  /// [QueryAddedEvent].
  void add(Query query) {
    _queries[query.key] = query;
    dispatch(QueryAddedEvent(query));
  }

  /// Removes [query] from the cache if it is still the exact instance
  /// associated with its key, disposes it, and dispatches a [QueryRemovedEvent].
  void remove(Query query) {
    final key = query.key;
    final cachedQuery = _queries[key];

    // Only remove if the query in the cache is the same instance
    if (cachedQuery == query) {
      query.dispose();
      _queries.remove(key);
      dispatch(QueryRemovedEvent(query));
    }
  }

  /// Removes and disposes the query associated with [queryKey], if any, and
  /// dispatches a [QueryRemovedEvent].
  void removeByKey(List<Object?> queryKey) {
    final key = QueryKey(queryKey);
    final query = _queries[key];
    if (query != null) {
      query.dispose();
      _queries.remove(key);
      dispatch(QueryRemovedEvent(query));
    }
  }

  /// Clears all queries from the cache, disposing each one and dispatching a
  /// [QueryRemovedEvent] for every removed query.
  void clear() {
    if (_queries.isEmpty) return;
    final queriesToRemove = _queries.values.toList();
    _queries.clear();
    for (final query in queriesToRemove) {
      query.dispose();
      dispatch(QueryRemovedEvent(query));
    }
  }

  /// Finds the first query that matches the provided filters.
  ///
  /// - [queryKey]: key to match against using [Query.matches].
  /// - [exact]: when `true`, the key must match exactly; otherwise partial
  ///   matches are allowed.
  /// - [predicate]: additional matcher that receives the query key and state.
  ///
  /// Returns `null` if no query satisfies all filters.
  Query<TData, TError>? find<TData, TError>(
    List<Object?> queryKey, {
    bool exact = true,
    bool Function(List<Object?> queryKey, QueryState state)? predicate,
  }) {
    return _queries.values.firstWhereOrNull((q) {
      if (!q.matches(queryKey, exact: exact)) return false;
      if (predicate != null && !q.matchesWhere(predicate)) return false;
      return true;
    }) as Query<TData, TError>?;
  }

  /// Returns all queries that satisfy the provided filters.
  ///
  /// When both [queryKey] and [predicate] are `null`, this is equivalent to
  /// calling [getAll].
  List<Query> findAll({
    List<Object?>? queryKey,
    bool exact = false,
    bool Function(List<Object?> queryKey, QueryState state)? predicate,
  }) {
    // If no filters provided, return all
    if (queryKey == null && predicate == null) {
      return getAll();
    }

    return _queries.values.where((query) {
      if (queryKey != null && !query.matches(queryKey, exact: exact)) {
        return false;
      }
      if (predicate != null && !query.matchesWhere(predicate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Notifies all registered listeners of the given [event].
  void dispatch(QueryCacheEvent event) {
    notify((listener) => listener(event));
  }
}
