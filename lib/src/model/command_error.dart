/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

/// A representation of a Redis error when a command fails, e.g. when the
/// args are invalid or the node is not ready.
class RedisCommandError implements Error {
  RedisCommandError(
    this.message, {
    required this.command,
    this.args = const <String>[],
    required this.stackTrace,
  });

  /// The command that caused the error.
  final String command;

  /// The arguments passed to the command.
  final List<Object?>? args;

  /// The error message returned by Redis.
  final String message;

  @override
  final StackTrace stackTrace;

  @override
  String toString() => 'RedisCommandError: ${message.replaceFirst('ERR ', '')}\n  COMMAND: "$command"\n  ARGS: $args';
}
