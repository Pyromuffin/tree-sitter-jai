#scope_file
// @Incomplete: We would like to be able to print stuff without having to take an import dependency on
// stb_sprintf (since this is included in Basic!!!) We are only using stb_sprintf for printing out
// floating point numbers; should be able to replace that pretty easily with our own.
// (I wrote one for float32 that mostly does the job a while back, but we can probably just use Jeff's.).
//         -jblow, 28 January 2019

#import "stb_sprintf";
#scope_export


/*

@Incomplete:

When we have namespaces, we want this module to create a namespace
into which users can poke their own procedures for printing data types.
This takes the place of the old 'print_me' functionality which is
now commented out.  :PrintMe

*/

Printer :: #type (builder: *String_Builder, any: Any, expansion: *Formatter) -> void;

Formatter :: struct {
    value   : Any;
    printer : Printer;

    silently_set_new_default := false;
}

FormatInt :: struct {
    using formatter : Formatter;

    base := 10;
    minimum_digits := -1;
}

FormatFloat :: struct {
    using formatter : Formatter;

    width := -1;
    trailing_width := -1;
    using mode : enum { Decimal; Scientific; Shortest; };
}

FormatStruct :: struct {
    using formatter : Formatter;

    use_newlines_if_more_than_this_many_members := -1;  // -1 means never use newlines. 0 would mean always use newlines (for structs with a nonzero number of members!).
}

formatInt :: (value : Any, base := 10, printer := null, silently_set_new_default := false, minimum_digits := -1) -> FormatInt {
    result : FormatInt;

    result.value = value;
    result.base = base;
    result.printer = printer;
    result.silently_set_new_default = silently_set_new_default;
    result.minimum_digits = minimum_digits;

    return result;
}

formatFloat :: (value : Any, width := -1, trailing_width := -1, printer := null, mode := FormatFloat.Decimal) -> FormatFloat {
    result : FormatFloat;

    result.value = value;
    result.printer = printer;
    result.width = width;
    result.trailing_width = trailing_width;
    result.mode = mode;

    return result;
}

formatStruct :: (value: Any, use_newlines_if_more_than_this_many_members := -1, printer: Printer = null) -> FormatStruct {
    result: FormatStruct;
    result.value = value;
    result.use_newlines_if_more_than_this_many_members = use_newlines_if_more_than_this_many_members;
    result.printer = printer;
    
    return result;
}

//#scope_file

/*
buffer_to_string_without_copy :: (using builder: String_Builder) -> string {
    bytes := base_buffer.occupied;
    for allocated_extra_buffers  bytes += it.occupied;
    
    assert(occupied < SIZE);

    result : string;
    result.data  = data.data;
    result.count = occupied;

    return result;
}
*/

get_s64_from_void_pointer :: (pointer: *void, size_in_bytes: int) -> s64 {
    if size_in_bytes == 8 return <<cast(*s64) pointer;
    if size_in_bytes == 4 return <<cast(*s32) pointer;
    if size_in_bytes == 2 return <<cast(*s16) pointer;
    if size_in_bytes == 1 return <<cast(*s8)  pointer;

    assert(false);

    return 0;
}

get_u64_from_void_pointer :: (pointer: *void, size_in_bytes: int) -> u64 {
    if size_in_bytes == 8 return <<cast(*u64) pointer;
    if size_in_bytes == 4 return <<cast(*u32) pointer;
    if size_in_bytes == 2 return <<cast(*u16) pointer;
    if size_in_bytes == 1 return <<cast(*u8)  pointer;

    assert(false);

    return 0;
}



print_u64_base_n :: (builder: *String_Builder, v: u64, format: FormatInt) {
    base_64_characters :: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_.";
    
    base := cast(u64) format.base;
    assert(base >=  2);
    assert(base <= 64);

    MAX_OUTPUT_LENGTH :: 64;

    digits := format.minimum_digits;

    if digits > MAX_OUTPUT_LENGTH digits = MAX_OUTPUT_LENGTH;
    if digits == 0 return;  // Do not print anything!


    output : [MAX_OUTPUT_LENGTH] u8;
    
    end := output.data + MAX_OUTPUT_LENGTH;
    p   := end;

    while v || (digits > 0) {
        place := v % base;
        v     =  v / base;

        p -= 1;
        << p  = base_64_characters[place];

        digits -= 1;
    }

    if (p == end) && ((digits > 0) || (digits == -1)) {
        p -= 1;
        << p = #char "0";
    }

    assert(p >= output.data);

    append(builder, p, end - p);
}

