dart-msgpack
============

This is a very early release of my MessagePack library for Dart. Currently, message classes must be written by hand. For example:

```dart
class NotificationFrame extends Message {
    String kind;
    Map<String, Object> data;

    NotificationFrame(this.kind, this.data);

    static NotificationFrame fromList(List f) => new NotificationFrame(f[0], f[1]);
    List toList() => [kind, data];
}
```

For each class you need to define the `fromList` and `toList` methods, which convert from and to a list of fields respectively.

For example usage, see the unit tests.
