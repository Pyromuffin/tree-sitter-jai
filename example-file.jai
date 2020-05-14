/*
  Owner: Jonathan Blow <jon@number-none.com>
  Description: The basic routines used in most programs.
 */

#load "Array.jai";
#load "Simple_String.jai";
#load "String_Builder.jai";
#load "Print.jai";
#load "tests.jai";   // @Temporary; once the test framework doesn't need us to, we won't load this automatically.

#scope_file
#if _MEMORY_DEBUGGER  #load "Memory_Debugger.jai";
#scope_export
 
get_command_line_arguments :: () -> [] string {
    c_args := __command_line_arguments;
    result := NewArray(c_args.count, string);
    for c_args {
        str_length :: (x: *u8) -> int @pure {  // Copied from String.jai to avoid dependency.
            assert(x != null);

            p := x;
            while << p  { p += 1; }
            return p - x;
        }
        
        result[it_index].data = it;
        result[it_index].count = str_length(it);
    }

    return result;
}

assert :: inline (arg: bool, message := "", args: .. Any, loc := #caller_location) {
    if arg return;

    if context.handling_assertion_failure  return;  // Avoid infinite loops.
    context.handling_assertion_failure = true;

    // We provide 'loc' in case _STACK_TRACE is turned off, but assertion_failed may well
    // look at the stack trace if it is available.
    context.assertion_failed(loc, tprint(message, ..args));
    context.handling_assertion_failure = false;
} @NoProfile @NoDebug


alloc :: (size: s64, allocator: Allocator = null, allocator_data: *void = null) -> *void {
    if allocator == null {
        allocator = context.allocator;
        allocator_data = context.allocator_data;
    }

    result := allocator(Allocator_Mode.ALLOCATE, size, 0, null, allocator_data);

    #if _MEMORY_DEBUGGER  check_alloc(allocator, allocator_data, result, size);
    
    return result;
}

free :: (memory: *void, allocator: Allocator = null, allocator_data: *void = null) {
    if allocator == null {
        allocator = context.allocator;
        allocator_data = context.allocator_data;
    }
    
    #if _MEMORY_DEBUGGER  check_free(allocator, allocator_data, memory);
    
    allocator(Allocator_Mode.FREE, 0, 0, memory, allocator_data);
}

realloc :: (memory: *void, size: s64, old_size: s64, allocator: Allocator = null, allocator_data: *void = null) -> *void {
    if allocator == null {
        allocator = context.allocator;
        allocator_data = context.allocator_data;
    }
    
    result := allocator(Allocator_Mode.RESIZE, size, old_size, memory, allocator_data);

    #if _MEMORY_DEBUGGER  check_realloc(allocator, allocator_data, memory, old_size, result, size);
    
    return result;
}

// Allocates a string.
alloc_string :: (count: int, allocator := context.allocator, allocator_data := context.allocator_data) -> string {
    assert(count >= 0);
    
    str: string;
    if !count return str;

    str.data = alloc(count, allocator, allocator_data);
    str.count = count;
    return str;
}

talloc_string :: (count: int) -> string {
    return alloc_string(count, __temporary_allocator, null);
}

free :: inline (s: string, allocator: Allocator = null, allocator_data: *void = null) {
    free(s.data, allocator, allocator_data);
}

push_allocator :: (allocator: Allocator, allocator_data := null) #expand {
    old_allocator := context.allocator;
    old_allocator_data := context.allocator_data;

    context.allocator = allocator;
    context.allocator_data = allocator_data;

    `defer context.allocator = old_allocator;
    `defer context.allocator_data = old_allocator_data;
}


// @@ Move to reflection?
get_field :: (info: *Type_Info_Struct, name: string) -> *Type_Info_Struct_Member {
    // First pass: Don't try recursing.
    for * info.members {
        ptr := *it.name;
        if name == it.name return it;
    }

    // Second pass: See if we can get something recursively.
    for * info.members {
        if (it.flags & it.flags.USING) && (it.type.type == Type_Info_Tag.STRUCT) {
            result := get_field(cast(*Type_Info_Struct)it.type, name);
            if result return result;
        }
    }
    
    return null;
}