print_float :: (builder : *String_Builder, format : FormatFloat) {
    info := cast(*Type_Info_Float) format.value.type;
    assert(info.type == Type_Info_Tag.FLOAT);

    // Printing floats is kind of hard, so initially we are going to punt
    // and call out to printf.
    

    // Build the format string.

    format_string: [32] u8;
    p := format_string.data;

    << p = #char "%";
    p += 1;
 
    if format.width != -1           p += stbsp_sprintf(p, "%d", format.width);
    if format.trailing_width != -1  p += stbsp_sprintf(p, ".%d", format.trailing_width);

    if #complete format.mode == {
        case FormatFloat.Decimal;   << p = #char "f";
        case FormatFloat.Scientific;<< p = #char "e";
        case FormatFloat.Shortest;  << p = #char "g";
    }

    p += 1;
    << p = 0;


//    printf("format_string is %s\n", format_string);

    output: [1024] u8;  // Overkill.
    if info.runtime_size == 8 {
        f := << cast(*float64) format.value.value_pointer;
        stbsp_sprintf(output.data, xx format_string.data, f);
    } else {
        f := << cast(*float32) format.value.value_pointer;
        stbsp_sprintf(output.data, xx format_string.data, f);
    }


    str_length :: (x: *u8) -> int @pure {  // Copied from String.jai to avoid dependency.
        assert(x != null);

        p := x;
        while << p  { p += 1; }
        return p - x;
    }

    // @Cleanup @Speed: Does stb_sprintf (or whatever we use instead) tell us the
    // number of bytes it wrote? If so we don't need str_length here.
    append(builder, output.data, str_length(output.data));
}


print_integer :: (builder : *String_Builder, format : FormatInt) {
    any := format.value;
    assert(any.type.type == Type_Info_Tag.INTEGER);

    info := cast(*Type_Info_Integer) any.type;

    v : u64 = ---;

    if format.base == 10 {
        if info.signed {
            v_signed := get_s64_from_void_pointer(any.value_pointer, info.runtime_size);

            if v_signed < 0 {
                append(builder, "-");
                v = cast(u64) -v_signed;
            } else {
                v = cast(u64)  v_signed;
            }
        } else {
            v = get_u64_from_void_pointer(any.value_pointer, info.runtime_size);
        }
    } else {
        v = get_u64_from_void_pointer(any.value_pointer, info.runtime_size);
    }

    print_u64_base_n(builder, v, format);
}

// The print routines return bytes_printed, but it is probably
// more useful for everyone involved to return utf8_characters_printed??
// Hmmm.  -jblow, 8 September 2015

print_sequence :: (args: .. Any) -> bytes_printed: s64 { 
    builder: String_Builder;
    defer free_buffers(*builder);

    print_sequence_to_builder(*builder, ..args);

    written := write_builder(*builder);
    return written;
}

sprint_sequence :: (args: .. Any) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_sequence_to_builder(*builder, ..args);

    return builder_to_string(*builder);
}

#scope_export

print_character :: (_c: u8) {
    // A ridiculous way of printing a character.
    c := _c;
    s: string;
    s.data = *c;
    s.count = 1;
    write_string(s);
}

print :: (format_string: string, args: .. Any) -> bytes_printed: s64 { 
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);
    written := write_builder(*builder);

    return written;
} @PrintLike

/*
print_single_byte_character :: (character: s64) {
    // @Wasteful!!

    builder: String_Builder;

    c := cast(u8) character;

    builder.data[0] = c;
    builder.occupied = 1;

    write_builder(*builder);
}
*/

sprint :: (format_string: string, args: .. Any) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);

    return builder_to_string(*builder);
} @PrintLike

