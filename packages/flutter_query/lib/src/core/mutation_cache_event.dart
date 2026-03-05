import 'package:meta/meta.dart';

import 'mutation.dart';

/// Base type for all events emitted by [MutationCache] to its listeners.
@internal
sealed class MutationCacheEvent {
  const MutationCacheEvent();
}

/// Event fired when a new [mutation] is added to the [MutationCache].
@internal
final class MutationAddedEvent extends MutationCacheEvent {
  const MutationAddedEvent(this.mutation);

  /// The mutation instance that was added to the cache.
  final Mutation mutation;
}

/// Event fired when an existing [mutation] is removed from the [MutationCache].
@internal
final class MutationRemovedEvent extends MutationCacheEvent {
  const MutationRemovedEvent(this.mutation);

  /// The mutation instance that was removed from the cache.
  final Mutation mutation;
}

/// Event fired when an existing [mutation] in the [MutationCache] is updated.
@internal
final class MutationUpdatedEvent extends MutationCacheEvent {
  const MutationUpdatedEvent(this.mutation);

  /// The mutation instance that was updated.
  final Mutation mutation;
}
