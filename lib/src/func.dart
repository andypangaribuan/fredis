/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

String _cmdWritable(String command) {
  return '*1\r\n\$${command.length}\r\n$command\r\n';
}

String _cmdPartial(String command) {
  return '\r\n\$${command.length}\r\n$command\r\n';
}

String _argWritable(Object? arg) {
  return '\$${utf8.encode(arg.toString()).length}\r\n$arg\r\n';
}

/// Convert a Redis command and its arguments to a writable Redis RESP command string.
/// e.g. `toCommandWritable('set', ['key', 'value'])` outputs `*3\r\n\$3\r\nset\r\n\$3\r\nkey\r\n\$5\r\nvalue\r\n`
String _toCommandWritable(String command, List<Object?>? args) {
  if (args == null || args.isEmpty) return _cmdWritable(command);
  var i = 0;
  final l = args.length;
  final writable = StringBuffer();
  writable.write('*${l + 1}${_cmdPartial(command)}');
  for (; i < l; i++) {
    writable.write(_argWritable(args[i]));
  }
  return writable.toString();
}

/// Convert a Redis RESP command string to a list of arguments.
/// e.g. `*3\r\n\$3\r\nset\r\n\$3\r\nkey\r\n\$5\r\nvalue\r\n` -> `['set', 'key', 'value']`
///
/// Mainly useful for testing purposes or emulating Redis server behavior.
List<String> _fromCommandWritable(String redisProtocolString) {
  final result = <String>[];
  var partial = redisProtocolString.substring(redisProtocolString.indexOf('\r\n') + 2);
  while (partial.isNotEmpty) {
    final argStart = partial.indexOf('\r\n') + 2;
    final argLengthSlice = partial.substring(1 /* skip "$" */, argStart - 2);
    final argLength = int.parse(argLengthSlice);
    final argEnd = argStart + argLength;
    result.add(partial.substring(argStart, argStart + argLength));
    if (partial.isNotEmpty) {
      partial = partial.substring(argEnd + 2);
    }
  }
  return result;
}

/// Error message for commands that are not usable whilst the Redis client is
/// in the specified mode.
String _errorCommandNotSupportedInMode(String command, String mode) {
  return 'Command "$command" is not supported in $mode mode.';
}
