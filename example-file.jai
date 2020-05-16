/*
    Owner: Jonathan Blow <jon@number-none.com>
    Description: Minimal code the compiler needs to compiler user source code. Volatile!

    This file should only contain things the compiler needs in order
    to successfully compile user-level code. (For example, things for which
    it needs pointers at various stages in the compilation process).

    This file cannot contain any varargs
    procedures, because those would need to use the type of Any, but they might
    compile before Any. We could make dependencies on Any every time there's a
    varargs, but that seems like an unnecessary complication that would
    incur a runtime performace penalty.

                             -- jblow, 15 May 2015.

    Addendum: We also can't compile any code here that does string comparisons,
    due to lack of __strings_are_equal, __strings_are_not_equal! Also, we can't
    use type_info() here! Really it is best if there is no imperative code at all.

*/

Type_Info_Tag :: enum u32 {
    INTEGER   :: 0;
    FLOAT     :: 1;
    BOOL      :: 2;
    STRING    :: 3;
    POINTER   :: 4;
    PROCEDURE :: 5;
    VOID      :: 6;
    STRUCT    :: 7;
    ARRAY     :: 8;
    OVERLOAD_SET :: 9;
    ANY       :: 10;
    ENUM      :: 11;
    POLYMORPHIC_VARIABLE :: 12;
    TYPE      :: 13;
    CODE      :: 14;
}

// The Type_Infos all need to be here because when you say
// type_info(x), we downcast to the most specific Type_Info.
// This is useful. But requires more in the preload. Sigh!

Type_Info :: struct {
    type : Type_Info_Tag;          // @@ IC: I think it would be nice to rename this "tag" to avoid type.type confusion.

    index_within_type_table: u32;
    runtime_size:            s64;  // WARNING: runtime_size may be unset for structs at compile-time if compilation is not finished. (It will be -1 in this case.)
}

Type_Info_Integer :: struct {
    using info : Type_Info;
    signed       : bool;
}

Type_Info_Float :: struct {
    using info : Type_Info;
}

// There is no Type_Info_Bool.

Type_Info_String :: struct {
    using info : Type_Info;

    relative_pointer_size : s32;  // 0 means not relative.
}

Type_Info_Pointer :: struct {
    using info : Type_Info;

    pointer_to  : *Type_Info;
    relative_pointer_size : s32;  // 0 means not relative.
}

Type_Info_Procedure :: struct {
    using info : Type_Info;

    argument_types : [] *Type_Info;
    return_types   : [] *Type_Info;

    procedure_flags: Flags;
    
    using Flags :: enum u32 {
        IS_ELSEWHERE    :: 0x1;
        IS_COMPILE_TIME :: 0x2;
        IS_POLYMORPHIC  :: 0x4;
        IS_COMPILER_GENERATED   :: 0x8;
        IS_C_CALL       :: 0x20;
        IS_TYPE_ONLY    :: 0x40;
        IS_INTRINSIC    :: 0x80;
    }
}

// There is no Type_Info_Void.

Struct_Flags :: enum_flags u32 {
    UNION            :: 0x2;
    NOT_INSTANTIABLE :: 0x4;
    FOREIGN          :: 0x8;
    HAS_NO_PADDING   :: 0x80;
    POLYMORPHIC      :: 0x200;
}

Struct_Status_Flags :: enum_flags u32 {
    INCOMPLETE :: 0x1;
    LOCAL      :: 0x4;
}

Type_Info_Struct :: struct {
    using info : Type_Info;

    name : string;
    members : [] Type_Info_Struct_Member;

    status_flags: Struct_Status_Flags;
    struct_flags: Struct_Flags;
    
    polymorph_source_struct: *Type_Info_Struct;

    initializer: (*void) -> void;
    
    // @Cleanup: Make constant_storage a string?
    constant_storage_size: s64;
    constant_storage_buffer: *u8;
}

Type_Info_Struct_Member :: struct {
    name : string;
    type : *Type_Info;
    offset_in_bytes : s64;
    
    flags : Flags;

    notes: [] string;

    offset_into_constant_storage : s64 = -1;

    using Flags :: enum_flags u32 {
        CONSTANT :: 0x1;
        IMPORTED :: 0x2;
        USING    :: 0x4;
    }
}

