/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

/// A representation of connection changes created by the `RedisConnector` when
/// the connection state changes.
class RedisConnectionStateChange {
  RedisConnectionStateChange({
    required this.currentState,
    required this.previousState,
  });

  /// The new state of the connection.
  final RedisConnectionState currentState;

  /// The previous state of the connection.
  final RedisConnectionState previousState;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RedisConnectionStateChange && currentState == other.currentState && previousState == other.previousState;

  @override
  int get hashCode => currentState.hashCode & previousState.hashCode;
}
