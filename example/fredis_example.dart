/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

// cSpell:disable
import 'package:fredis/fredis.dart';

void main() async {
  try {
    final redis = RedisClient(
      host: '127.0.0.1',
      port: 6379,
      password: 'password',
      clientName: 'fredis',
    );
    await redis.connect();

    await redis.send('ZADD myzset 1 "one"');
  } catch (err, stackTrace) {
    print(err);
    print(stackTrace);
  }
}