tprint :: (format_string: string, args: .. Any) -> string {
    builder: String_Builder;
    builder.allocator = __temporary_allocator;
    defer free_buffers(*builder);
    
    print_to_builder(*builder, format_string, ..args);

    return builder_to_string(*builder, __temporary_allocator, null);
} @PrintLike

// This prints a string using the temporary allocator, and appends a zero at the end.
tprintz :: (format_string: string, args: .. Any) -> string {
    builder: String_Builder;
    builder.allocator = __temporary_allocator;
    defer free_buffers(*builder);
    
    print_to_builder(*builder, format_string, ..args);
    append(*builder, "\0");

    return builder_to_string(*builder, __temporary_allocator);
} @PrintLike


logprint :: (ident: string, mode: Log_Mode, format_string: string, args: .. Any) {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);

    s := builder_to_string(*builder, __temporary_allocator);
    if !s.count return;

    context.logger(s, ident, mode, context.logger_data);
} @PrintLike


logprint :: (ident: string, format_string: string, args: .. Any) {
    logprint(ident, Log_Mode.EVERYDAY, format_string, ..args);
} @PrintLike


// Ugh, I never use logprint I guess because I don't want to think about it,
// so how about if I make a log_print that works just like print,
// and we'll see if I use it. If we made it so that we can take optional
// arguments after the varargs, we could even supply 'ident' and 'mode'
// and it would be fine, hmm...
//
//   -jblow, 8 June 2016
//
log_print :: (format_string: string, args: .. Any) {

    ident := "";
    mode := Log_Mode.EVERYDAY;

    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);
    s := builder_to_string(*builder, __temporary_allocator);
    if !s.count return;

    context.logger(s, ident, mode, context.logger_data);
} @PrintLike


// Put this in file scope?
append_struct_info :: (builder: *String_Builder, info: *Type_Info_Struct, base_pointer: *void, format : *FormatStruct = null) {
    if info.name then {
        append(builder, info.name);
        append(builder, " { ");
    } else {
        append(builder, "struct {");
    }

    using Type_Info_Tag;

    highest_offset := -1;  // We use this to skip unioned things, to reduce printout size. Maybe this is not the right policy for data structures in general. -jblow, 22 March 2017

    use_newlines := false;
    newline_limit := 4;
    if format {
        newline_limit = format.use_newlines_if_more_than_this_many_members;
    }

    if newline_limit >= 0 {
        use_newlines = (info.members.count > newline_limit);
    }
    
    if use_newlines append(builder, "\n");
    
    for info.members {
        // For now, don't draw constant members, since you are probably using this for
        // debugging and that can be spammy when you declare lots of constants (and it
        // adds no information usually!)   -jblow, 10 September 2015

        // ... Similarly for imported, since we usually just imported
        // stuff from the base class that we already printed or are
        // about to print.
        
        if it.flags & it.CONSTANT continue;
        if it.flags & it.IMPORTED continue;

        if it.offset_in_bytes < highest_offset continue;
        if it.type.runtime_size == 0  continue;  // Skip 'void' elements, as these can't hold values.
        highest_offset = it.offset_in_bytes + it.type.runtime_size;

        if use_newlines  append(builder, "    "); // @Incomplete: Control indentation string, track depth of struct nesting.
        append(builder, it.name);
        append(builder, " = ");

        address := (cast(*u8) base_pointer) + it.offset_in_bytes;

        any : Any;
        any.type = it.type;
        any.value_pointer = address;

        if it.type.type == FLOAT {
            string_heads_match :: (a: string, b: string) -> bool {
                if b.count < a.count return false;

                for i : 0..a.count-1 {
                    if a[i] != b[i] then return false;
                }

                return true;
            }

            precision := -1;
            for note : it.notes {
                head := "print_precision";

                if string_heads_match(head, note) {
                    post, value := parse_number(note, head.count);

                    precision = value;
                }
            }

            // @Cleanup: We might want a more-convenient way to 
            // do these notes without overriding print_item_to_builder
            // completely.

            format : FormatFloat;
            format.trailing_width = precision;
            format.value = any;

            print_float(builder, format);
        } else if it.type.type == STRING {
            // Print the string in quotes, escaping any characters.
            // A little slow for now.

            quote : u8 = #char "\"";
            append(builder, *quote, 1);
            
            {
                s := get_full_sized_string(any);
                for 0..s.count-1 {
                    c := s[it];
                    if c == 10 {
                        append(builder, "\\n".data, 2);
                    } else {
                        append(builder, *c, 1);
                    }
                }
            }

            append(builder, *quote, 1);
        } else {
            print_item_to_builder(builder, any);
        }

        if use_newlines {
            append(builder, "\n");
        } else {
            append(builder, "; ");
        }
    }

    append(builder, "}");
}

