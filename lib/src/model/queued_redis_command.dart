/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

/// A command that has been queued for execution on the Redis connector instance.
class QueuedRedisCommand {
  QueuedRedisCommand({
    required this.completer,
    required this.command,
    required this.stacktrace,
    this.args,
  });

  /// The completer that will be completed when the command has been executed.
  final Completer<Object?> completer;

  /// The command that is being executed.
  final String command;

  /// The arguments that are being passed to the command.
  final List<Object?>? args;

  /// The originating stacktrace of the command that is being executed.
  /// This helps provide better stack locations to end users that are sending
  /// commands, since the stacktrace provides the location.
  final StackTrace stacktrace;
}
