import 'dart:ffi';
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
        final d = ffiBindings.discoverScan(stopOnFirst ? 1 : 0);
        int i = 0;
        int n = ffiBindings.discoverCount(d);
        while (i < n) {
            final ip = ffiBindings.discoverGetIp(d, i);
            final name = ffiBindings.discoverGetName(d, i);
            final model = ffiBindings.discoverGetModel(d, i);
            final serial = ffiBindings.discoverGetSerial(d, i);
            final firmware = ffiBindings.discoverGetFirmware(d, i);
            ret.add(WingDiscover(
                        ip: ip.toDartString(),
                        name: name.toDartString(),
                        model: model.toDartString(),
                        serial: serial.toDartString(),
                        firmware: firmware.toDartString(),
                        ));
            ffiBindings.stringDestroy(ip);
            ffiBindings.stringDestroy(name);
            ffiBindings.stringDestroy(model);
            ffiBindings.stringDestroy(serial);
            ffiBindings.stringDestroy(firmware);
            i++;
        }

        ffiBindings.discoverDestroy(d);
        return ret;
    }
}

const _libname = 'libwing';
final DynamicLibrary _lib = switch (defaultTargetPlatform) {
    TargetPlatform.android => DynamicLibrary.open("lib$_libname.so"),
    TargetPlatform.linux => DynamicLibrary.open("lib$_libname.so"),
    TargetPlatform.macOS => DynamicLibrary.open("lib$_libname.dylib"),
    TargetPlatform.windows => DynamicLibrary.open("$_libname.dll"),
    _ => DynamicLibrary.executable(),
};

final WingBindings ffiBindings = WingBindings(_lib);

class Response {
  static final Finalizer<Response> _finalizer =
      Finalizer((response) => response._close());

  void _close() {
      ffiBindings.responseDestroy(_response);
      _finalizer.detach(this);
  }

  Response.fromNative(this._response);

  final Pointer<NativeResponse> _response;

    ResponseType get type => ResponseType.values[ffiBindings.responseGetType(_response)];
    bool get dataHasString => ffiBindings.nodeDataHasString(_response) != 0;
    bool get dataHasFloat => ffiBindings.nodeDataHasFloat(_response) != 0;
    bool get dataHasInt => ffiBindings.nodeDataHasInt(_response) != 0;

    int    get dataId => ffiBindings.nodeDataGetId(_response);
    double get dataFloatValue => ffiBindings.nodeDataGetFloat(_response);
    int    get dataIntValue => ffiBindings.nodeDataGetInt(_response);
    String get dataStringValue {
        final str = ffiBindings.nodeDataGetString(_response);
        try {
            return str.toDartString();
        } finally {
            ffiBindings.stringDestroy(str);
        }
    }

    NodeType get defType => NodeType.values[ffiBindings.nodeDefGetType(_response)];
    NodeUnit get defUnit => NodeUnit.values[ffiBindings.nodeDefGetUnit(_response)];
    bool get defIsReadOnly => ffiBindings.nodeDefIsReadOnly(_response) != 0;
    int get defParentId => ffiBindings.nodeDefGetParentId(_response);
    int get defId => ffiBindings.nodeDefGetId(_response);
    int get defIndex => ffiBindings.nodeDefGetIndex(_response);
    String get defName {
        final str = ffiBindings.nodeDefGetName(_response);
        try {
            return str.toDartString();
        } finally {
            ffiBindings.stringDestroy(str);
        }
    }
    String get defLongName {
        final str = ffiBindings.nodeDefGetLongName(_response);
        try {
            return str.toDartString();
        } finally {
            ffiBindings.stringDestroy(str);
        }
    }
    double get defMinFloat => ffiBindings.nodeDefGetMinFloat(_response);
    double get defMaxFloat => ffiBindings.nodeDefGetMaxFloat(_response);
    int get defSteps => ffiBindings.nodeDefGetSteps(_response);
    int get defMinInt => ffiBindings.nodeDefGetMinInt(_response);
    int get defMaxInt => ffiBindings.nodeDefGetMaxInt(_response);
    int get defMaxStringLength => ffiBindings.nodeDefGetMaxStringLen(_response);
    int get defStringEnumCount => ffiBindings.nodeDefGetStringEnumCount(_response);
    int get defFloatEnumCount => ffiBindings.nodeDefGetFloatEnumCount(_response);
    
    // XXX
    // Tuple<String, String> getStringEnumItem(int index) => _bindings.nodeDefGetStringEnumItem(_response, index);
    // Tuple<double, String> getFloatEnumItem(int index) => _bindings.nodeDefGetFloatEnumItem(_response, index);
}

class WingConsole {
  static final Finalizer<WingConsole> _finalizer =
      Finalizer((console) => console.close());

  void close() {
      ffiBindings.consoleDestroy(_console);
      _finalizer.detach(this);
  }

  WingConsole._fromNative(this._console);

  final Pointer<NativeWingConsole> _console;
  Pointer<NativeWingConsole> get nativePointer => _console;

  static int nameToId(String name) {
        final nameNative = name.toNativeUtf8(allocator: malloc);
        try {
            Pointer<Int32> outId = malloc<Int32>(1);
            try {
                final rc = ffiBindings.nameToId(nameNative, outId);
                if (rc != 0) {
                    return outId.value;
                } else {
                    throw Exception('Failed to convert name $name to id');
                }
            } finally {
                malloc.free(outId);
            }
        } finally {
            malloc.free(nameNative);
        }
    }

  static WingConsole? connect(String? ip) {
      if (ip == null) {
          var c = ffiBindings.consoleConnect(nullptr);
          if (c == nullptr) { return null; }
          return WingConsole._fromNative(c);
      } else {
          final ipNative = ip.toNativeUtf8(allocator: malloc);
          try {
              var c = ffiBindings.consoleConnect(ipNative);
              if (c == nullptr) { return null; }
              return WingConsole._fromNative(c);
          } finally {
              malloc.free(ipNative);
          }
      }
  }

  Response? read() {
      final r = ffiBindings.consoleRead(_console);
      if (r == nullptr) {
          return null;
      }
      return Response.fromNative(r);
  }

  void setString(int id, String value) {
      final valueNative = value.toNativeUtf8(allocator: malloc);
      try {
          if (ffiBindings.consoleSetString(_console, id, valueNative) != 0) throw Exception('Failed to set string');
      } finally {
          malloc.free(valueNative);
      }
  }

  void setFloat(int id, double value) {
      if (ffiBindings.consoleSetFloat(_console, id, value) != 0) throw Exception('Failed to set float');
  }

  void setInt(int id, int value) {
      if (ffiBindings.consoleSetInt(_console, id, value) != 0) throw Exception('Failed to set int');
  }

  void requestNodeData(int id) {
      if (ffiBindings.consoleRequestNodeData(_console, id) != 0) throw Exception('Failed to request node data');
  }

  void requestNodeDef(int id) {
      if (ffiBindings.consoleRequestNodeDef(_console, id) != 0) throw Exception('Failed to request node def');
  }

}