append_relative_pointer_size :: (builder: *String_Builder, size: int) {
    if size == {
      case 0;
      case 1;
        append(builder, "~s8 ");
      case 2;
        append(builder, "~s16 ");
      case 4;
        append(builder, "~s32 ");
      case 8;
        append(builder, "~s64 ");
      case;
        append(builder, "~?? ");
    }
}

print_type_to_builder :: (builder: *String_Builder, info: *Type_Info) {
    using Type_Info_Tag;

    if info.type == STRUCT {
        info_struct := cast(*Type_Info_Struct) info;
        if info_struct.name {
            append(builder, info_struct.name);
        } else {
            if info_struct.struct_flags & Struct_Flags.UNION {
                append(builder, "(anonymous union)");
            } else {
                append(builder, "(anonymous struct)");
            }
        }
    } else if info.type == POINTER {
        info_pointer := cast(*Type_Info_Pointer) info;
        append(builder, "*");
        if info_pointer.relative_pointer_size append_relative_pointer_size(builder, info_pointer.relative_pointer_size);
        print_type_to_builder(builder, info_pointer.pointer_to);
    } else if info.type == ARRAY {
        info_array := cast(*Type_Info_Array) info;

        if info_array.array_type == Type_Info_Array.FIXED {
            append(builder, "[");
            print_item_to_builder(builder, info_array.array_count);
            append(builder, "] ");
        } else if info_array.array_type == Type_Info_Array.VIEW {
            append(builder, "[] ");
        } else if info_array.array_type == Type_Info_Array.RESIZABLE {
            append(builder, "[..] ");
        } else {
            assert(false);
        }

        print_type_to_builder(builder, info_array.element_type);
    } else if info.type == TYPE {
        append(builder, "Type");
    } else if info.type == ENUM {
        info_enum := cast(*Type_Info_Enum)(info);
        if info_enum.name {
            append(builder, info_enum.name);
        } else {
            append(builder, "(anonymous enum)");
        }
    } else if info.type == STRING {
        info_string := cast(*Type_Info_String)(info);
        append(builder, "string");
        if info_string.relative_pointer_size {
            append_relative_pointer_size(builder, info_string.relative_pointer_size);
        }
    } else if info.type == PROCEDURE {
        append(builder, "(procedure)");
    } else if info.type == CODE {  // @redundant with other "code" in here... !
        append(builder, "Code");
    } else {
        element_type := "";
        
        // Quick hack!
        if info == type_info(u8)   element_type = "u8";
        if info == type_info(u16)  element_type = "u16";
        if info == type_info(u32)  element_type = "u32";
        if info == type_info(u64)  element_type = "u64";
        if info == type_info(s8)   element_type = "s8";
        if info == type_info(s16)  element_type = "s16";
        if info == type_info(s32)  element_type = "s32";
        if info == type_info(s64)  element_type = "s64";
        else if info == type_info(int)  element_type = "int";    // Currently 's64' and 'int' are the same, so we will never print 'int'.
        if info == type_info(float)    element_type = "float";
        if info == type_info(float32)  element_type = "float32";
        if info == type_info(float64)  element_type = "float64";
        if info == type_info(bool)     element_type = "bool";
        if info == type_info(void)     element_type = "void";

        if element_type {
            append(builder, element_type);
        } else {
            append(builder, "(some type)");
        }
    }
}

