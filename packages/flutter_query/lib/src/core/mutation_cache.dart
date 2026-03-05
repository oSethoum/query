import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'mutation.dart';
import 'mutation_cache_event.dart';
import 'mutation_state.dart';
import 'subscribable.dart';

/// Signature for listeners that are notified whenever the [MutationCache]
/// emits a [MutationCacheEvent].
typedef MutationCacheListener = void Function(MutationCacheEvent event);

/// In–memory store for all active [Mutation] instances.
///
/// The cache tracks active mutations, provides helpers to look them up
/// by key, status or predicate, and dispatches [MutationCacheEvent]s on
/// changes.
class MutationCache with Subscribable<MutationCacheListener> {
  final Set<Mutation> _mutations = {};
  int _mutationIdCounter = 0;

  /// Returns the next monotonically increasing identifier used to tag
  /// new mutations created by this cache.
  @internal
  int getNextMutationId() => _mutationIdCounter++;

  /// Returns a snapshot list of all mutations currently stored in the cache.
  List<Mutation> getAll() {
    return _mutations.toList();
  }

  /// Adds [mutation] to the cache and notifies subscribers with a
  /// [MutationAddedEvent].
  void add(Mutation mutation) {
    _mutations.add(mutation);
    dispatch(MutationAddedEvent(mutation));
  }

  /// Removes [mutation] from the cache, disposes it, and dispatches a
  /// [MutationRemovedEvent] if it was present.
  void remove(Mutation mutation) {
    if (_mutations.remove(mutation)) {
      mutation.dispose();
      dispatch(MutationRemovedEvent(mutation));
    }
  }

  /// Clears all mutations from the cache, disposing each one and dispatching
  /// a [MutationRemovedEvent] for every removed mutation.
  void clear() {
    if (_mutations.isEmpty) return;
    final mutationsToRemove = _mutations.toList();
    _mutations.clear();
    for (final mutation in mutationsToRemove) {
      mutation.dispose();
      dispatch(MutationRemovedEvent(mutation));
    }
  }

  /// Finds the first mutation that matches the provided filters.
  ///
  /// The match is delegated to [Mutation.matches] using:
  /// - [exact]: whether to require an exact key match.
  /// - [predicate]: custom matcher over mutation key and state.
  /// - [mutationKey]: key used for matching.
  /// - [status]: restricts matches to a specific [MutationStatus].
  Mutation? find({
    bool exact = true,
    bool Function(List<Object?>? mutationKey, MutationState state)? predicate,
    List<Object?>? mutationKey,
    MutationStatus? status,
  }) {
    return _mutations.firstWhereOrNull((mut) => mut.matches(
          exact: exact,
          predicate: predicate,
          mutationKey: mutationKey,
          status: status,
        ));
  }

  /// Returns all mutations that satisfy the provided filters.
  ///
  /// Filtering semantics are the same as for [find], but returns every
  /// matching mutation instead of only the first.
  List<Mutation> findAll({
    bool exact = false,
    bool Function(List<Object?>? mutationKey, MutationState state)? predicate,
    List<Object?>? mutationKey,
    MutationStatus? status,
  }) {
    return _mutations
        .where((mut) => mut.matches(
              exact: exact,
              predicate: predicate,
              mutationKey: mutationKey,
              status: status,
            ))
        .toList();
  }

  /// Notifies all registered listeners of the given [event].
  void dispatch(MutationCacheEvent event) {
    notify((listener) => listener(event));
  }
}
