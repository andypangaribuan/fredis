/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

/// A representation of a Redis reply.
class RedisReply<T extends Object?> {
  RedisReply(
    this.value, {
    this.attributes,
  });

  /// The value of the reply.
  final T value;

  /// The attributes of the reply returned as additional information.
  /// This only applies to RESP 3.
  final Map<String, Object?>? attributes;

  @override
  String toString() => 'RedisReply: $value, attributes: $attributes';
}
