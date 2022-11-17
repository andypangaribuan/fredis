/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

// cSpell:disable
part of redis;

class _RedisClient extends StreamView<RedisConnectionStateChange> implements RedisClientImpl {
  _RedisClient(RedisConfig config)
      : this._(
          config,
          StreamController<RedisConnectionStateChange>.broadcast(sync: true),
        );

  _RedisClient._(this.config, this._controller) : super(_controller.stream);

  /// The underlying options for the Redis connector.
  final RedisConfig config;

  /// The current connection state of this connector.
  /// [RedisConnectionState.closed] is the initial state before any
  /// connection is attempted.
  @override
  RedisConnectionState state = RedisConnectionState.closed;

  /// Redis Pub/Sub channels this connection is currently subscribed to.
  /// If not empty then this connection is in a Pub/Sub mode.
  /// If empty then this connection is not in a Pub/Sub mode.
  final List<String> subscriptions = <String>[];

  /// Parser for the Redis protocol to use on this connection only.
  _RedisParser? parser;

  /// Underlying socket connection to the Redis server.
  Socket? socket;

  // Internal controller to handle connection state changes for the [RedisClient]
  // [StreamView].
  final StreamController<RedisConnectionStateChange> _controller;

  // Current socket subscription to the Redis server, if any.
  StreamSubscription? _socketSubscription;

  // Current parser stream subscription, if any.
  StreamSubscription? _parserSubscription;

  /// Commands that have been sent to the Redis server but have
  /// not yet been responded to.
  //
  /// Commands sent to Redis are responded to in the order they are
  /// sent so we queue them up here and remove the last item in the
  /// queue when a response is received.
  final DoubleLinkedQueue<QueuedRedisCommand> commandQueue = DoubleLinkedQueue<QueuedRedisCommand>();

  /// Sets the current connection state and emits a state change.
  /// You probably shouldn't call this directly unless your
  /// Redis Client needs to change state explicitly itself.
  void setConnectionState(RedisConnectionState state) {
    if (state == this.state) {
      return;
    }
    final previousState = this.state;
    this.state = state;
    _controller.add(
      RedisConnectionStateChange(
        currentState: state,
        previousState: previousState,
      ),
    );
  }

  /// Handles a Redis command success/ok response returned from the parser.
  /// Custom connectors can override this method to handle responses themselves
  /// and add the [skip] parameter to skip default response handling logic when calling
  /// super.[handleRedisOkReponse] - otherwise default response handling logic will
  /// apply when calling super.[handleRedisOkReponse].
  // @mustCallSuper
  void handleRedisOkReponse(
    Object? response, {
    bool skip = false,
  }) {
    if (skip) {
      // Override method implementations that call super can optionally skip
      // default response handling logic in this function.
      return;
    }

    if (subscriptions.isNotEmpty) {
      // Client is in Pub/Sub mode. We don't care about the response here.
      return;
    }

    if (commandQueue.isEmpty) {
      throw StateError(
        'Received a RESP response but no queued commands found.',
      );
    }

    final command = commandQueue.removeLast();
    command.completer.complete(response);
  }

  /// Handles a Redis command error response returned from the parser.
  /// Custom connectors can override this method to handle errors themselves
  /// and add the [skip] parameter to skip default error handling logic when calling
  /// super.[handleRedisErrorReponse] - otherwise default error handling logic will
  /// apply when calling super.[handleRedisErrorReponse].
  // @mustCallSuper
  void handleRedisErrorReponse(
    String response, {
    bool skip = false,
  }) {
    if (skip) {
      // Override method implementations that call super can optionally skip
      // default response handling logic in this function.
      return;
    }

    if (commandQueue.isEmpty) {
      throw StateError(
        'Received a RESP response but no queued commands found.',
      );
    }

    final queuedCommand = commandQueue.removeLast();
    queuedCommand.completer.completeError(
      RedisCommandError(
        response,
        command: queuedCommand.command,
        args: queuedCommand.args,
        stackTrace: queuedCommand.stacktrace,
      ),
    );
  }

