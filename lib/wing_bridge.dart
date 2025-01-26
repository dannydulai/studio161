import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:path/path.dart' as path;
import './wing_bindings.dart';

class WingBridge {
  static late final ffi.DynamicLibrary _lib;
  static late final WingBindings _bindings;
  static late final ffi.Pointer<WingConsole> _console;
  
  static void initialize() {
    const libName = 'wing';
    final libPrefix = Platform.isWindows ? '' : 'lib';
    final libSuffix = Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
    final libFileName = '$libPrefix$libName$libSuffix';
    
    // Look for the library in the parent directory
    final libraryPath = path.join('..', 'libwing', libFileName);
    _lib = ffi.DynamicLibrary.open(libraryPath);
    _bindings = WingBindings(_lib);
  }

  static List<WingDiscoveryInfo> discover({bool stopOnFirst = false}) {
    final maxCount = 10;
    final array = ffi.calloc<WingDiscoveryInfo>(maxCount);
    try {
      final count = _bindings.discover(array, maxCount, stopOnFirst ? 1 : 0);
      return List.generate(count, (i) => array[i]);
    } finally {
      ffi.calloc.free(array);
    }
  }

  static void connect(String ip) {
    final ipNative = ip.toNativeUtf8();
    try {
      _console = _bindings.connect(ipNative);
    } finally {
      ffi.calloc.free(ipNative);
    }
  }

  static void destroy() {
    _bindings.destroy(_console);
  }

  static void read() {
    _bindings.read(_console);
  }

  static void setString(int id, String value) {
    final valueNative = value.toNativeUtf8();
    try {
      _bindings.setString(_console, id, valueNative);
    } finally {
      ffi.calloc.free(valueNative);
    }
  }

  static void setFloat(int id, double value) {
    _bindings.setFloat(_console, id, value);
  }

  static void setInt(int id, int value) {
    _bindings.setInt(_console, id, value);
  }
}
