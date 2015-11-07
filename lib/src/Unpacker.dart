part of msgpack;

dynamic unpack(buffer) {
  if (buffer is TypedData) {
    buffer = buffer.buffer;
  }

  if (buffer is List) {
    buffer = new Uint8List.fromList(buffer).buffer;
  }

  if (_unpacker == null) {
    _unpacker = new Unpacker(buffer);
  } else {
    _unpacker.reset(buffer);
  }

  return _unpacker.unpack();
}

Unpacker _unpacker;

unpackMessage(buffer, factory(List fields)) {
  if (buffer is TypedData) {
    buffer = buffer.buffer;
  }

  if (buffer is List) {
    buffer = new Uint8List.fromList(buffer).buffer;
  }

  if (_unpacker == null) {
    _unpacker = new Unpacker(buffer);
  } else {
    _unpacker.reset(buffer);
  }

  return _unpacker.unpackMessage(factory);
}

class Unpacker {
  ByteData data;
  int offset;

  Unpacker(ByteBuffer buffer, [this.offset = 0]) {
    data = new ByteData.view(buffer);
  }

  void reset(ByteBuffer buff) {
    data = new ByteData.view(buff);
    offset = 0;
  }

  unpack() {
    int type = data.getUint8(offset++);

    if (type >= 0xe0) return type - 0x100;
    if (type < 0xc0) {
      if (type < 0x80) return type;
      else if (type < 0x90) return unpackMap(() => type - 0x80);
      else if (type < 0xa0) return unpackList(() => type - 0x90);
      else return unpackString(() => type - 0xa0);
    }

    switch (type) {
      case 0xc0:
        return null;
      case 0xc2:
        return false;
      case 0xc3:
        return true;

      case 0xc4:
        return unpackBinary(type);
      case 0xc5:
        return unpackBinary(type);
      case 0xc6:
        return unpackBinary(type);

      case 0xcf:
        return unpackU64();
      case 0xce:
        return unpackU32();
      case 0xcd:
        return unpackU16();
      case 0xcc:
        return unpackU8();

      case 0xd3:
        return unpackS64();
      case 0xd2:
        return unpackS32();
      case 0xd1:
        return unpackS16();
      case 0xd0:
        return unpackS8();

      case 0xd9:
        return unpackString(unpackU8);
      case 0xda:
        return unpackString(unpackU16);
      case 0xdb:
        return unpackString(unpackU32);

      case 0xdf:
        return unpackMap(unpackU32);
      case 0xde:
        return unpackMap(unpackU16);
      case 0x80:
        return unpackMap(unpackU8);

      case 0xdd:
        return unpackList(unpackU32);
      case 0xdc:
        return unpackList(unpackU16);
      case 0x90:
        return unpackList(unpackU8);

      case 0xca:
        return unpackFloat32();
      case 0xcb:
        return unpackDouble();
    }
  }

  ByteData unpackBinary(int type) {
    int count;

    if (type == 0xc4) {
      count = data.getUint8(offset);
      offset += 1;
    } else if (type == 0xc5) {
      count = data.getUint16(offset);
      offset += 2;
    } else if (type == 0xc6) {
      count = data.getUint32(offset);
      offset += 4;
    } else {
      throw new Exception("Bad Binary Type");
    }

    var result = new ByteData(count);
    for (var i = 0; i < count; i++) {
      var idx = offset + i;
      result.setUint8(i, data.getUint8(idx));
    }
    offset += count;
    return result;
  }

  double unpackFloat32() {
    var value = data.getFloat32(offset);
    offset += 4;
    return value;
  }

  double unpackDouble() {
    var value = data.getFloat64(offset);
    offset += 8;
    return value;
  }

  unpackMessage(factory(List fields)) {
    List fields = unpack();
    return factory(fields);
  }

  int unpackU64() {
    int value = data.getUint64(offset);
    offset += 8;
    return value;
  }

  int unpackU32() {
    int value = data.getUint32(offset);
    offset += 4;
    return value;
  }

  int unpackU16() {
    int value = data.getUint16(offset);
    offset += 2;
    return value;
  }

  int unpackU8() {
    return data.getUint8(offset++);
  }

  int unpackS64() {
    int value = data.getInt64(offset);
    offset += 8;
    return value;
  }

  int unpackS32() {
    int value = data.getInt32(offset);
    offset += 4;
    return value;
  }

  int unpackS16() {
    int value = data.getInt16(offset);
    offset += 2;
    return value;
  }

  int unpackS8() {
    return data.getInt8(offset++);
  }

  String unpackString(int counter()) {
    var count = counter();
    String value = const Utf8Decoder().convert(new Uint8List.view(data.buffer, offset, count));
    offset += count;
    return value;
  }

  Map unpackMap(int counter()) {
    var count = counter();
    Map map = {};
    for (int i = 0; i < count; ++i) {
      map[unpack()] = unpack();
    }
    return map;
  }

  List unpackList(int counter()) {
    var count = counter();
    List list = [];
    for (int i = 0; i < count; ++i) {
      list.add(unpack());
    }
    return list;
  }
}