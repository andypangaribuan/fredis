/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

class _RedisConfig extends RedisConfig {
  late final String _host;
  late final int _port;
  late final int _database;
  late final Duration _connectTimeout;
  late final String? _username;
  late final String? _password;
  late final String? _clientName;
  late final int _protocol;
  late final bool _tls;
  late final List<SocketOption> _socketOptions;

  @override
  String get host => _host;

  @override
  int get port => _port;

  @override
  int get database => _database;

  @override
  Duration get connectTimeout => _connectTimeout;

  @override
  String? get username => _username;
  @override
  String? get password => _password;

  @override
  String? get clientName => _clientName;

  @override
  int get protocol => _protocol;

  @override
  bool get tls => _tls;

  @override
  List<SocketOption> get socketOptions => _socketOptions;

  _RedisConfig({
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
    _host = host;
    _port = port;
    _database = database;
    _connectTimeout = connectionTimeout;
    _username = username;
    _password = password;
    _clientName = clientName;
    _protocol = protocol;
    _tls = tls;
    _socketOptions = socketOptions;
  }

  @override
  RedisConfig copy({
    String? host,
    int? port,
    int? database,
    Duration? connectTimeout,
    String? username,
    String? password,
    String? clientName,
    int? protocol,
    bool? tls,
    List<SocketOption>? socketOptions,
  }) {
    return _RedisConfig(
      host: host ?? _host,
      port: port ?? _port,
      database: database ?? _database,
      connectionTimeout: connectTimeout ?? _connectTimeout,
      username: username ?? _username,
      password: password ?? _password,
      protocol: protocol ?? _protocol,
      tls: tls ?? _tls,
      socketOptions: socketOptions ?? _socketOptions,
    );
  }
}
