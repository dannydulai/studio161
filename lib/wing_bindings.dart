import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

// Enums
enum NodeType {
  node(0),
  linearFloat(1),
  logarithmicFloat(2),
  faderLevel(3),
  integer(4),
  stringEnum(5),
  floatEnum(6),
  string(7);

  final int value;
  const NodeType(this.value);
}

enum NodeUnit {
  none(0),
  db(1),
  percent(2),
  milliseconds(3),
  hertz(4),
  meters(5),
  seconds(6),
  octaves(7);

  final int value;
  const NodeUnit(this.value);
}

// Discovery Info struct
base class WingDiscoveryInfo extends ffi.Struct {
  @ffi.Array.multi([64])
  external ffi.Array<ffi.Int8> ip;

  @ffi.Array.multi([64])
  external ffi.Array<ffi.Int8> name;

  @ffi.Array.multi([64])
  external ffi.Array<ffi.Int8> model;

  @ffi.Array.multi([64])
  external ffi.Array<ffi.Int8> serial;

  @ffi.Array.multi([64])
  external ffi.Array<ffi.Int8> firmware;
}

// Opaque types
final class WingConsole extends ffi.Opaque {}
final class NodeData extends ffi.Opaque {}
final class NodeDefinition extends ffi.Opaque {}

// Callback typedefs
typedef WingRequestEndCallback = ffi.Void Function(
    ffi.Pointer<ffi.Void> userData);
typedef WingNodeDefinitionCallback = ffi.Void Function(
    ffi.Pointer<NodeDefinition> def, ffi.Pointer<ffi.Void> userData);
typedef WingNodeDataCallback = ffi.Void Function(
    ffi.Uint32 id, ffi.Pointer<NodeData> data, ffi.Pointer<ffi.Void> userData);

// Native function signatures
class WingBindings {
  final ffi.DynamicLibrary _lib;

  WingBindings(this._lib) {
    _initBindings();
  }

  late final int Function(ffi.Pointer<WingDiscoveryInfo> infoArray,
      ffi.Size maxCount, ffi.Int32 stopOnFirst) discover;
  
  late final ffi.Pointer<WingConsole> Function(ffi.Pointer<ffi.Int8> ip) connect;
  
  late final void Function(ffi.Pointer<WingConsole> console) destroy;
  
  late final void Function(ffi.Pointer<WingConsole> console) read;

  late final void Function(ffi.Pointer<WingConsole> console, ffi.Uint32 id,
      ffi.Pointer<ffi.Int8> value) setString;

  late final void Function(ffi.Pointer<WingConsole> console, ffi.Uint32 id,
      double value) setFloat;

  late final void Function(ffi.Pointer<WingConsole> console, ffi.Uint32 id,
      ffi.Int32 value) setInt;

  void _initBindings() {
    discover = _lib.lookupFunction<
        ffi.Int32 Function(ffi.Pointer<WingDiscoveryInfo>, ffi.Size,
            ffi.Int32),
        int Function(ffi.Pointer<WingDiscoveryInfo>, ffi.Size,
            ffi.Int32)>('wing_console_discover');

    connect = _lib.lookupFunction<
        ffi.Pointer<WingConsole> Function(ffi.Pointer<ffi.Int8>),
        ffi.Pointer<WingConsole> Function(
            ffi.Pointer<ffi.Int8>)>('wing_console_connect');

    destroy = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<WingConsole>),
        void Function(ffi.Pointer<WingConsole>)>('wing_console_destroy');

    read = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<WingConsole>),
        void Function(ffi.Pointer<WingConsole>)>('wing_console_read');

    setString = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<WingConsole>, ffi.Uint32,
            ffi.Pointer<ffi.Int8>),
        void Function(ffi.Pointer<WingConsole>, ffi.Uint32,
            ffi.Pointer<ffi.Int8>)>('wing_console_set_string');

    setFloat = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<WingConsole>, ffi.Uint32, ffi.Float),
        void Function(
            ffi.Pointer<WingConsole>, ffi.Uint32, double)>('wing_console_set_float');

    setInt = _lib.lookupFunction<
        ffi.Void Function(ffi.Pointer<WingConsole>, ffi.Uint32, ffi.Int32),
        void Function(
            ffi.Pointer<WingConsole>, ffi.Uint32, ffi.Int32)>('wing_console_set_int');
  }
}
