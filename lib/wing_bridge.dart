import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'wing_bindings.dart';

class WingDiscover {
    const WingDiscover({
        required this.ip,
        required this.name,
        required this.model,
        required this.serial,
        required this.firmware
    });

    final String ip;
    final String name;
    final String model;
    final String serial;
    final String firmware;

    static List<WingDiscover> scan({bool stopOnFirst = false}) {
        final ret = <WingDiscover>[];
        final d = _bindings.discoverScan(stopOnFirst ? 1 : 0);
        int i = 0;
        int n = _bindings.discoverCount(d);
        while (i < n) {
            ret.add(WingDiscover(
                        ip: _bindings.discoverGetIp(d, i).toDartString(),
                        name: _bindings.discoverGetName(d, i).toDartString(),
                        model: _bindings.discoverGetModel(d, i).toDartString(),
                        serial: _bindings.discoverGetSerial(d, i).toDartString(),
                        firmware: _bindings.discoverGetFirmware(d, i).toDartString() 
                        ));
            i++;
        }

        _bindings.discoverDestroy(d);
        return ret;
    }
}

class WingReadIsolate {
    final Pointer<NativeWingConsole> _console;
    final SendPort sendPort;

    WingReadIsolate(this._console, this.sendPort);
}

class IsolateMessageRequestEnd {
}
class IsolateMessageNodeDefinition {
    final NodeDefinition def;
    IsolateMessageNodeDefinition(this.def);
}
class IsolateMessageNodeData {
    final int id;
    final NodeData data;
    IsolateMessageNodeData(this.id, this.data);
}

void _task(WingReadIsolate iso) {
    final nativeCallableRequestEnd = NativeCallable<WingRequestEndCallback>.isolateLocal(
            (Pointer<Void> userData) {
                iso.sendPort.send(IsolateMessageRequestEnd());
            });
    _bindings.consoleSetRequestEndCallback(iso._console, nativeCallableRequestEnd.nativeFunction, nullptr);
    final nativeCallableNodeDefinition = NativeCallable<WingNodeDefinitionCallback>.isolateLocal(
            (Pointer<NativeNodeDefinition> def, Pointer<Void> userData) {
                iso.sendPort.send(IsolateMessageNodeDefinition(NodeDefinition(def)));
            });
    _bindings.consoleSetNodeDefinitionCallback(iso._console, nativeCallableNodeDefinition.nativeFunction, nullptr);
    final nativeCallableNodeData = NativeCallable<WingNodeDataCallback>.isolateLocal(
            (int id, Pointer<NativeNodeData> data, Pointer<Void> userData) {
                iso.sendPort.send(IsolateMessageNodeData(id, NodeData(data)));
            });
    _bindings.consoleSetNodeDataCallback(iso._console, nativeCallableNodeData.nativeFunction, nullptr);

    _bindings.consoleRead(iso._console);
}

const _libname = 'wing';
final DynamicLibrary _lib = switch (defaultTargetPlatform) {
    TargetPlatform.android => DynamicLibrary.open("lib$_libname.so"),
    TargetPlatform.linux => DynamicLibrary.open("lib$_libname.so"),
    TargetPlatform.macOS => DynamicLibrary.open("lib$_libname.dylib"),
    TargetPlatform.windows => DynamicLibrary.open("$_libname.dll"),
    _ => DynamicLibrary.executable(),
};

final WingBindings _bindings = WingBindings(_lib);

class NodeDefinition {
  static final Finalizer<NodeDefinition> _finalizer =
      Finalizer((n) => n._close());
    final Pointer<NativeNodeDefinition> _p;

    void _close() {
        _bindings.nodeDefDestroy(_p);
        _finalizer.detach(this);
    }

    NodeDefinition(this._p);

    NodeType get type => NodeType.values[_bindings.nodeDefGetType(_p)];
    NodeUnit get unit => NodeUnit.values[_bindings.nodeDefGetUnit(_p)];
    bool get isReadOnly => _bindings.nodeDefIsReadOnly(_p) != 0;
    int get parentId => _bindings.nodeDefGetParentId(_p);
    int get id => _bindings.nodeDefGetId(_p);
    int get index => _bindings.nodeDefGetIndex(_p);
    String get name {
        final int bufferSize = 1024; // Reasonable default size
        final Pointer<Utf8> buffer = malloc<Uint8>(bufferSize).cast<Utf8>();
        try {
            _bindings.nodeDefGetName(_p, buffer, bufferSize);
            return buffer.toDartString();
        } finally {
            malloc.free(buffer);
        }
    }
    String get longName {
        final int bufferSize = 1024; // Reasonable default size
        final Pointer<Utf8> buffer = malloc<Uint8>(bufferSize).cast<Utf8>();
        try {
            _bindings.nodeDefGetLongName(_p, buffer, bufferSize);
            return buffer.toDartString();
        } finally {
            malloc.free(buffer);
        }
    }
    double get minFloat => _bindings.nodeDefGetMinFloat(_p);
    double get maxFloat => _bindings.nodeDefGetMaxFloat(_p);
    int get steps => _bindings.nodeDefGetSteps(_p);
    int get minInt => _bindings.nodeDefGetMinInt(_p);
    int get maxInt => _bindings.nodeDefGetMaxInt(_p);
    int get maxStringLength => _bindings.nodeDefGetMaxStringLen(_p);
    int get stringEnumCount => _bindings.nodeDefGetStringEnumCount(_p);
    int get floatEnumCount => _bindings.nodeDefGetFloatEnumCount(_p);
    
