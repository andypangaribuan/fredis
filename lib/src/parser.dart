/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

const _noResponse = Symbol('noResponse');

class _RedisParser extends StreamView<Object?> implements Sink<Uint8List> {
  _RedisParser() : this._(StreamController<Object?>.broadcast(sync: true));

  _RedisParser._(this._controller) : super(_controller.stream);

  int _offset = 0;
  int _bigStringSize = 0;
  int _totalChunkSize = 0;
  Uint8List? _currentBuffer;
  List<Uint8List> _bufferResponseCache = [];

  final List<Object> _arrayResponseItemCache = [];
  final List<int> _arrayResponsePosCache = [];
  final StreamController<Object?> _controller;

  @override
  void add(Uint8List input) {
    if (_currentBuffer == null) {
      _currentBuffer = input;
      _offset = 0;
    } else if (_bigStringSize == 0) {
      _currentBuffer!.addAll(input);
      _offset = 0;
      if (_arrayResponseItemCache.isNotEmpty) {
        final array = _parseArrayChunks();
        if (array == _noResponse) {
          return;
        }
        _controller.add(array);
      }
    } else if (_totalChunkSize + input.length >= _bigStringSize) {
      _bufferResponseCache.add(input);
      var tempBuffer = _concatBulkString();
      _bigStringSize = 0;
      _bufferResponseCache = [];
      _currentBuffer = input;
      if (_arrayResponseItemCache.isNotEmpty) {
        (_arrayResponseItemCache[0] as List)[_arrayResponsePosCache[0]++] = tempBuffer;
        tempBuffer = _parseArrayChunks();
        if (tempBuffer == _noResponse) {
          return;
        }
      }
      _controller.add(tempBuffer);
    } else {
      _bufferResponseCache.add(input);
      _totalChunkSize += input.length;
      return;
    }

    while (_offset < _currentBuffer!.length) {
      final currentOffset = _offset;
      final type = _currentBuffer![_offset++];
      final response = _parseType(type);
      if (response == _noResponse) {
        if (_arrayResponseItemCache.isEmpty && _bufferResponseCache.isEmpty) {
          _offset = currentOffset;
        }
        return;
      }

      if (type == _RespToken.error) {
        // TODO nicer redis errors, atm these are just strings.
        _controller.addError(response!);
      } else {
        _controller.add(response);
      }
    }

    _currentBuffer = null;
  }

  @override
  Future<void> close() {
    return _controller.close();
  }

  Object? _concatBulkString() {
    final list = _bufferResponseCache;
    final oldOffset = _offset;
    var chunks = list.length;
    var offset = _bigStringSize - _totalChunkSize;
    _offset = offset;
    if (offset <= 2) {
      if (chunks == 2) {
        return utf8.decode(list[0].sublist(oldOffset, list[0].length + offset - 2));
      }
      chunks--;
      offset = list[list.length - 2].length + offset;
    }

    final stringBuffer = StringBuffer();
    stringBuffer.write(utf8.decode((list[0]).sublist(oldOffset)));
    int i;
    for (i = 1; i < chunks - 1; i++) {
      stringBuffer.write(utf8.decode(list[i]));
    }
    stringBuffer.write(utf8.decode(list[i].sublist(0, offset - 2)));
    return stringBuffer.toString();
  }

  Object? _parseArrayChunks() {
    final array = _arrayResponseItemCache.removeLast() as List;
    var position = _arrayResponsePosCache.removeLast();
    if (_arrayResponseItemCache.isNotEmpty) {
      final response = _parseArrayChunks();
      if (response == _noResponse) {
        _pushArrayCache(array, position);
        return response;
      }
      array[position++] = response;
    }
    return _parseArrayElements(array, position);
  }

  num _parseLength() {
    final length = _currentBuffer!.length - 1;
    var currentOffset = _offset;
    num number = 0;
    while (currentOffset < length) {
      final c1 = _currentBuffer![currentOffset++];
      if (c1 == _RespToken.lineBreak) {
        _offset = currentOffset + 1;
        return number;
      }
      number = (number * 10) + (c1 - 48);
    }

    throw StateError('Invalid Redis array/buffer length.');
  }

  Object? _parseType(int type) {
    switch (type) {
      case _RespToken.bulk:
        return _parseBulkString();
      case _RespToken.string:
        return _parseString();
      case _RespToken.array:
        return _parseArray();
      case _RespToken.integer:
        return _parseNum();
      case _RespToken.error:
        return _parseString();
    }
    throw StateError(
      'Redis data type of "${String.fromCharCode(type)}" is currently not supported.',
    );
  }

  Object? _parseBulkString() {
    final length = _parseLength();
    if (length < 0) {
      return null;
    }
    final currentOffset = _offset + length.toInt();
    if (currentOffset + 2 > _currentBuffer!.length) {
      _bigStringSize = currentOffset + 2;
      _totalChunkSize = _currentBuffer!.length;
      _bufferResponseCache.add(_currentBuffer!);
      return _noResponse;
    }
    final start = _offset;
    _offset = currentOffset + 2;
    return utf8.decode(_currentBuffer!.sublist(start, currentOffset));
  }

  Object? _parseArray() {
    final length = _parseLength();
    if (length < 0) {
      return null;
    }
    final responses = List<Object?>.filled(length.toInt(), null);
    return _parseArrayElements(responses, 0);
  }

  void _pushArrayCache(Object array, int position) {
    _arrayResponseItemCache.add(array);
    _arrayResponsePosCache.add(position);
  }

  Object? _parseArrayElements(List<Object?> responses, int index) {
    var _index = index;
    final length = _currentBuffer!.length;

    while (_index < responses.length) {
      final currentOffset = _offset;
      if (_offset >= length) {
        _pushArrayCache(responses, _index);
        return _noResponse;
      }
      final response = _parseType(_currentBuffer![_offset++]);
      if (response == _noResponse) {
        if (!(_arrayResponseItemCache.isNotEmpty || _bufferResponseCache.isNotEmpty)) {
          _offset = currentOffset;
        }
        _pushArrayCache(responses, _index);
        return _noResponse;
      }
      responses[_index] = response;
      _index++;
    }
    return responses;
  }

  num _parseNum() {
    final length = _currentBuffer!.length - 1;
    var currentOffset = _offset;
    var number = 0;
    var sign = 1;

    if (_currentBuffer![currentOffset] == 45) {
      sign = -1;
      _offset++;
    }

    while (currentOffset < length) {
      final c1 = _currentBuffer![currentOffset++];
      if (c1 == _RespToken.lineBreak) {
        _offset = currentOffset + 1;
        return sign * number;
      }
      number = (number * 10) + (c1 - 48);
    }
    throw StateError('Invalid Redis number response.');
  }

  String _parseString() {
    final start = _offset;
    final length = _currentBuffer!.length - 1;
    var currentOffset = start;

    while (currentOffset < length) {
      if (_currentBuffer![currentOffset++] == _RespToken.lineBreak) {
        _offset = currentOffset + 1;
        return utf8.decode(_currentBuffer!.sublist(start, currentOffset - 1));
      }
    }

    throw StateError('Invalid Redis string response.');
  }
}