// @@ Move to Compiler.jai? 
running_at_compile_time :: () -> bool #compiler {
    // If called outside the compiler, we're not running at compile time!
    return false;
}


// For floating point values, it returns the second value if the first is NaN.
min :: (a: $T, b: T) -> T {
    if a < b return a;
    return b;
}

// For floating point values, it returns the second value if the first is NaN.
max :: (a: $T, b: T) -> T {
    if b < a return a;
    return b;
}

// WARNING
// WARNING
// WARNING
// These overloads of 'max' and 'min' are error-prone... we need to
// restrict them to numeric types, and/or rename max/min in Math
// to be max_of_type / min_of_type (WE REALLY NEED TO DO THAT).

max :: inline (a: $T, x: ..T) -> T {
    m := a;
    for x if m < it m = it;
    return m;
}

min :: inline (a: $T, x: ..T) -> T {
    m := a;
    for x if it < m m = it;
    return m;
}

clamp :: (x: $T, a: T, b: T) -> T {
    return min(max(x, a), b);
}

Swap :: (a: *$T, b: *T) {   // @@ Why uppercase?
    tmp := << a;
    << a = << b;
    << b = tmp;
}

// IC: Isn't this cleaner than the version above? a,b = swap(a,b); @@ Note, in go you can simply do a,b = b,a, but not in jai!
// Yeah it is probably cleaner!
swap :: inline (a: $T, b: T) -> T #must, T #must {
    return b, a;
}

// @Cleanup: Put a better version of this into the standard library.
enum_names :: ($t: Type) -> [] string {
    info := type_info(t);
    assert(info.type == Type_Info_Tag.ENUM);
    return info.names;
}

enum_values :: ($t: Type) -> [] int {
    info := type_info(t);
    assert(info.type == Type_Info_Tag.ENUM);
    return info.values;
}

enum_highest_value :: ($t: Type) -> s64 {  // @Cleanup: A safe version of this will return type_of(T.loose)
    low, high := enum_range_given_info(type_info(t));
    return high;
}

enum_range :: ($t: Type) -> (low: s64, high: s64) {  // @Cleanup: A safe version of this will return type_of(T.loose)
    low, high := enum_range_given_info(type_info(t));
    return low, high;
}

enum_range_given_info :: (info: *Type_Info_Enum) -> (low: s64, high: s64) {  // @Cleanup: A safe version of this will return type_of(T.loose)
    if info.values.count == 0  return 0, 0;

    low  := cast(s64) info.values[0];
    high := low;
    for info.values {
        low  = min(low,  it);
        high = max(high, it);
    }

    return low, high;
}

// ## Temporary Memory Functions

// IC: This is such a common function, that I think is nice to have a shorter name for it.
talloc :: temporary_alloc;

temporary_alloc :: inline (size: s64) -> *void {
    return __temporary_allocator(Allocator_Mode.ALLOCATE, size, 0, null, null);
}

__temporary_allocator :: (mode: Allocator_Mode, requested_size: s64, old_size: s64, old_memory_pointer: *void, allocator_data: *void) -> *void {
    using Allocator_Mode;
    
    if #complete mode == {
      case FREE;
        return null;
      case RESIZE; #through;
      case ALLOCATE;
        // Pad to 8-byte alignment.
        size := (requested_size + 7) & ~7;
        
        ts := context.temporary_storage;

        if size > ts.size - ts.occupied {
            success := add_new_page(ts, size);
            if !success  return null;
        }

        result := ts.data + ts.occupied;
        ts.occupied += cast(s32) size;
        ts.high_water_mark = max(ts.high_water_mark, ts.occupied);
        
        if result && (mode == RESIZE) {
            memcpy(result, old_memory_pointer, min(old_size, requested_size));
        }
        
        return result;
    }
}