print_item_to_builder :: (builder: *String_Builder, it: Any, default_formatters: *[] *Formatter = null) {
    using Type_Info_Tag;

    t := it.type.type;

    default_formatter : *Formatter;
    if default_formatters && (t < xx HIGHEST_TAG) {
        default_formatter = (<< default_formatters)[t];
    }

    if t == {
      case STRING;
        s := get_full_sized_string(it);
        append(builder, s);

      case BOOL;
        b := << cast(*bool) it.value_pointer;
        if b {
            append(builder, "true");
        } else {
            append(builder, "false");
        }

      case INTEGER;
        if default_formatter {
            default_formatter.value = it;
            print_integer(builder, << cast(*FormatInt) default_formatter);
        } else {
            default : FormatInt;
            default.value = it;
            print_integer(builder, default);
        }

      case FLOAT;
        if default_formatter {
            default_formatter.value = it;
            print_float(builder, << cast(*FormatFloat) default_formatter);
        } else {
            default : FormatFloat;
            default.value = it;
            print_float(builder, default);
        }

      case POINTER;
        pt := cast(*Type_Info_Pointer)(it.type);

        if pt.relative_pointer_size {
            pointer, offset := decode_relative_pointer(cast(s32) pt.runtime_size, it.value_pointer);
            if pointer  print_to_builder(builder, "r% (%)", offset, pointer);
            else        append   (builder, "r null");
        } else {
            u64_val := << cast(*u64) it.value_pointer;
            default : FormatInt;
            default.value = u64_val;
            default.base = 16;
            print_integer(builder, default);
        }

      case STRUCT;
        info_struct := cast(*Type_Info_Struct) it.type;
        expansion := isFormatter(info_struct);

        if expansion {
            expander := cast(*Formatter) it.value_pointer;

            // If it's a silent default-setter, set the new default pointer, then bail.

            if expander.silently_set_new_default {
                if default_formatters {
                    index := expander.value.type.type;
                    (<< default_formatters)[index] = expander;
                    return;
                }
            }

            if it.type == type_info(FormatInt) {
                format := << cast(*FormatInt) it.value_pointer;
                print_integer(builder, format);
                return;
            } else if it.type == type_info(FormatFloat) {
                format := << cast(*FormatFloat) it.value_pointer;
                print_float(builder, format);
                return;
            } else if it.type == type_info(FormatStruct) {
                format := cast(*FormatStruct) it.value_pointer;

                new_info_struct := cast(*Type_Info_Struct) format.value.type;
                value_pointer := format.value.value_pointer;
                if format.value.type.type == POINTER {  // We let people wrap a pointer to a struct, since often that's what you'll have...
                    tip := cast(*Type_Info_Pointer)format.value.type;
                    if tip.pointer_to.type == STRUCT {
                        new_info_struct = cast(*Type_Info_Struct) tip.pointer_to;
                        value_pointer = << cast(**void) format.value.value_pointer;
                    }
                }
                
                if new_info_struct.type == STRUCT {
                    if format.printer {
                        any: Any = ---;
                        any.type = new_info_struct;
                        any.value_pointer = value_pointer;
                        format.printer(builder, any, format);
                    } else {
                        append_struct_info(builder, new_info_struct, value_pointer, format);
                    }
                    return;
                } else {
                    context.logger("Error: Attempt to pass a non-struct inside a FormatStruct.\n", "print", Log_Mode.MINIMAL, context.logger_data);
                    append(builder, "error");
                    return;
                }
            }
        }


        printer : Printer;

        if expansion {
            expander := cast(*Formatter) it.value_pointer;

            // Look for a printer and then recurse, printing our value.

            printer = expander.printer;
            // :PrintMe  if !printer  printer = get_printer(expander.value.type);

            if printer printer(builder, expander.value, expander);
        } else {
            // :PrintMe printer = get_printer(it.type);
            if printer printer(builder, it, null);
        }

        if !printer {
            append_struct_info(builder, info_struct, it.value_pointer);
        }

      case ARRAY;
        info_array := cast(*Type_Info_Array) it.type;
        
        print_type_to_builder(builder, *info_array.info); // @Cast

        if info_array.array_type == Type_Info_Array.VIEW {
            size : s32 = 8;
            if info_array.relative_pointer_size  size = info_array.relative_pointer_size;
            append(builder, " { count = ");
            print_item_to_builder(builder, get_int_of_size(it.value_pointer, size));
            append(builder, ", data = 0x");

            if info_array.relative_pointer_size {
                print_item_to_builder(builder, decode_relative_pointer(size, it.value_pointer + size));
            } else {
                print_item_to_builder(builder, get_int_of_size(it.value_pointer + 8, size)); // size is just 8 here.
            }
            
            append(builder, " }");
        } else if info_array.array_type == Type_Info_Array.RESIZABLE {
            array := cast(*Resizable_Array) it.value_pointer;
            append(builder, " { count = ");
            print_item_to_builder(builder, array.count);
            append(builder, ", data = 0x");
            print_item_to_builder(builder, array.data);
            append(builder, ", allocated = ");
            print_item_to_builder(builder, array.allocated);
            append(builder, ", allocator = ");
            print_item_to_builder(builder, array.allocator);
            append(builder, " }");
        }

      case PROCEDURE;
        pv := << cast(**void) it.value_pointer;  // @Hack

        if pv {
            append(builder, "procedure 0x");

            print_item_to_builder(builder, pv);
            // append(builder, ")");
        } else {
            append(builder, "null");
        }

      case ENUM;
        // Kind of ugly, but let's go for it.

        info_enum := cast(*Type_Info_Enum) it.type;
        info_int  := cast(*Type_Info_Integer) info_enum.internal_type;
        assert(info_int.type == INTEGER);
        
        size := info_int.runtime_size;

        target_value : s64 = ---;
        if size == 8 {
            target_value = << cast(*s64) it.value_pointer;
        } else if size == 4 {
            target_value = << cast(*s32) it.value_pointer;
        } else if size == 2 {
            target_value = << cast(*s16) it.value_pointer;
        } else if size == 1 {
            target_value = << cast(*s8) it.value_pointer;
        }

        if info_enum.is_flags {
            if target_value == 0 {
                append(builder, "0");
                return;
            }

            // I felt like doing this in unsigned for some reason!
            flags_total   := cast(u64) target_value;
            flags_printed : u64 = 0;

            first := true;
            for info_enum.values {
                value := cast(u64) it;
                matching := flags_total & value;

                if !matching continue;
                if !(matching & ~flags_printed) continue;

                flags_printed |= matching;

                if !first  append(builder, " | ");
                append(builder, info_enum.names[it_index]);
                first = false;
            }

            unmatched := flags_total & ~flags_printed;
            if unmatched {
                if !first  append(builder, " | 0x");
                format: FormatInt;  // Dummy.
                print_u64_base_n(builder, unmatched, format);
            }
        } else {
            assert(info_enum.names.count == info_enum.values.count);
            
            for info_enum.values {
                if target_value == it {
                    append(builder, info_enum.names[it_index]);
                    return;
                }
            }

            // If zero, we may not have matched any values, but
            // let's not call that out of range!
            if target_value {
                append(builder, "(enum out of range: ");
                print_item_to_builder(builder, target_value);
                append(builder, ")");
            } else {
                print_item_to_builder(builder, target_value);
            }                
        }
    
      case TYPE;
        ti := << cast(**Type_Info) it.value_pointer;

        if ti {
            print_type_to_builder(builder, ti);
        } else {
            append(builder, "(null)");
        }

/*
        append(builder, "(Type, address ");

        default : FormatInt;
        default.base = 16;
        default.value = cast(s64) ti;
        print_integer(builder, default);

        append(builder, ")");
*/
    
      case VOID;
        append(builder, "void");

      case CODE;
        append(builder, "Code");

      case;
        // This is a type we don't know or don't yet handle.

        append(builder, "(corrupted type tag ");
        print_item_to_builder(builder, cast(int)t);
        append(builder, ")");
    }
}


