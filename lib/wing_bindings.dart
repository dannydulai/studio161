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
    late final void Function(Pointer<NativeWingConsole> console, int id) consoleRequestNodeData;
    late final void Function(Pointer<NativeWingConsole> console, int id) consoleRequestNodeDef;
    
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

    late final int  Function(Pointer<Utf8>) nodeInitMap;
    late final int  Function(Pointer<Utf8>) nodeNameToId;
    late final void Function(int, Pointer<Utf8>, int) nodeIdToName;

    late final void   Function(Pointer<NativeNodeDefinition>) nodeDefDestroy;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetType;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetUnit;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefIsReadOnly;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetParentId;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetId;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetIndex;
    late final double Function(Pointer<NativeNodeDefinition>) nodeDefGetMinFloat;
    late final double Function(Pointer<NativeNodeDefinition>) nodeDefGetMaxFloat;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetMinInt;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetMaxInt;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetSteps;
    late final int    Function(Pointer<NativeNodeDefinition>) nodeDefGetMaxStringLen;
    late final void   Function(Pointer<NativeNodeDefinition>, Pointer<Utf8>, int) nodeDefGetName;
    late final void   Function(Pointer<NativeNodeDefinition>, Pointer<Utf8>, int) nodeDefGetLongName;

    late final int  Function(Pointer<NativeNodeDefinition>) nodeDefGetStringEnumCount;
    //XXX late final void Function(Pointer<NativeNodeDefinition>, int) nodeDefGetStringEnumItem;

    late final int  Function(Pointer<NativeNodeDefinition>) nodeDefGetFloatEnumCount;
    //XXX late final void Function(Pointer<NativeNodeDefinition>, int) nodeDefGetFloatEnumItem;

    late final void  Function(Pointer<NativeNodeData>) nodeDataDestroy;
    late final double Function(Pointer<NativeNodeData>) nodeDataGetFloat;
    late final int   Function(Pointer<NativeNodeData>) nodeDataGetInt;
    late final void  Function(Pointer<NativeNodeData>, Pointer<Utf8>, int) nodeDataGetString;
    late final int   Function(Pointer<NativeNodeData>) nodeDataHasString;
    late final int   Function(Pointer<NativeNodeData>) nodeDataHasFloat;
    late final int   Function(Pointer<NativeNodeData>) nodeDataHasInt;

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

        consoleRequestNodeData = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Uint32),
            void Function(Pointer<NativeWingConsole>, int)>('wing_console_request_node_data');

        consoleRequestNodeDef = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Uint32),
            void Function(Pointer<NativeWingConsole>, int)>('wing_console_request_node_definition');

        consoleSetString = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Uint32, Pointer<Utf8>),
            void Function(Pointer<NativeWingConsole>, int, Pointer<Utf8>)>('wing_console_set_string');

        consoleSetFloat = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Uint32, Float),
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

        nodeInitMap = _lib.lookupFunction<
            Int32 Function(Pointer<Utf8>),
            int   Function(Pointer<Utf8>)>('wing_node_init_map');

        nodeNameToId = _lib.lookupFunction<
            Uint32 Function(Pointer<Utf8>),
            int    Function(Pointer<Utf8>)>('wing_node_name_to_id');

        nodeIdToName = _lib.lookupFunction<
            Void Function(Uint32, Pointer<Utf8>, Uint32),
            void Function(int, Pointer<Utf8>, int)>('wing_node_id_to_name');

        nodeDefDestroy = _lib.lookupFunction<
            Void Function(Pointer<NativeNodeDefinition>),
            void Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_destroy');

        nodeDefGetType = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeDefinition>),
            int   Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_type');

        nodeDefGetUnit = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeDefinition>),
            int   Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_unit');

        nodeDefGetName = _lib.lookupFunction<
            Void Function(Pointer<NativeNodeDefinition>, Pointer<Utf8>, Uint32),
            void Function(Pointer<NativeNodeDefinition>, Pointer<Utf8>, int)>('wing_node_definition_get_name');

        nodeDefGetLongName = _lib.lookupFunction<
            Void Function(Pointer<NativeNodeDefinition>, Pointer<Utf8>, Uint32),
            void Function(Pointer<NativeNodeDefinition>, Pointer<Utf8>, int)>('wing_node_definition_get_long_name');

        nodeDefGetParentId = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_parent_id');

        nodeDefGetId = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_id');

        nodeDefGetIndex = _lib.lookupFunction<
            Uint16 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_index');

        nodeDefGetMinFloat = _lib.lookupFunction<
            Float Function(Pointer<NativeNodeDefinition>),
            double Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_min_float');

        nodeDefGetMaxFloat = _lib.lookupFunction<
            Float Function(Pointer<NativeNodeDefinition>),
            double Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_max_float');

        nodeDefGetSteps = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_steps');

        nodeDefGetMinInt = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_min_int');

        nodeDefGetMaxInt = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_max_int');

        nodeDefGetMaxStringLen = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeNodeDefinition>),
            int Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_max_string_len');

        nodeDefGetStringEnumCount = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeDefinition>),
            int   Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_string_enum_count');

        // XXX
        // nodeDefGetStringEnumItem = _lib.lookupFunction<
        //     Void Function(Pointer<NativeNodeDefinition>, Int32),
        //     void Function(Pointer<NativeNodeDefinition>, int)>('wing_node_definition_get_string_enum_item');

        nodeDefGetFloatEnumCount = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeDefinition>),
            int   Function(Pointer<NativeNodeDefinition>)>('wing_node_definition_get_float_enum_count');

        // XXX
        // nodeDefGetFloatEnumItem = _lib.lookupFunction<
        //     Void Function(Pointer<NativeNodeDefinition>, Int32),
        //     void Function(Pointer<NativeNodeDefinition>, int)>('wing_node_definition_get_float_enum_item');

        nodeDataDestroy = _lib.lookupFunction<
            Void Function(Pointer<NativeNodeData>),
            void Function(Pointer<NativeNodeData>)>('wing_node_data_destroy');

        nodeDataGetFloat = _lib.lookupFunction<
            Float Function(Pointer<NativeNodeData>),
            double Function(Pointer<NativeNodeData>)>('wing_node_data_get_float');

        nodeDataGetInt = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeData>),
            int   Function(Pointer<NativeNodeData>)>('wing_node_data_get_int');

        nodeDataGetString = _lib.lookupFunction<
            Void Function(Pointer<NativeNodeData>, Pointer<Utf8>, Size),
            void Function(Pointer<NativeNodeData>, Pointer<Utf8>, int)>('wing_node_data_get_string');

        nodeDataHasString = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeData>),
            int   Function(Pointer<NativeNodeData>)>('wing_node_data_has_string');

        nodeDataHasFloat = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeData>),
            int   Function(Pointer<NativeNodeData>)>('wing_node_data_has_float');

        nodeDataHasInt = _lib.lookupFunction<
            Int32 Function(Pointer<NativeNodeData>),
            int   Function(Pointer<NativeNodeData>)>('wing_node_data_has_int');
    }
}
