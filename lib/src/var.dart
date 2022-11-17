/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

// cSpell:disable
part of redis;

const List<String> subscriberModeAvailableCommands = [
  'SUBSCRIBE',
  'SSUBSCRIBE',
  'SUNSUBSCRIBE',
  'PSUBSCRIBE',
  'UNSUBSCRIBE',
  'PUNSUBSCRIBE',
  'PING',
  'RESET',
  'QUIT',
];

/// State of the Redis client.
enum RedisConnectionState {
  /// The connector is attempting to connect to the Redis server.
  connecting,

  /// The connector is connected to the Redis server.
  ready,

  /// The connector is attempting to disconnect from the Redis server.
  /// This is usually only indicated when close() is called on the underlying
  /// connector.
  closing,

  /// The connector is disconnected from the Redis server.
  /// This is the default state for new instances of the connectors.
  closed,

  /// An error has occurred when attempting to connect to the Redis server
  /// or when the connection is closed due to an error.
  /// Sent after the [closed] state.
  error,
}