  /// Connects to the Redis server.
  /// Returns an [Future] that completes when the connection is established.
  /// If the connection fails, the [Future] completes with an error.
  @override
  Future<RedisServerInfo> connect() async {
    if (state == RedisConnectionState.connecting) {
      throw StateError(
        'Cannot call connect when already attempting to connect to the Redis server.',
      );
    }
    if (state == RedisConnectionState.ready) {
      throw StateError(
        'Cannot call connect when already connected to the Redis server.',
      );
    }

    setConnectionState(RedisConnectionState.connecting);

    // TODO Parser only supports RESP 2 for now.
    parser = _RedisParser();

    try {
      socket = await Socket.connect(
        config.host,
        config.port,
        timeout: config.connectTimeout,
      );
      for (final option in config.socketOptions) {
        socket!.setOption(option, true);
      }
    } on SocketException catch (error, stackTrace) {
      // TODO should we handle a SocketException relating to a timeout
      // differently?
      await closeWithError(error, stackTrace);
      rethrow;
    }

    _socketSubscription = socket!.listen(
      parser!.add,
      onError: closeWithError,
    );
    _parserSubscription = parser!.listen(
      handleRedisOkReponse,
      onError: (Object error) => handleRedisErrorReponse(error as String),
      cancelOnError: false,
    );

    if (config.protocol != 2) {
      // TODO RESP 2 protocol only supported for now.
      throw UnsupportedError('Only RESP 2 protocol is currently supported.');
    }

    // Call HELLO command to setup protocol version, authentication and
    // client name, if specified.
    final redisConnectionInfo = await _send<List<Object?>>(
      'HELLO',
      args: [
        config.protocol,
        // AUTH <username?> <password?>
        if (config.username != null || config.password != null) 'AUTH',
        if (config.username != null)
          config.username
        // In order to just use a general password like in Redis 5,
        // clients should use "default" as username (all lower case).
        else if (config.password != null)
          'default',
        if (config.password != null) config.password,
        // SETNAME <name?>
        if (config.clientName != null) ...[
          'SETNAME',
          config.clientName,
        ]
      ],
    );

    if (config.database != 0) {
      await _send('SELECT', args: [config.database]);
    }

    setConnectionState(RedisConnectionState.ready);

    return _RedisServerInfo.fromReply(redisConnectionInfo.value);
  }

  /// Gracefully closes the connection to the Redis server.
  // @mustCallSuper
  Future<void> close() async {
    if (state != RedisConnectionState.ready && state != RedisConnectionState.connecting) {
      throw StateError(
        'Cannot call close on a connection that is not ready or connecting.',
      );
    }
    setConnectionState(RedisConnectionState.closing);
    await _parserSubscription?.cancel();
    await _socketSubscription?.cancel();
    await parser?.close();
    await socket?.close();
    commandQueue.clear();
    parser = null;
    socket = null;
    setConnectionState(RedisConnectionState.closed);
  }

  /// Closes the connection with an error.
  // @mustCallSuper
  Future<void> closeWithError(
    Object? possibleError, [
    StackTrace? stackTrace,
  ]) async {
    _controller.addError(possibleError!);
    await close();
    setConnectionState(RedisConnectionState.error);
  }

  // Internal send function, to bypass ready check requirements since
  // we need to be able to send commands to verify connection and
  // authenticate the client.
  Future<RedisReply<T>> _send<T extends Object?>(
    String command, {
    List<Object?>? args,
  }) async {
    final commandString = const Utf8Encoder().convert(_toCommandWritable(command, args));
    final completer = Completer<Object?>();
    socket!.add(commandString);
    commandQueue.add(
      QueuedRedisCommand(
        completer: completer,
        command: command,
        args: args,
        stacktrace: StackTrace.current,
      ),
    );
    final response = await completer.future;
    return RedisReply<T>(response as T);
  }

