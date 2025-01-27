// ignore_for_file: avoid_print

import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import './wing_bindings.dart';

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

void _task(WingConsole model) {
    _bindings.consoleRead(model._console);

    print("flutter _task: done reading");
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

class WingConsole {
  final Pointer<NativeWingConsole> _console;

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
  print("flutter _close");

      _bindings.consoleDestroy(_console);
      _finalizer.detach(this);
  }

  void read() {
      Isolate.spawn<WingConsole>(_task, this);
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

  // Callback storage
  Pointer<NativeFunction<WingRequestEndCallback>>? _requestEndCallback;
  Pointer<NativeFunction<WingNodeDefinitionCallback>>? _nodeDefinitionCallback;
  Pointer<NativeFunction<WingNodeDataCallback>>? _nodeDataCallback;

  // Callback setters
  void setRequestEndCallback(void Function() callback) {
    // Convert Dart function to native callback
    _requestEndCallback = Pointer.fromFunction<WingRequestEndCallback>(
      (Pointer<Void> userData) {
        callback();
      },
    );
    
    _bindings.consoleSetRequestEndCallback(_console, _requestEndCallback!, nullptr);
  }

  void setNodeDefinitionCallback(void Function(Pointer<NativeNodeDefinition>) callback) {
    // Convert Dart function to native callback
    _nodeDefinitionCallback = Pointer.fromFunction<WingNodeDefinitionCallback>(
      (Pointer<NativeNodeDefinition> def, Pointer<Void> userData) {
        callback(def);
      },
    );
    
    _bindings.consoleSetNodeDefinitionCallback(_console, _nodeDefinitionCallback!, nullptr);
  }

  void setNodeDataCallback(void Function(int, Pointer<NativeNodeData>) callback) {
    // Convert Dart function to native callback
    _nodeDataCallback = Pointer.fromFunction<WingNodeDataCallback>(
      (int id, Pointer<NativeNodeData> data, Pointer<Void> userData) {
        callback(id, data);
      },
    );
    
    _bindings.consoleSetNodeDataCallback(_console, _nodeDataCallback!, nullptr);
  }
}
