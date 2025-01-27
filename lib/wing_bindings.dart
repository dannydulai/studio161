import 'dart:ffi';
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

// Opaque types
final class NativeWingConsole extends Opaque {}
final class NativeWingDiscover extends Opaque {}
final class NativeNodeData extends Opaque {}
final class NativeNodeDefinition extends Opaque {}

// Callback typedefs
typedef WingRequestEndCallback     = Void Function(Pointer<Void> userData);
typedef WingNodeDefinitionCallback = Void Function(Pointer<NativeNodeDefinition> def, Pointer<Void> userData);
typedef WingNodeDataCallback       = Void Function(Uint32 id, Pointer<NativeNodeData> data, Pointer<Void> userData);

// Native function signatures
class WingBindings {
    final DynamicLibrary _lib;

    late final Pointer<NativeWingDiscover> Function(int stopOnFirst) discoverScan;
    late final void Function(Pointer<NativeWingDiscover>) discoverDestroy;
    late final int Function(Pointer<NativeWingDiscover>) discoverCount;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetIp;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetName;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetModel;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetSerial;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetFirmware;

    late final Pointer<NativeWingConsole> Function(Pointer<Utf8> ip) consoleConnect;
    late final void Function(Pointer<NativeWingConsole> console) consoleDestroy;
    late final void Function(Pointer<NativeWingConsole> console) consoleRead;
    late final void Function(Pointer<NativeWingConsole> console, int id, Pointer<Utf8> value) consoleSetString;
    late final void Function(Pointer<NativeWingConsole> console, int id, double value) consoleSetFloat;
    late final void Function(Pointer<NativeWingConsole> console, int id, int value) consoleSetInt;
    
    // Callback setters
    late final void Function(
        Pointer<NativeWingConsole> console,
        Pointer<NativeFunction<WingRequestEndCallback>> callback,
        Pointer<Void> userData
    ) consoleSetRequestEndCallback;

    late final void Function(
        Pointer<NativeWingConsole> console,
        Pointer<NativeFunction<WingNodeDefinitionCallback>> callback,
        Pointer<Void> userData
    ) consoleSetNodeDefinitionCallback;

    late final void Function(
        Pointer<NativeWingConsole> console,
        Pointer<NativeFunction<WingNodeDataCallback>> callback,
        Pointer<Void> userData
    ) consoleSetNodeDataCallback;

    WingBindings(this._lib) {
        discoverScan = _lib.lookupFunction<
            Pointer<NativeWingDiscover> Function(Int32),
            Pointer<NativeWingDiscover> Function(int)>('wing_discover_scan');

        discoverDestroy = _lib.lookupFunction<
            Void Function(Pointer<NativeWingDiscover>),
            void Function(Pointer<NativeWingDiscover>)>('wing_discover_destroy');

        discoverCount = _lib.lookupFunction<
            Int32 Function(Pointer<NativeWingDiscover>),
            int   Function(Pointer<NativeWingDiscover>)>('wing_discover_count');

        discoverGetIp = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, Int32),
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int)>('wing_discover_get_ip');

        discoverGetName = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, Int32),
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int)>('wing_discover_get_name');

        discoverGetModel = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, Int32),
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int)>('wing_discover_get_model');

        discoverGetSerial = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, Int32),
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int)>('wing_discover_get_serial');

        discoverGetFirmware = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, Int32),
            Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int)>('wing_discover_get_firmware');

        consoleConnect = _lib.lookupFunction<
            Pointer<NativeWingConsole> Function(Pointer<Utf8>),
            Pointer<NativeWingConsole> Function(Pointer<Utf8>)>('wing_console_connect');

        consoleDestroy = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>),
            void Function(Pointer<NativeWingConsole>)>('wing_console_destroy');

        consoleRead = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>),
            void Function(Pointer<NativeWingConsole>)>('wing_console_read');

        consoleSetString = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Uint32, Pointer<Utf8>),
            void Function(Pointer<NativeWingConsole>, int, Pointer<Utf8>)>('wing_console_set_string');

        consoleSetFloat = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Uint32, Double),
            void Function(Pointer<NativeWingConsole>, int, double)>('wing_console_set_float');

        consoleSetInt = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Uint32, Int32),
            void Function(Pointer<NativeWingConsole>, int, int)>('wing_console_set_int');

        consoleSetRequestEndCallback = _lib.lookupFunction<
            Void Function(
                Pointer<NativeWingConsole>,
                Pointer<NativeFunction<WingRequestEndCallback>>,
                Pointer<Void>
            ),
            void Function(
                Pointer<NativeWingConsole>,
                Pointer<NativeFunction<WingRequestEndCallback>>,
                Pointer<Void>
            )>('wing_console_set_request_end_callback');

        consoleSetNodeDefinitionCallback = _lib.lookupFunction<
            Void Function(
                Pointer<NativeWingConsole>,
                Pointer<NativeFunction<WingNodeDefinitionCallback>>,
                Pointer<Void>
            ),
            void Function(
                Pointer<NativeWingConsole>,
                Pointer<NativeFunction<WingNodeDefinitionCallback>>,
                Pointer<Void>
            )>('wing_console_set_node_definition_callback');

        consoleSetNodeDataCallback = _lib.lookupFunction<
            Void Function(
                Pointer<NativeWingConsole>,
                Pointer<NativeFunction<WingNodeDataCallback>>,
                Pointer<Void>
            ),
            void Function(
                Pointer<NativeWingConsole>,
                Pointer<NativeFunction<WingNodeDataCallback>>,
                Pointer<Void>
            )>('wing_console_set_node_data_callback');

        wingNodeDefGetId = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_id');

        wingNodeDefGetType = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_type');

        wingNodeDefGetUnit = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_unit');

        wingNodeDefGetName = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeNodeDefinition>),
            Pointer<Utf8> Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_name');

        wingNodeDefGetPath = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeNodeDefinition>),
            Pointer<Utf8> Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_path');

        wingNodeDefGetMin = _lib.lookupFunction<
            Double Function(Pointer<NativeNodeDefinition>),
            double Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_min');

        wingNodeDefGetMax = _lib.lookupFunction<
            Double Function(Pointer<NativeNodeDefinition>),
            double Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_max');

        wingNodeDefGetDefault = _lib.lookupFunction<
            Double Function(Pointer<NativeNodeDefinition>),
            double Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_default');

        wingNodeDefGetEnumCount = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_def_get_enum_count');

        wingNodeDefGetEnumName = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeNodeDefinition>, Int32),
            Pointer<Utf8> Function(Pointer<NativeNodeDefinition>, int)>('wing_node_def_get_enum_name');

        wingNodeDefGetEnumValue = _lib.lookupFunction<
            Double Function(Pointer<NativeNodeDefinition>, Int32),
            double Function(Pointer<NativeNodeDefinition>, int)>('wing_node_def_get_enum_value');

        wingNodeDataGetType = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeData>),
            int Function(Pointer<NativeNodeData>)>('wing_node_data_get_type');

        wingNodeDataGetFloat = _lib.lookupFunction<
            Double Function(Pointer<NativeNodeData>),
            double Function(Pointer<NativeNodeData>)>('wing_node_data_get_float');

        wingNodeDataGetInt = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeData>),
            int Function(Pointer<NativeNodeData>)>('wing_node_data_get_int');

        wingNodeDataGetString = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeNodeData>),
            Pointer<Utf8> Function(Pointer<NativeNodeData>)>('wing_node_data_get_string');
    }
}
