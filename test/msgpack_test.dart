import 'dart:typed_data';
import 'package:unittest/unittest.dart';
import 'package:msgpack/msgpack.dart';

var isString = predicate((e) => e is String, 'is a String');
var isInt = predicate((e) => e is int, 'is an int');
var isMap = predicate((e) => e is Map, 'is a Map');
var isList = predicate((e) => e is List, 'is a List');

class TestMessage extends Message {
    int a;
    String b;
    Map<int, String> c;

    TestMessage(this.a, this.b, this.c);

    static TestMessage fromList(List f) => new TestMessage(f[0], f[1], f[2]);

    List toList() => [a, b, c];
}

class OuterMessage extends Message {
    String a;
    bool b;
    List<int> list;
    TestMessage inner;

    OuterMessage(this.a, this.b, this.list, this.inner);

    static OuterMessage fromList(List f) => new OuterMessage(f[0], f[1], f[2], TestMessage.fromList(f[3]));

    List toList() => [a, b, list, inner];
}

Packer packer;

int main() {
    setUp(() { packer = new Packer(); });
    tearDown(() { packer = null; });

    test("Pack 5-character string", packString5);
    test("Pack 22-character string", packString22);
    test("Pack 256-character string", packString256);
    test("Pack string array", packStringArray);
    test("Pack int-to-string map", packIntToStringMap);
    test("Pack 3-field message", packMessage);
    test("Pack nested message", packNestedMessage);

    test("Unpack 5-character string", unpackString5);
    test("Unpack 22-character string", unpackString22);
    test("Unpack 256-character string", unpackString256);
    test("Unpack string array", unpackStringArray);
    test("Unpack int-to-string map", unpackIntToStringMap);
    test("Unpack 3-field message", unpackMessage);
    test("Unpack nested message", unpackNestedMessage);
}

// Test packing

void packString5() {
    List<int> encoded = packer.pack("hello");
    expect(encoded, orderedEquals([165, 104, 101, 108, 108, 111]));
}

void packString22() {
    List<int> encoded = packer.pack("hello there, everyone!");
    expect(encoded, orderedEquals([182, 104, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 44, 32, 101, 118, 101, 114, 121, 111, 110, 101, 33]));
}

void packString256() {
    List<int> encoded = packer.pack("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
    expect(encoded, hasLength(259));
    expect(encoded.sublist(0, 3), orderedEquals([218, 1, 0]));
    expect(encoded.sublist(3, 259), everyElement(65));
}

void packStringArray() {
    List<int> encoded = packer.pack(["one", "two", "three"]);
    expect(encoded, orderedEquals([147, 163, 111, 110, 101, 163, 116, 119, 111, 165, 116, 104, 114, 101, 101]));
}

void packIntToStringMap() {
    List<int> encoded = packer.pack({1: "one", 2: "two"});
    expect(encoded, orderedEquals([130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111]));
}

void packMessage() {
    Message message = new TestMessage(1, "one", {2: "two"});
    List<int> encoded = packer.pack(message);
    expect(encoded, orderedEquals([147, 1, 163, 111, 110, 101, 129, 2, 163, 116, 119, 111]));
}

void packNestedMessage() {
    Message inner = new TestMessage(1, "one", {2: "two"});
    Message outer = new OuterMessage("three", true, [4, 5, 6], inner);
    List<int> encoded = packer.pack(outer);
    expect(encoded, orderedEquals([148, 165, 116, 104, 114, 101, 101, 195, 147, 4, 5, 6, 147, 1, 163, 111, 110, 101, 129, 2, 163, 116, 119, 111]));
}

// Test unpacking

void unpackString5() {
    Uint8List data = new Uint8List.fromList([165, 104, 101, 108, 108, 111]);
    Unpacker unpacker = new Unpacker(data.buffer);
    var value = unpacker.unpack();
    expect(value, isString);
    expect(value, equals("hello"));
}

void unpackString22() {
    Uint8List data = new Uint8List.fromList([182, 104, 101, 108, 108, 111, 32, 116, 104, 101, 114, 101, 44, 32, 101, 118, 101, 114, 121, 111, 110, 101, 33]);
    Unpacker unpacker = new Unpacker(data.buffer);
    var value = unpacker.unpack();
    expect(value, isString);
    expect(value, equals("hello there, everyone!"));
}

void unpackString256() {
    Uint8List data = new Uint8List.fromList([218, 1, 0]..addAll(new List.filled(256, 65)));
    Unpacker unpacker = new Unpacker(data.buffer);
    var value = unpacker.unpack();
    expect(value, isString);
    expect(value, equals("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"));
}

void unpackStringArray() {
    Uint8List data = new Uint8List.fromList([147, 163, 111, 110, 101, 163, 116, 119, 111, 165, 116, 104, 114, 101, 101]);
    Unpacker unpacker = new Unpacker(data.buffer);
    var value = unpacker.unpack();
    expect(value, isList);
    expect(value, orderedEquals(["one", "two", "three"]));
}

void unpackIntToStringMap() {
    Uint8List data = new Uint8List.fromList([130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111]);
    Unpacker unpacker = new Unpacker(data.buffer);
    var value = unpacker.unpack();
    expect(value, isMap);
    expect(value[1], equals("one"));
    expect(value[2], equals("two"));
}

void unpackMessage() {
    Uint8List data = new Uint8List.fromList([147, 1, 163, 111, 110, 101, 129, 2, 163, 116, 119, 111]);
    Unpacker unpacker = new Unpacker(data.buffer);
    var value = unpacker.unpackMessage(TestMessage.fromList);
    expect(value, predicate((x) => x is TestMessage));
    expect(value.a, equals(1));
    expect(value.b, equals("one"));
    expect(value.c[2], equals("two"));
}

void unpackNestedMessage() {
    Uint8List data = new Uint8List.fromList([148, 165, 116, 104, 114, 101, 101, 195, 147, 4, 5, 6, 147, 1, 163, 111, 110, 101, 129, 2, 163, 116, 119, 111]);
    Unpacker unpacker = new Unpacker(data.buffer);
    var value = unpacker.unpackMessage(OuterMessage.fromList);
    expect(value, predicate((x) => x is OuterMessage));
    expect(value.a, equals("three"));
    expect(value.b, equals(true));
    expect(value.list, orderedEquals([4, 5, 6]));
    expect(value.inner, predicate((x) => x is TestMessage));
    expect(value.inner.a, equals(1));
    expect(value.inner.b, equals("one"));
    expect(value.inner.c[2], equals("two"));
}