Temporary_Storage_State :: struct {
    top_overflow_page: *Temporary_Storage.Overflow_Page;
    occupied: s64;
}


get_temporary_storage_mark :: inline () -> Temporary_Storage_State {
    ts := context.temporary_storage;
    
    state: Temporary_Storage_State = ---;
    state.occupied = ts.occupied;
    state.top_overflow_page = ts.overflow_pages;

    return state;
}

// Typically used as follows:
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// mark := get_temporary_storage_mark();
// defer set_temporary_storage_mark(mark);
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Now we have the `auto_release_temp` macro.
set_temporary_storage_mark :: inline (state: Temporary_Storage_State) {
    ts := context.temporary_storage;
    free_pages_down_to(ts, state.top_overflow_page);

    if state.top_overflow_page {
        page := state.top_overflow_page;
        ts.data = (cast(*u8) page) + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
        ts.size = page.size;
        assert(page.size >= 0);
    } else {
        ts.data = ts.original_data;
        ts.size = ts.original_size;
        assert(ts.overflow_pages == null);
    }

    ts.occupied = state.occupied;
}

reset_temporary_storage :: () {
    ts := context.temporary_storage;
    ts.data = ts.original_data;
    ts.size = ts.original_size;
    ts.occupied = 0;
    ts.high_water_mark = 0;

    // @Speed: Maybe we should keep the allocated pages on the side,
    // rather than freeing them every frame. It probably would not
    // add much complexity here.
    free_pages_down_to(ts, null);
}

