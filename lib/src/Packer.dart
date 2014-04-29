part of msgpack;

List<int> pack(value) => new Packer().pack(value);

class Packer {
    List<int> pack(value) {
        if (value == null) return [0xc0];
        else if (value == false) return [0xc2];
        else if (value == true) return [0xc3];
        else if (value is int) return packInt(value);
        else if (value is String) return packString(value);
        else if (value is List) return packList(value);
        else if (value is Map) return packMap(value);
        else if (value is Message) return packMessage(value);
    }

    List<int> packAll(values) {
        List<int> encoded = [];
        for (var value in values) encoded.addAll(pack(value));
        return encoded;
    }

    List<int> packInt(int value) {
        List<int> encoded = [];
        if (value < 0) {
            if (value >= -32) encoded.add(0xe0 + value + 32);
            else if (value > -0x80) encoded.addAll([0xd0, value + 0x100]);
            else if (value > -0x8000) encoded..add(0xd1)..addAll(_encodeUInt16(value + 0x10000));
            else if (value > -0x80000000) encoded..add(0xd2)..addAll(_encodeUInt32(value + 0x100000000));
            else encoded..add(0xd3)..addAll(_encodeUInt64(value));
        } else {
            if (value < 0x80) encoded.add(value);
            else if (value < 0x100) encoded.addAll([0xcc, value]);
            else if (value < 0x10000) encoded..addAll(0xcd)..addAll(_encodeUInt16(value));
            else if (value < 0x100000000) encoded..add(0xce)..addAll(_encodeUInt32(value));
            else encoded..add(0xcf)..addAll(_encodeUInt64(value));
        }
        return encoded;
    }

    List<int> _encodeUInt16(int value) {
        return [(value >> 8) & 0xff, value & 0xff];
    }

    List<int> _encodeUInt32(int value) {
        return [(value >> 24) & 0xff, (value >> 16) & 0xff, (value >>  8) & 0xff, value & 0xff];
    }

    List<int> _encodeUInt64(int value) {
        return [
            (value >> 56) & 0xff, (value >> 48) & 0xff, (value >> 40) & 0xff, (value >> 32) & 0xff,
            (value >> 24) & 0xff, (value >> 16) & 0xff, (value >> 8) & 0xff, value & 0xff
        ];
    }

    List<int> packString(String value) {
        List<int> encoded = [];
        List<int> utf8 = UTF8.encode(value);
        if (utf8.length < 0x20) encoded.add(0xa0 + utf8.length);
        else if (utf8.length < 0x100) encoded.addAll([0xd9, utf8.length]);
        else if (utf8.length < 0x10000) encoded..add(0xda)..addAll(_encodeUInt16(utf8.length));
        else encoded..add(0xdb)..addAll(_encodeUInt32(utf8.length));
        encoded.addAll(utf8);
        return encoded;
    }

    List<int> packList(List value) {
        List<int> encoded = [];
        if (value.length < 16) encoded.add(0x90 + value.length);
        else if (value.length < 0x100) encoded..add(0xdc)..addAll(_encodeUInt16(value.length));
        else encoded..add(0xdd)..addAll(_encodeUInt32(value.length));
        for (var element in value) {
            encoded.addAll(pack(element));
        }
        return encoded;
    }

    List<int> packMap(Map value) {
        List<int> encoded = [];
        if (value.length < 16) encoded.add(0x80 + value.length);
        else if (value.length < 0x100) encoded..add(0xde)..addAll(_encodeUInt16(value.length));
        else encoded..add(0xdf)..addAll(_encodeUInt32(value.length));
        for (var element in value.keys) {
            encoded.addAll(pack(element));
            encoded.addAll(pack(value[element]));
        }
        return encoded;
    }

    List<int> packMessage(Message value) {
        return packList(value.toList());
    }
}
