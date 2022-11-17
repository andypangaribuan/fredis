/*
 * Copyright (c) 2022.
 * Created by Andy Pangaribuan. All Rights Reserved.
 *
 * This product is protected by copyright and distributed under
 * licenses restricting copying, distribution and decompilation.
 */

part of redis;

abstract class _RespToken {
  static const int lineBreak = 13; // \r\n
  static const int bulk = 36; // $
  static const int string = 43; // +
  static const int array = 42; // *
  static const int error = 45; // -
  static const int integer = 58; // :
}