auto_release_temp :: () #expand {
    __mark := get_temporary_storage_mark();
    `defer set_temporary_storage_mark(__mark);
}



decode_relative_pointer :: (relative_pointer_size: s32, address: *void) -> (pointer: *void, offset: s64) {
    offset: s64;
    if relative_pointer_size == {
      case 1;
        ival := << cast(*s8) address;
        if ival  offset = ival ^ 0x80;
        else return null, 0;
        
      case 2;
        ival := << cast(*s16) address;
        if ival  offset = ival ^ 0x8000;
        else return null, 0;

      case 4;
        ival := << cast(*s32) address;
        if ival  offset = ival ^ 0x80000000;
        else return null, 0;

      case 8;
        ival := << cast(*s64) address;
        if ival  offset = ival ^ 0x8000000000000000;
        else return null, 0;

      case;
        assert(false);
    }

    pointer := cast(*u8)address + offset;
    return pointer, offset;
}

write_relative_pointer :: ($type: Type, pointer_address: *void, target_address: *void) {
    size := size_of(type);
    ival: type;
    
    if target_address {
        if size == {
          case 1;
            ival = cast(type)(target_address - pointer_address) ^ 0x80;
            
          case 2;
            ival = cast(type)(target_address - pointer_address) ^ 0x8000;

          case 4;
            ival = cast(type)(target_address - pointer_address) ^ 0x8000_0000;

          case 8;
            ival = cast(type)(target_address - pointer_address) ^ 0x8000_0000_0000_0000;

          case;
            assert(false);
        }
    }
    
    << cast(*type) pointer_address = ival;
}

Construct :: (memory: *void, $T: Type) {
    ini :: initializer_of(T);

    #if ini {
        inline ini(memory);
    } else {
        memset(memory, 0, size_of(T));
    }
}

New :: ($T: Type, $initialized := true, allocator := context.allocator, allocator_data := context.allocator_data) -> *T {
    memory := alloc(size_of(T), allocator, allocator_data);

    #if initialized {
        ini :: initializer_of(T);

        #if ini {
            inline ini(memory);
        } else {
            memset(memory, 0, size_of(T));
        }
    }
    
    return cast(*T) memory;
}

NewArray :: (count: s64, $T: Type, $initialized := true, allocator := context.allocator, allocator_data := context.allocator_data) -> [] T {
    // NewArray is for when we want to new a not-known-at-compile-time
    // number of things...

    // @Temporary: This overload of alloc returns *T, not *void, but the other one returns *void... we are casting it so that we don't get confused.  :VeryBadAllocWith
    memory := cast(*void) alloc(size_of(T) * count, allocator, allocator_data);

    result: [] T = ---;
    result.count = count;
    result.data  = memory;

    #if initialized {
        ini :: initializer_of(T);

        #if ini {
            for 0..count-1 {
                inline ini(memory);
                memory += size_of(T);
            }
        } else {
            memset(memory, 0, count * size_of(T));
        }
    }
    
    return result;
}

#if OS_WINDOWS {
    #load "windows.jai";
}

#if OS_LINUX {
    #load "linux.jai";
}

#if OS_MACOSX {
    #load "osx.jai";
}

#if OS_SWITCH {
    #load "switch.jai";
}

#scope_file
free_pages_down_to :: (ts: *Temporary_Storage, page: *ts.Overflow_Page) {
    cursor := ts.overflow_pages;
    while cursor != page {
        if !cursor {
            logprint("Temporary_Storage", "Error: Attempt to free down to page %, but that page was not found! This is probably an error in using set_temporary_storage_mark, or a general memory corruption.\n", page);
            ts.overflow_pages = null;
            return;
        }
        
        next := cursor.next;
        free(cursor, cursor.allocator, cursor.allocator_data);
        cursor = next;
    }

    ts.overflow_pages = page;
}

ALIGNED_OVERFLOW_PAGE_ALLOCATION :: 32; 
add_new_page :: (ts: *Temporary_Storage, minimum_size: s64) -> bool {
    #assert(size_of(Temporary_Storage.Overflow_Page) <= ALIGNED_OVERFLOW_PAGE_ALLOCATION);

    data_size : s64 = ts.original_size - ALIGNED_OVERFLOW_PAGE_ALLOCATION;
    if data_size < minimum_size  data_size = minimum_size;
    
    size_including_header := data_size + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
    
    // It's legal for overflow_allocator to be null, in which case
    // we do whatever alloc does.
    allocator      := ts.overflow_allocator;
    allocator_data := ts.overflow_allocator_data;
    
    memory := alloc(size_including_header, allocator, allocator_data);
    if !memory {
        logprint("Temporary_Storage", "Failed to allocate % bytes for a Temporary_Storage overflow page.\n", size_including_header);
        return false;  // This is going to be bad!
    }
    
    page := cast(*ts.Overflow_Page) memory;
    page.next           = ts.overflow_pages;
    page.allocator      = allocator;
    page.allocator_data = allocator_data;
    page.size           = data_size;

    ts.overflow_pages = page;
    
    ts.data = memory + ALIGNED_OVERFLOW_PAGE_ALLOCATION;
    ts.size = data_size;
    ts.occupied = 0;
    assert(ts.size >= 0);
    
    return true;
}
    

#scope_export

// pack_stack_trace is convenient in case you want to store the stack trace
// on a data structure. You can't just store a pointer to context.stack_trace,
// because that data will be destroyed as the stack unwinds. So this routine
// copies that trace into a packed array.
pack_stack_trace :: () -> [] Stack_Trace_Node {
    result: [..] Stack_Trace_Node;

    node := context.stack_trace;
    while node {
        array_add(*result, << node);
        node = node.next;
    }

    // Fix up the 'next' pointers so you can use them normally.
    for * result {
        if it.next   // The one that was already null, at the end, leave it null. Otherwise:
            it.next = it + 1;  // Set 'next' to point at the subsequent element in the array.
    }
    
    return result;
}

// This function is kind of silly and should probably get removed? I dunno.
log :: (ident: string, message: string, mode: Log_Mode = Log_Mode.EVERYDAY) {
    context.logger(ident, message, mode, context.logger_data);
}
