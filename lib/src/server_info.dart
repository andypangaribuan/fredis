/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

class _RedisServerInfo extends RedisServerInfo {
  late final String _server;
  late final String _version;
  late final int _protocol;
  late final int _id;
  late final String _mode;
  late final String _role;
  late final List<String> _modules;

  @override
  String get server => _server;

  @override
  String get version => _version;

  @override
  int get protocol => _protocol;

  @override
  int get id => _id;

  @override
  String get mode => _mode;

  @override
  String get role => _role;

  @override
  List<String> get modules => _modules;

  _RedisServerInfo({
    required String server,
    required String version,
    required int protocol,
    required int id,
    required String mode,
    required String role,
    required List<String> modules,
  }) {
    _server = server;
    _version = version;
    _protocol = protocol;
    _id = id;
    _mode = mode;
    _role = role;
    _modules = modules;
  }

  /// Return a [RedisConnectionInfo] from a RESP Array reply.
  /// e.g. a reply looking like the following is converted:
  /// `[server, redis, version, 6.2.6, proto, 2, id, 17, mode, standalone, role, master, modules, []]`
  factory _RedisServerInfo.fromReply(List<Object?> reply) {
    final info = <String, Object>{};
    for (var i = 0; i < reply.length; i += 2) {
      info[reply[i]! as String] = reply[i + 1]!;
    }

    return _RedisServerInfo(
      server: info['server']! as String,
      version: info['version']! as String,
      protocol: info['proto']! as int,
      id: info['id']! as int,
      mode: info['mode']! as String,
      role: info['role']! as String,
      modules: List<String>.from(info['modules']! as List),
    );
  }
}
