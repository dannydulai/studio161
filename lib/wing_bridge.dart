import 'dart:ffi' as ffi;
import 'dart:io' show Platform, Directory;
import 'package:path/path.dart' as path;

// This will be populated with the actual bindings once we see wing_c_api.h
class WingBridge {
  static late final ffi.DynamicLibrary _lib;
  
  static void initialize() {
    const libName = 'wing';
    final libPrefix = Platform.isWindows ? '' : 'lib';
    final libSuffix = Platform.isWindows ? '.dll' : (Platform.isMacOS ? '.dylib' : '.so');
    final libFileName = '$libPrefix$libName$libSuffix';
    
    // Look for the library in the parent directory
    final libraryPath = path.join('..', 'libwing', libFileName);
    _lib = ffi.DynamicLibrary.open(libraryPath);
  }
}
