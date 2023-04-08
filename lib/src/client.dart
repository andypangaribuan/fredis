/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

library redis;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'abs/config.dart';
import 'abs/server_info.dart';

part 'config.dart';
part 'core.dart';
part 'func.dart';
part 'parser.dart';
part 'server_info.dart';
part 'var.dart';

part 'impl/client.dart';

part 'model/command_error.dart';
part 'model/connection_state_change.dart';
part 'model/queued_redis_command.dart';
part 'model/reply.dart';
part 'model/resp_token.dart';

class RedisClient {
  late final _RedisConfig _config;
  late final RedisClientImpl _client;

  RedisConnectionState get state => _client.state;

  RedisClient({
    String host = 'localhost',
    int port = 6379,
    int database = 0,
    Duration connectionTimeout = const Duration(seconds: 10),
    String? username,
    String? password,
    String? clientName,
    int protocol = 2,
    bool tls = false,
    List<SocketOption> socketOptions = const [],
  }) {
    _config = _RedisConfig(
      host: host,
      port: port,
      database: database,
      connectionTimeout: connectionTimeout,
      username: username,
      password: password,
      clientName: clientName,
      protocol: protocol,
      tls: tls,
      socketOptions: socketOptions,
    );

    _client = _RedisClient(_config);
  }

  Future<RedisServerInfo> connect() => _client.connect();

  Future<RedisReply<T>> send<T extends Object?>(String command, {List<Object?>? args}) => _client.send(command, args: args);

  RedisClient newClient() {
    return RedisClient(
      host: _config.host,
      port: _config.port,
      database: _config.database,
      connectionTimeout: _config.connectTimeout,
      username: _config.username,
      password: _config.password,
      clientName: _config.clientName,
      protocol: _config.protocol,
      tls: _config.tls,
      socketOptions: _config.socketOptions,
    );
  }
}