Type_Info_Array :: struct {
    using info : Type_Info;

    element_type : *Type_Info;

    array_type   : Array_Type;
    array_count  : s64;    // -1 unless this array is is of a known compile-time size, i.e. array_type is FIXED.

    relative_pointer_size : s32;  // 0 means not relative.

    using Array_Type :: enum u32 {
        FIXED     :: 0;
        VIEW      :: 1;
        RESIZABLE :: 2;
    }
}

// There is no Type_Info_Any.

Enum_Status_Flags :: enum_flags u32 {
    INCOMPLETE :: 0x1;
}

Type_Info_Enum :: struct {
    using info : Type_Info;
    
    name : string;
    internal_type   : *Type_Info_Integer;

    names:         [] string;
    values:        [] s64;

    status_flags: Enum_Status_Flags;
    is_flags := false;
}

// There is no Type_Info_Polymorphic_Variable.
// There is no Type_Info_Type.

Any :: struct {
     type : *Type_Info;
     value_pointer : *void;
}

Allocator :: #type (mode: Allocator_Mode, size: s64, old_size: s64, old_memory_pointer: *void, allocator_data: *void) -> *void;
Logger    :: #type (ident: string, message: string, mode: Log_Mode, data: *void) -> void;

Workspace :: s64;

Allocator_Mode :: enum {  // @Volatile: If you change these, the bytecode has to change!
    ALLOCATE  :: 0;
    RESIZE    :: 1;
    FREE      :: 2;
}

Log_Mode :: enum {
    NONE     :: 0;
    MINIMAL  :: 1;
    EVERYDAY :: 2;
    VERBOSE  :: 3;
}

Stack_Trace_Procedure_Info :: struct {
    name:      string;
    location:  Source_Code_Location;

    procedure_address: *void;

    // @Incomplete: We may wish to provide the procedure type here?
    // procedure_type:    *Type_Info_Procedure;
}

// @Speed: We can cut down Stack_Trace_Node so that much of it
// lives in static space, so it'd just be 3 pointers: Pointer to
// location record (filename, line number, procedure), 64-bit hash,
// next pointer. It can be bigger if we want to store depth also...
Stack_Trace_Node :: struct {  // @Volatile: Must match the layout built into the compiler.
    next:        *Stack_Trace_Node;
    info:        *Stack_Trace_Procedure_Info;
    hash:        u64;
    call_depth:  u32;
    line_number: u32;
}

// @Volatile: Context_Base must match internal compiler settings in general.h
Context_Base :: struct {
    thread_index   : u32;

    allocator      := default_allocator;
    allocator_data : *void;

    logger         := default_logger;
    logger_data    : *void;

    assertion_failed := default_assertion_failed;
    
    temporary_storage : *Temporary_Storage;

    // Note: We don't #if this out right now when _STACK_TRACE is false, because
    // _STACK_TRACE gets added after the Preload is loaded, for implementation detail
    // reasons. We could change this eventually, but in the meantime, you just can't
    // use _STACK_TRACE in the Preload at all. So if _STACK_TRACE is false, this pointer
    // will still exist in the context, but it will stay null.
    stack_trace: *Stack_Trace_Node;

    // Things that don't take up any space:
    default_logger           :: (message: string, ident: string, mode: Log_Mode, data: *void) { write_strings("[", ident, "] ", message); };
    default_assertion_failed :: (loc: Source_Code_Location, message: string) { runtime_support_assertion_failed :: (loc: Source_Code_Location, message: string) #runtime_support; runtime_support_assertion_failed(loc, message); } // @Cleanup
    default_allocator        :: __default_allocator;

    handling_assertion_failure := false;  // Used internally. Do not mess with this value.
}

#add_context using base: Context_Base;

__default_allocator :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory_pointer: *void, allocator_data: *void) -> *void {
    // @Temporary: This bridge is just here to deal with some problem involving #runtime_support procedure pointers not being handled
    // correctly by the backends. Once that is fixed, this can be removed.
    // :RuntimeSupportCleanup
    runtime_support_default_allocator :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory_pointer: *void, allocator_data: *void) -> *void #runtime_support;
    return runtime_support_default_allocator(mode, size, old_size, old_memory_pointer, allocator_data);
}