is_digit :: (c: s64) -> bool {
    relative := c - #char "0";
    return (relative >= 0) && (relative <= 9);
}

// @Cleanup: Can use to_integer in Basic.jai now.
parse_number :: (s: string, cursor: s64) -> end_cursor: s64, sum: s64 {
    sum := 0;

    while cursor < s.count {
        c := s[cursor];
        if !is_digit(c) break;

        sum *= 10;
        sum += cast(int) c - #char "0";

        cursor += 1;
    }

    return cursor, sum;
}
            
HIGHEST_TAG :: #run enum_highest_value(Type_Info_Tag) + 1;

// @Cleanup: I don't like having multiple aliases for the same thing... ??? -jblow, 11 January // IC: Agreed. This was an experiment in using a naming convention closer to 'append'.
append_format :: print_to_builder;

print_to_builder :: (builder : *String_Builder, format_string : string, args: .. Any) -> bool {
    default_formatters : [HIGHEST_TAG] *Formatter;

    implicit_index_cursor := 0;
    
    cursor := 0;
    printed := 0;
    while cursor < format_string.count {
        c := format_string.data[cursor];

        if c != #char "%" {
            cursor += 1;
            continue;
        }

        append(builder, format_string.data + printed, cursor - printed);
        cursor += 1;  // Skip the %.

        value := implicit_index_cursor; // Will get bumped below.

        if cursor < format_string.count {
            next := format_string.data[cursor];
            if next == #char "%" {  // Double-percent means to actually output a percent.
                append(builder, "%");
                cursor += 1;
                printed = cursor;
                continue;
            }

            // If it's  digit, parse a number.
            if is_digit(next) {
                // @Robustness: We probably want to test that parse_number does not overflow!
                cursor, value = parse_number(format_string, cursor);
                value -= 1;
            }
        }


        if value < 0 {
            return false;  // @Incomplete: Give a reason. Maybe continue printing?
        }

        if value >= args.count {
            return false;  // @Incomplete: Give a reason. Maybe continue printing?
        }

        item := args[value];

        untyped : [] *Formatter = default_formatters; // Get around a casting problem when taking pointer.
        print_item_to_builder(builder, item, *untyped);
        implicit_index_cursor = value + 1;

        printed = cursor;   // Next time we append, start here.
    }

    append(builder, format_string.data + printed, cursor - printed);

    if builder.failed return false;
    return true;
}

