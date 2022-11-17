/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

abstract class RedisClientImpl {
  late RedisConnectionState state;
  Future<RedisServerInfo> connect();
  Future<RedisReply<T>> send<T extends Object?>(String command, {List<Object?>? args});
}