Temporary_Storage :: struct {  // @Volatile: Must match general.h
    data:     *u8;
    size:     s64;       // @Volatile: Must stay s32, or init code in Bytecode_Builder must change.
    occupied: s64;
    high_water_mark: s64;
    
    overflow_allocator := __default_allocator;
    overflow_allocator_data: *void;

    overflow_pages: *Overflow_Page;
    original_data: *u8;  // Data to restore after clearing overflow pages. @Simplify: Maybe could be an Overflow_Page, but maybe we want to be able to assert on overflow_pages==null to ensure performance.
    original_size: s64;
    
    Overflow_Page :: struct {
        next: *Overflow_Page;
        allocator: Allocator;
        allocator_data: *void;
        size: s64;
    }
}

// @Cleanup: __strings_are_equal, __srings_are_not_equal should not
// be in here ... we can have intrinsics for these.
strings_are_equal     :: (a: string, b: string) -> bool #runtime_support #compiler;
strings_are_not_equal :: (a: string, b: string) -> bool #runtime_support #compiler;

__command_line_arguments: [] *u8;


Source_Code_Location :: struct {
    fully_pathed_filename: string;
    line_number:           s64;
    character_number:      s64;
}

get_current_workspace :: () -> Workspace #compiler {
    // If calling this at runtime, we just return 0.
    // You might think we want to assert, but stuff
    // like thread_create calls this and doesn't think
    // about whether it's compile-time or not, and maybe
    // that is more convenient.

    return cast(Workspace) 0;
}

// We need this here because #code directives result in
// a *Code_Node. Sigh.      -jblow, 11 November 2017
Code_Node :: struct {
    Kind :: enum u8 {
        UNINITIALIZED :: 0;
        BLOCK     :: 1;
        LITERAL   :: 2;
        IDENT     :: 3;
        UNARY_OPERATOR  :: 4;
        BINARY_OPERATOR :: 5;
        PROCEDURE_BODY  :: 6;
        PROCEDURE_CALL  :: 7;
        // 8 is currently unused.
        WHILE     :: 9;
        IF        :: 10;
        LOOP_CONTROL :: 11;
        CASE      :: 12;
        REMOVE    :: 13;
        RETURN    :: 14;
        EACH      :: 15;

        TYPE_DEFINITION :: 16;
        TYPE_INSTANTIATION :: 17;
        ENUM :: 18;

        PROCEDURE_HEADER :: 19;
        STRUCT :: 20;
        COMMA_SEPARATED_ARGUMENTS :: 21;
        EXTRACT :: 22;
        SEQUENCE :: 23;
        MAKE_VARARGS :: 24;

        DECLARATION :: 25;

        CAST_EXPRESSION :: 26;

        DIRECTIVE_IMPORT :: 27;
        DIRECTIVE_INLINE :: 28;
        DIRECTIVE_THROUGH :: 29;
        DIRECTIVE_LOAD :: 30;

        DIRECTIVE_RUN :: 31;
        DIRECTIVE_CODE :: 32;
        DIRECTIVE_POKE_NAME :: 33;
        // DIRECTIVE_IF_DEFINED :: 34;  Not currently implemented.
        DIRECTIVE_BAKE :: 35;
        DIRECTIVE_MODIFY :: 36;
        DIRECTIVE_FOREIGN_LIBRARY :: 37;

        SIZE_OR_TYPE_INFO :: 38;
        CONTEXT_OR_PUSH   :: 39;

        NOTE :: 40;

        DIRECTIVE_PLACE :: 41;
        DIRECTIVE_SCOPE :: 42;
        DIRECTIVE_STATIC_IF :: 43;
        DIRECTIVE_LOCATION :: 44;
        DIRECTIVE_ALIGN :: 45;
        DIRECTIVE_ADD_CONTEXT :: 46;

        COMPOUND_DECLARATION :: 47;
        DEFER :: 48;
        USING :: 49;
        PLACEHOLDER :: 50;
    };

    kind := Kind.UNINITIALIZED;

    type: *Type_Info;
    node_flags: u64;
    
    filename:    string;

    // l0 is the index of the starting line. l1 is the index of the ending line.
    // c0 is the index of the starting character (in bytes). c1 is the index of
    // the ending character's byte, +1 (i.e. the start of the next character).
    // @Speed: I made these s32 for speed/memory purposes, because there are a lot
    // of them! This may be insufficiently visionary... we may want to change them
    // to s64 before release. Consider this.
    // Pseudonym73 in chat is suggesting using a byte offset instead of
    // line/character pair. This would require decoding that via some process
    // that computes the line+character. It may be better though. Consider this.
    l0, c0, l1, c1: s32;

    serial:         s64;
}