  @override
  Future<RedisReply<T>> send<T extends Object?>(String command, {List<Object?>? args}) {
    var cmd = command.trim();
    while (cmd.contains('  ')) {
      cmd = cmd.replaceAll('  ', ' ');
    }

    final ls = cmd.split(' ');

    cmd = ls[0];
    final pars = <Object?>[];
    for (int i = 1; i < ls.length; i++) {
      pars.add(ls[i]);
    }

    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        pars.add(args[i]);
      }
    }

    return sendWithArgs(cmd, args: pars);
  }

  /// Sends a command to the Redis server and returns a [Future] that
  /// completes with the response.
  // @mustCallSuper
  Future<RedisReply<T>> sendWithArgs<T extends Object?>(
    String command, {
    List<Object?>? args,
  }) async {
    if (state != RedisConnectionState.ready) {
      throw StateError(
        'Cannot send command to Redis server because connection is not ready.',
      );
    }
    // RESP protocol v3 supports out-of-band messages (push data) so we
    // can send commands to the server - even with subscriptions.
    if (config.protocol == 2 && subscriptions.isNotEmpty && subscriberModeAvailableCommands.contains(command.toLowerCase())) {
      throw StateError(_errorCommandNotSupportedInMode(command, 'subscriber'));
    }
    return _send<T>(command, args: args);
  }

  /// Stream Redis SCAN values, e.g. Redis keys via the SCAN command.
  /// See https://redis.io/commands/scan for more information.
  ///
  /// [scanCommand] is the SCAN command to use, valid values are:
  /// SCAN, SSCAN, HSCAN, ZSCAN
  /// [count] is the number of values to return per iteration, this is only reflected
  /// internally and is useful for tweaking the performance of the scan.
  /// [match] is the optional pattern to match against.
  /// [type] is the optional type of value to return, examples are:
  /// 'string', 'hash', 'set', 'zset'. The [type] option is only available on
  /// the whole-database, e.g. SCAN, not HSCAN or ZSCAN etc.
  Stream<String> scan(
    String scanCommand, {
    int? count,
    String? type,
    String? match,
  }) async* {
    final args = <Object?>[
      if (match != null) ...[
        'MATCH',
        match,
      ],
      // The TYPE option is only available on the whole-database SCAN,
      // not HSCAN or ZSCAN etc.
      if (type != null && scanCommand.toLowerCase() == 'scan') ...[
        'TYPE',
        type,
      ],
      if (count != null) ...[
        'COUNT',
        count,
      ],
    ];
    var nextCursor = 0;
    while (true) {
      final reply = await sendWithArgs<List<Object?>>(scanCommand, args: [nextCursor, ...args]);
      nextCursor = int.parse(reply.value[0]! as String);
      final values = List<String>.from((reply.value)[1]! as List);
      for (final value in values) {
        yield value;
      }
      if (nextCursor == 0) {
        break;
      }
    }
  }

  /// Receive a [Stream] of Redis Pub/Sub messages.
  /// See https://redis.io/topics/pubsub for more information on commands
  Stream<List<Object?>> subscribeToMessages({
    required String channelOrPattern,
    required String subscribeCommand,
    required String unsubscribeCommand,
  }) {
    // TODO: Remi-ify this function.

    StreamSubscription? parserSubscription;
    StreamSubscription? redisSubscription;
    StreamController<List<Object?>>? controller;

    Future<void> tryUnsubscribe() async {
      await redisSubscription?.cancel();
      await parserSubscription?.cancel();
      await controller?.close();
      try {
        await sendWithArgs(unsubscribeCommand, args: [channelOrPattern]);
      } catch (_) {
        // Ignore errors when unsubscribing, since client state may be
        // invalid, e.g. disconnected.
      }
      subscriptions.remove(channelOrPattern);
      redisSubscription = null;
      parserSubscription = null;
      controller = null;
    }

    final connector = this;
    controller = StreamController<List<Object?>>.broadcast(
      sync: true,
      onListen: () async {
        // Tell Redis to subscribe this client connection.
        await sendWithArgs(subscribeCommand, args: [channelOrPattern]);

        // Forward all future messages from Redis to the stream.
        parserSubscription = parser!.map((event) => event! as List<Object?>).listen(controller?.add);

        // Listen for connection state changes and unsubscribe if the
        // connection is closed.
        redisSubscription = connector.listen((event) async {
          if (event.currentState == RedisConnectionState.closed || event.currentState == RedisConnectionState.closing || event.currentState == RedisConnectionState.error) {
            // TODO should we controller.addError here if state is error?
            await tryUnsubscribe();
          }
        });

        // Locally track subscriptions.
        subscriptions.add(channelOrPattern);
      },
      onCancel: tryUnsubscribe,
    );

    return controller!.stream;
  }
}
