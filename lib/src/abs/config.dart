/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

// cSpell:disable
import 'dart:io';

/// Base options class defining a Redis connection.
abstract class RedisConfig {
  String get host;
  int get port;
  int get database;
  Duration get connectTimeout;
  String? get username;
  String? get password;

  /// Optional name of this client to set when connecting to Redis
  /// via the `CLIENT SETNAME` Redis command.
  String? get clientName;

  /// The Redis protocol version to use.
  /// Defaults to `2` and currently only `2` is supported.
  /// See: https://redis.io/topics/protocol
  int get protocol;

  /// Whether to use TLS when connecting to the Redis server.
  /// Note that Redis itself does not support TLS natively, so this option is
  /// dependent on your server hosting provider and if they support TLS,
  /// e.g. `redis.com` or if you are hosting behind a TLS proxy yourself.
  bool get tls;

  /// Socket options to set as enabled when creating the socket connection
  /// to the Redis server.
  /// See [SocketOption] for more information.
  List<SocketOption> get socketOptions;

  RedisConfig copy({
    String? host,
    int? port,
    int? database,
    Duration? connectTimeout,
    String? password,
    String? username,
    String? clientName,
    int? protocol,
    bool? tls,
    List<SocketOption>? socketOptions,
  });
}