    // XXX
    // Tuple<String, String> getStringEnumItem(int index) => _bindings.nodeDefGetStringEnumItem(_p, index);
    // Tuple<double, String> getFloatEnumItem(int index) => _bindings.nodeDefGetFloatEnumItem(_p, index);
}

class NodeData {
  static final Finalizer<NodeData> _finalizer =
      Finalizer((n) => n._close());

    final Pointer<NativeNodeData> _p;

    NodeData(this._p);

    void _close() {
        _bindings.nodeDataDestroy(_p);
        _finalizer.detach(this);
    }

    bool get hasString => _bindings.nodeDataHasString(_p) != 0;
    bool get hasFloat => _bindings.nodeDataHasFloat(_p) != 0;
    bool get hasInt => _bindings.nodeDataHasInt(_p) != 0;

    double get floatValue => _bindings.nodeDataGetFloat(_p);
    int    get intValue => _bindings.nodeDataGetInt(_p);
    String get stringValue {
        final int bufferSize = 1024; // Reasonable default size
        final Pointer<Utf8> buffer = malloc<Uint8>(bufferSize).cast<Utf8>();
        try {
            _bindings.nodeDataGetString(_p, buffer, bufferSize);
            return buffer.toDartString();
        } finally {
            malloc.free(buffer);
        }
    }
}

class WingConsole {
  final Pointer<NativeWingConsole> _console;

  void Function(NodeDefinition)? _cbNodeDefinition;
  void Function(int, NodeData)?  _cbNodeData;
  void Function()?               _cbRequestEnd;

  static void nodeInitMap(String name) {
        final nameNative = name.toNativeUtf8(allocator: malloc);
        try {
            if (_bindings.nodeInitMap(nameNative) != 0) {
                throw Exception("Failed to initialize node map");
            }
        } finally {
            malloc.free(nameNative);
        }
    }
  static int nodeNameToId(String name) {
        final nameNative = name.toNativeUtf8(allocator: malloc);
        try {
            return _bindings.nodeNameToId(nameNative);
        } finally {
            malloc.free(nameNative);
        }
    }
  static String nodeIdToName(int id) {
        final buffer = malloc<Uint8>(1024).cast<Utf8>();
        try {
            _bindings.nodeIdToName(id, buffer, 1024);
            return buffer.toDartString();
        } finally {
            malloc.free(buffer);
        }
    }

  static final Finalizer<WingConsole> _finalizer =
      Finalizer((console) => console._close());

  WingConsole._fromNative(this._console);

  factory WingConsole.connect(String ip) {
      final ipNative = ip.toNativeUtf8(allocator: malloc);
      try {
      var c = _bindings.consoleConnect(ipNative);
          return WingConsole._fromNative(c);
      } finally {
          malloc.free(ipNative);
      }
  }

  void _close() {
      _bindings.consoleDestroy(_console);
      _finalizer.detach(this);
  }

  void read() async {
      final receivePort = ReceivePort();
      receivePort.listen((message) {
        if (message is IsolateMessageRequestEnd) {
            _cbRequestEnd?.call();
        } else if (message is IsolateMessageNodeDefinition) {
            _cbNodeDefinition?.call(message.def);
        } else if (message is IsolateMessageNodeData) {
            _cbNodeData?.call(message.id, message.data);
        } else {
            throw UnimplementedError();
        }
      });
      await Isolate.spawn<WingReadIsolate>(_task, WingReadIsolate(_console, receivePort.sendPort));
  }

  void requestNodeData(int id) {
      _bindings.consoleRequestNodeData(_console, id);
  }

  void setString(int id, String value) {
      final valueNative = value.toNativeUtf8(allocator: malloc);
      try {
          _bindings.consoleSetString(_console, id, valueNative);
      } finally {
          malloc.free(valueNative);
      }
  }

  void setFloat(int id, double value) {
      _bindings.consoleSetFloat(_console, id, value);
  }

  void setInt(int id, int value) {
      _bindings.consoleSetInt(_console, id, value);
  }

  void setRequestEndCallback(void Function() callback) {
      _cbRequestEnd = callback;
  }

  void setNodeDefinitionCallback(void Function(NodeDefinition) callback) {
      _cbNodeDefinition = callback;
  }

  void setNodeDataCallback(void Function(int, NodeData) callback) {
      _cbNodeData = callback;
  }
}
