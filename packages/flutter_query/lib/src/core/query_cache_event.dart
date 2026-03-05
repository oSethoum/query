import 'package:meta/meta.dart';

import 'query.dart';

/// Base type for all events emitted by [QueryCache] to its listeners.
@internal
sealed class QueryCacheEvent {
  const QueryCacheEvent();
}

/// Event fired when a new [query] is added to the [QueryCache].
@internal
final class QueryAddedEvent extends QueryCacheEvent {
  const QueryAddedEvent(this.query);

  /// The query instance that was added to the cache.
  final Query query;
}

/// Event fired when an existing [query] is removed from the [QueryCache].
@internal
final class QueryRemovedEvent extends QueryCacheEvent {
  const QueryRemovedEvent(this.query);

  /// The query instance that was removed from the cache.
  final Query query;
}

/// Event fired when an existing [query] in the [QueryCache] is updated.
@internal
final class QueryUpdatedEvent extends QueryCacheEvent {
  const QueryUpdatedEvent(this.query);

  /// The query instance that was updated.
  final Query query;
}
