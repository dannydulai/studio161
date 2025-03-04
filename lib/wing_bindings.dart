import 'dart:ffi';
import 'package:ffi/ffi.dart';

enum ResponseType {
    end(0),
    nodeDefinition(1),
    nodeData(2);

    final int value;
    const ResponseType(this.value);
}

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

enum MeterType {
    channel(0xa0),
    aux(0xa1),
    bus(0xa2),
    main(0xa3),
    matrix(0xa4),
    dca(0xa5),
    fx(0xa6),
    source(0xa7),
    output(0xa8),
    monitor(0xa9),
    rta(0xaa),
    channel2(0xab),
    aux2(0xac),
    bus2(0xad),
    main2(0xae),
    matrix2(0xaf);

    final int value;
    const MeterType(this.value);
}

// Opaque types
final class NativeWingConsole extends Opaque {}
final class NativeWingDiscover extends Opaque {}
final class NativeWingMeter extends Opaque {}
final class NativeResponse extends Opaque {}
final class NativeMeterResponse extends Opaque {}

// Native function signatures
class WingBindings {
    final DynamicLibrary _lib;

    late final Pointer<NativeWingDiscover> Function(int stopOnFirst) discoverScan;
    late final void          Function(Pointer<NativeWingDiscover>) discoverDestroy;
    late final int           Function(Pointer<NativeWingDiscover>) discoverCount;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetIp;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetName;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetModel;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetSerial;
    late final Pointer<Utf8> Function(Pointer<NativeWingDiscover>, int) discoverGetFirmware;

    late final Pointer<NativeWingConsole> Function(Pointer<Utf8> ip) consoleConnect;
    late final void          Function(Pointer<NativeWingConsole> console) consoleDestroy;
    late final Pointer<NativeResponse> Function(Pointer<NativeWingConsole> console) consoleRead;
    late final void          Function(Pointer<NativeWingConsole> console, int nativeport) dartConsoleRead;
    late final int           Function(Pointer<NativeWingConsole> console, int id, Pointer<Utf8> value) consoleSetString;
    late final int           Function(Pointer<NativeWingConsole> console, int id, double value) consoleSetFloat;
    late final int           Function(Pointer<NativeWingConsole> console, int id, int value) consoleSetInt;
    late final int           Function(Pointer<NativeWingConsole> console, int id) consoleRequestNodeData;
    late final int           Function(Pointer<NativeWingConsole> console, int id) consoleRequestNodeDef;

    late final int           Function(Pointer<NativeWingConsole> console, Pointer<Uint16>, int) consoleRequestMeter;
    late final int           Function(Pointer<NativeWingConsole> console, Pointer<Uint16>, Pointer<Int16>) consoleReadMeter;
    late final void          Function(Pointer<NativeWingConsole> console, int nativeport) dartConsoleReadMeter;
                             
    late final void          Function(Pointer<NativeResponse>) responseDestroy;
    late final int           Function(Pointer<NativeResponse>) responseGetType;

    late final int           Function(Pointer<NativeResponse>) nodeDataGetId;
    late final double        Function(Pointer<NativeResponse>) nodeDataGetFloat;
    late final int           Function(Pointer<NativeResponse>) nodeDataGetInt;
    late final Pointer<Utf8> Function(Pointer<NativeResponse>) nodeDataGetString;
    late final int           Function(Pointer<NativeResponse>) nodeDataHasString;
    late final int           Function(Pointer<NativeResponse>) nodeDataHasFloat;
    late final int           Function(Pointer<NativeResponse>) nodeDataHasInt;
                             
    late final int           Function(Pointer<NativeResponse>) nodeDefGetParentId;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetId;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetIndex;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetType;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetUnit;
    late final Pointer<Utf8> Function(Pointer<NativeResponse>) nodeDefGetName;
    late final Pointer<Utf8> Function(Pointer<NativeResponse>) nodeDefGetLongName;
    late final int           Function(Pointer<NativeResponse>) nodeDefIsReadOnly;
    late final double        Function(Pointer<NativeResponse>) nodeDefGetMinFloat;
    late final double        Function(Pointer<NativeResponse>) nodeDefGetMaxFloat;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetSteps;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetMinInt;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetMaxInt;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetMaxStringLen;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetStringEnumCount;
    late final int           Function(Pointer<NativeResponse>) nodeDefGetFloatEnumCount;
    //XXX late final void Function(Pointer<NativeResponse>, int) nodeDefGetStringEnumItem;
    //XXX late final void Function(Pointer<NativeResponse>, int) nodeDefGetFloatEnumItem;

    late final int           Function(Pointer<Utf8>, Pointer<Int32>) nameToId;
    late final void          Function(Pointer<Utf8>) stringDestroy;

    WingBindings(this._lib) {
        final storeDartPostCobject = _lib.lookupFunction<
            Void Function(Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr),
            void Function(Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>> ptr)>('store_dart_post_cobject');

        storeDartPostCobject(NativeApi.postCObject);


        
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
            Pointer<NativeResponse> Function(Pointer<NativeWingConsole>),
            Pointer<NativeResponse> Function(Pointer<NativeWingConsole>)>('wing_console_read');

        dartConsoleRead = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Int64),
            void Function(Pointer<NativeWingConsole>, int)>('dart_wing_console_read');

        dartConsoleReadMeter = _lib.lookupFunction<
            Void Function(Pointer<NativeWingConsole>, Int64),
            void Function(Pointer<NativeWingConsole>, int)>('dart_wing_console_read_meter');

        consoleSetString = _lib.lookupFunction<
            Int32 Function(Pointer<NativeWingConsole>, Int32, Pointer<Utf8>),
            int  Function(Pointer<NativeWingConsole>, int, Pointer<Utf8>)>('wing_console_set_string');