// Most of these intrinsics are not actually required to compile code,
// so they should not be in this file. We should probably make an Intrinsics
// module for them.    -jblow, 28 December 2019

memcpy :: (dest: *void, source: *void, count: s64) #intrinsic;
memcmp :: (a: *void, b: *void, count: s64) -> s16  #intrinsic;  // @Incomplete: Do we want to tell people how many bytes in the first difference is?  // @Incomplete: The C spec for this routine sucks; we should probably return the actual byte difference. But the bytecode_runner version uses the C library version which just returns <=>0. I don't really want to inherit this ill-defined version. Unless we think it really doesn't matter. I dunno.
memset :: (dest: *void, value: u8, count: s64)     #intrinsic;

// Valid for bool, pointers, s8, s16, s32, s64, u8, u16, u32, u64, enums.
atomic_swap       :: (dest: *$T, new_value: T) -> (old_value: T) #intrinsic;
compare_and_swap  :: (dest: *$T, old_value: T, new_value: T) -> bool #intrinsic;
compare_and_swap2 :: (dest: *void, old_value_1: $T1_64, old_value_2: $T2_64, new_value_1: T1_64, new_value_2: T2_64) -> bool #intrinsic;
// Future functionality: A version of compare_and_swap2 that returns the old values as return values, so you can loop on those instead of needing a separate read step in the loop ... so says jacobly0 in chat. Err actually as pointers, since we can't loop treating a multiple return value as a truth condition. As mentioned, this current version is more of a conditional store.

debug_break :: () #intrinsic;
pause    :: () #intrinsic;
rdtsc    :: () -> u64 #intrinsic;
rdtscp   :: () -> u64 #intrinsic;
rdseed   :: () -> (success: bool, value: u64) #intrinsic;
rdrand   :: () -> (success: bool, value: u64) #intrinsic;
prefetch :: (pointer: *void, hint: u8) #intrinsic;  // hint 0 = NTA, 1 = T0, 2 = T1, 3 = T2
read_gs_qword :: (offset: u32) -> u64 #intrinsic;

atomic_add :: (dest: *$T, value: T) -> T  #intrinsic;  // @Incomplete: Do we want to guard against floating-point numbers here?
atomic_increment :: (dest: *$T) #intrinsic;  // @Incomplete: Do we want to guard against floating-point numbers here?

atomic_and :: (dest: *$T, value: T) #intrinsic;  // @Incomplete: Do we want to guard against floating-point numbers here?
atomic_or  :: (dest: *$T, value: T) #intrinsic;
atomic_xor :: (dest: *$T, value: T) #intrinsic;

mfence :: () #intrinsic;

cpuid  :: (info: [4] u32, fid: u32, exfid: u32 = 0) #intrinsic;
xgetbv :: (xcr: u32) -> u64 #intrinsic;

write_string  :: (s: string) #runtime_support;
write_strings :: (strings: ..string) #runtime_support;



// Rather than declaring these structs here, we could have the compiler
// do its own hardcoded thing internally so it doesn't require these declarations.
// I dunno man!

Newstring    :: struct {
    count     : s64;  // Signed so that if we do for 0..count-1 it works...
    data      : *u8;
};

Array_View_64 :: struct {
    count     : s64;  // Signed so that if we do for 0..count-1 it works...   
    data      : *u8;
}

Array_View_32 :: struct {
    count     : s32;
    data      : *~s32 u8;
}

Array_View_16 :: struct {
    count     : s16;
    data      : *~s16 u8;
}

Array_View_8 :: struct {
    count     : s8;
    data      : *~s8 u8;
}

// Resizable_Array is used in Print, so we left it here,
// but maybe it should go into file scope and Print should
// have its own copy.
// (It's also used by the compiler internally.)
Resizable_Array :: struct {
    count      : s64;  // Signed so that if we do for 0..count-1 it works...
    data       : *void;
    allocated  : s64;

    allocator      : Allocator;
    allocator_data : *void;
}

// This is used so that we can typecheck/polymorph a name-mapping procedure for #load directives.
__name_mapper :: #type (string) -> string;