print_sequence_to_builder :: (builder : *String_Builder, args: .. Any) { 
    for args {
        print_item_to_builder(builder, it);
    }
}

/* :PrintMe
get_printer :: (info : *Type_Info) -> Printer {
    if info.type != Type_Info_Tag.STRUCT return null;

    info_struct := cast(*Type_Info_Struct) info;

    field := get_field(info_struct, "print_me");
    if !field return null;

    offset := field.offset_into_constant_storage;
    if offset == -1 return null;

    function_pointer := cast(*Printer) (info_struct.constant_storage_buffer + offset);
    return <<function_pointer;
}
*/


isFormatter :: (info: *Type_Info_Struct) -> *Type_Info_Struct_Member {
    for * info.members {
        if it.type == type_info(Formatter) return it;
    }

    return null;
}


print_bytes :: (a: *void, length: int, format_string := "% ") {
    b := cast(*u8) a;
    for 0..length-1 {
        print(format_string, formatInt(b[it], base=16));
    }

    print("\n");
}

get_int_of_size :: (p: *void, size: s32) -> s64 {
    if size == {
      case 1;
        return << cast(*s8) p;
      case 2;
        return << cast(*s16) p;
      case 4;
        return << cast(*s32) p;
      case 8;
        return << cast(*s64) p;
      case;
        print("Error: size is %\n", size);
        assert(false);
    }

    return 0;  // @Temporary: Shut up @Incomplete control flow analysis.
}

#scope_file

get_full_sized_string :: (any: Any) -> string {
    assert(any.type.type == Type_Info_Tag.STRING);
    tis := cast(*Type_Info_String) any.type;

    if !tis.relative_pointer_size  return << cast(*string) any.value_pointer;

    size := tis.relative_pointer_size;
    
    s: string = ---;
    s.count = get_int_of_size(any.value_pointer, size);
    s.data  = decode_relative_pointer(size, any.value_pointer + size);
    return s;
}