        consoleSetFloat = _lib.lookupFunction<
            Int32 Function(Pointer<NativeWingConsole>, Int32, Float),
            int  Function(Pointer<NativeWingConsole>, int, double)>('wing_console_set_float');

        consoleSetInt = _lib.lookupFunction<
            Int32 Function(Pointer<NativeWingConsole>, Uint32, Int32),
            int  Function(Pointer<NativeWingConsole>, int, int)>('wing_console_set_int');

        consoleRequestNodeData = _lib.lookupFunction<
            Int32 Function(Pointer<NativeWingConsole>, Int32),
            int  Function(Pointer<NativeWingConsole>, int)>('wing_console_request_node_data');

        consoleRequestNodeDef = _lib.lookupFunction<
            Int32 Function(Pointer<NativeWingConsole>, Int32),
            int  Function(Pointer<NativeWingConsole>, int)>('wing_console_request_node_definition');

        consoleRequestMeter = _lib.lookupFunction<
            Uint16 Function(Pointer<NativeWingConsole>, Pointer<Uint16>, Size),
            int Function(Pointer<NativeWingConsole>, Pointer<Uint16>, int)>('wing_console_request_meter');

        consoleReadMeter = _lib.lookupFunction<
            Int32 Function(Pointer<NativeWingConsole>, Pointer<Uint16>, Pointer<Int16>),
            int   Function(Pointer<NativeWingConsole>, Pointer<Uint16>, Pointer<Int16>)>('wing_console_read_meter');

        responseDestroy = _lib.lookupFunction<
            Void Function(Pointer<NativeResponse>),
            void Function(Pointer<NativeResponse>)>('wing_response_destroy');

        responseGetType = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_response_get_type');

        nodeDataGetId = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_data_get_id');

        nodeDataGetFloat = _lib.lookupFunction<
            Float Function(Pointer<NativeResponse>),
            double Function(Pointer<NativeResponse>)>('wing_node_data_get_float');

        nodeDataGetInt = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_data_get_int');

        nodeDataGetString = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeResponse>),
            Pointer<Utf8> Function(Pointer<NativeResponse>)>('wing_node_data_get_string');

        nodeDataHasString = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_data_has_string');

        nodeDataHasFloat = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_data_has_float');

        nodeDataHasInt = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_data_has_int');

        nodeDefGetParentId = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeResponse>),
            int Function(Pointer<NativeResponse>)>('wing_node_definition_get_parent_id');

        nodeDefGetId = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeResponse>),
            int Function(Pointer<NativeResponse>)>('wing_node_definition_get_id');

        nodeDefGetIndex = _lib.lookupFunction<
            Uint16 Function(Pointer<NativeResponse>),
            int Function(Pointer<NativeResponse>)>('wing_node_definition_get_index');

        nodeDefGetType = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_definition_get_type');

        nodeDefGetUnit = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_definition_get_unit');

        nodeDefGetName = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeResponse>),
            Pointer<Utf8> Function(Pointer<NativeResponse>)>('wing_node_definition_get_name');

        nodeDefGetLongName = _lib.lookupFunction<
            Pointer<Utf8> Function(Pointer<NativeResponse>),
            Pointer<Utf8> Function(Pointer<NativeResponse>)>('wing_node_definition_get_long_name');

        nodeDefIsReadOnly = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_definition_is_read_only');

        nodeDefGetMinFloat = _lib.lookupFunction<
            Float Function(Pointer<NativeResponse>),
            double Function(Pointer<NativeResponse>)>('wing_node_definition_get_min_float');

        nodeDefGetMaxFloat = _lib.lookupFunction<
            Float Function(Pointer<NativeResponse>),
            double Function(Pointer<NativeResponse>)>('wing_node_definition_get_max_float');

        nodeDefGetSteps = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeResponse>),
            int Function(Pointer<NativeResponse>)>('wing_node_definition_get_steps');

        nodeDefGetMinInt = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeResponse>),
            int Function(Pointer<NativeResponse>)>('wing_node_definition_get_min_int');

        nodeDefGetMaxInt = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeResponse>),
            int Function(Pointer<NativeResponse>)>('wing_node_definition_get_max_int');

        nodeDefGetMaxStringLen = _lib.lookupFunction<
            Uint32 Function(Pointer<NativeResponse>),
            int Function(Pointer<NativeResponse>)>('wing_node_definition_get_max_string_len');

        nodeDefGetStringEnumCount = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_definition_get_string_enum_count');

        nodeDefGetFloatEnumCount = _lib.lookupFunction<
            Int32 Function(Pointer<NativeResponse>),
            int   Function(Pointer<NativeResponse>)>('wing_node_definition_get_float_enum_count');

        // XXX
        // nodeDefGetStringEnumItem = _lib.lookupFunction<
        //     Void Function(Pointer<NativeResponse>, Int32),
        //     void Function(Pointer<NativeResponse>, int)>('wing_node_definition_get_string_enum_item');

        // XXX
        // nodeDefGetFloatEnumItem = _lib.lookupFunction<
        //     Void Function(Pointer<NativeResponse>, Int32),
        //     void Function(Pointer<NativeResponse>, int)>('wing_node_definition_get_float_enum_item');

        nameToId = _lib.lookupFunction<
            Int32 Function(Pointer<Utf8>, Pointer<Int32>),
            int   Function(Pointer<Utf8>, Pointer<Int32>)>('wing_name_to_id');

        stringDestroy = _lib.lookupFunction<
            Void Function(Pointer<Utf8>),
            void Function(Pointer<Utf8>)>('wing_string_destroy');
    }
}
