/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

/// Redis connection information. This is a representation of the reply
/// sent from the Redis HELLO command.
/// See https://redis.io/commands/hello
abstract class RedisServerInfo {
  /// The Redis server name. Usually 'redis'.
  String get server;

  /// The Redis server version.
  String get version;

  /// The Redis server protocol version.
  /// e.g. '2' or '3'.
  int get protocol;

  /// The Redis client ID of this connection.
  int get id;

  /// The Redis mode of this connection.
  /// e,g, 'standalone', 'cluster', 'sentinel'.
  String get mode;

  /// The Redis role of this connection.
  /// e,g, 'master', 'slave'.
  String get role;

  /// The Redis modules loaded on this server.
  List<String> get modules;

  @override
  String toString() => 'RedisConnectionInfo(server: $server, version: $version, protocol: $protocol, id: $id, mode: $mode, role: $role, modules: $modules)';
}
