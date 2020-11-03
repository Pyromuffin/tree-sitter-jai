#import "Basic";
#import "Random";

//
// The #insert directive lets you insert compile-time-generated code, 
// or code that has been represented as data in some other way.
//
// You can represent the code either as a string or as the syntax tree nodes
// that are defined in modules/Compiler/Compiler.jai (the same nodes you
// would see when watching your program from a metaprogram).
//
// #insert takes a single argument, like this:
//

some_procedure :: () {
    x := 3;
    
    #insert "x *= x;";

    print("x is: %\n", x);

    // x will be 9 when printed!
}

// Above, we inserted some code, was represented as a string,
// that modified the original value of x.
//
// That looks pretty dumb, and in this case there was no reason
// not to just put the x *= x in there directly. But the nice
// thing about #insert is that you can generate the strings
// dynamically. Here's a slightly-less-useless example:

bookender :: ($preamble: string, $body: string, $postamble: string, n: int) {
    // preamble, body, and postamble are known at compile-time because of the $s,
    // so we can #insert them. This leaves us with just n, which tells us how much
    // to loop. 
    #insert preamble;

    for 1..n {
        #insert body;
    }

    #insert postamble;
}


bookender_example :: () {
    // When inserting code, it is often nice to use #string so you don't have to worry too much
    // about escaping quotes and backslashes and whatever else.
    
    preamble :: #string DONE
        counter := 0;
        print("We are about to begin!\n");
    DONE

    body :: #string DONE
        print("    ... one iteration! Incrementing!\n");
        counter += 1;
    DONE
    
    postamble :: #string DONE
        print("We are done! counter is: %.\n", counter);
    DONE


    bookender(preamble, body, postamble, 5);

    // Let's re-use the same preamble and postamble, but
    // a different body.

    other_body :: #string DONE 
        print("    ... iteration? Squaring and adding 1!\n");
        counter = (counter * counter) + 1;
    DONE
    
    bookender(preamble, other_body, postamble, 7);
    
}


// #insert works inside struct definitions, and even inside
// the global scope if you want to put it there. Here we can
// make a struct that generates default values for its array,
// and those values go into the struct's initializer:

generate_assignments :: (name: string, N: int) -> string {
    builder: String_Builder;  // We will use this to concatenate a potentially big string.
    defer free_buffers(*builder);

    for 0..N-1 {
        print_to_builder(*builder, "%[%] = %;\n", name, it, xx (it*it));
    }

    result := builder_to_string(*builder);

    print("generate_assignments('%', %) outputted this:\n%\n", name, N, result);

    return result;
}

Holder :: struct (N: int) {
    floats: [N] float;

    #insert #run generate_assignments("floats", N);
}


holder_example :: () {
    holder: Holder(5);

    for 0..holder.N-1 {
        print("holder.floats[%] == %\n", it, holder.floats[it]);
    }

    // Instead of generating float assignments for a Holder,
    // let's use the same generator here to make an array of a different length
    // in this procedure, on the stack, and it has a different name and a
    // different type! generate_assigments uses an auto-cast, so we
    // can pass integers, or whatever!

    ITEMS :: 7;
    ting_tanglers: [ITEMS] u16;

    #insert #run generate_assignments("ting_tanglers", ITEMS);

    for 0..ITEMS-1 {
        print("ting_tanglers[%] == %\n", it, ting_tanglers[it]);
    }
}


//
// That seems like a funky example, but here's a more-applicable one
// that is schematically just like Holder above: We can make an
// N-dimensional square matrix whose default value is the identity.
// Note that this matrix does not have a 'constructor' as you'd have
// in a language like C++; the elements just get written in its initializer,
// which does not require code to be run at runtime. (The matrix's default
// value is representable in static readonly memory, and any instance
// of the matrix can be initialized with a single memcpy, for example.)
//
Matrix :: struct (N: int) {
    elements: [N*N] float;          // These will be initialized to 0.

    #insert #run set_diagonals_to_1(N);  // Setting diagonal elements to 1 makes this the identity matrix.
}

set_diagonals_to_1 :: (N: int) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);

    for 0..N-1 {
        print_to_builder(*builder, "elements[%] = 1;\n", it*N+it);
    }

    return builder_to_string(*builder);
}

matrix_example :: () {
    m: Matrix(5);

    print("The matrix contains:\n");
    for j: 0..4 {
        for i: 0..4 {
            print("%  ", m.elements[j*5+i]);
        }

        print("\n");
    }
}


// So far we have been using #insert in structs just to set values,
// but you can do some pretty wacky stuff. Here we'll generate a struct type
// just given an array of types and names:

Container :: struct (s: string) {
    #insert s;  // Whatever we pass as s is the body of the struct ... and that's all!
}

Name_And_Type :: struct {  // This is going to hold the bindings we want to use to make a struct.
    name: string;
    type: Type;
}

container_example :: () {
    make_bindings :: (array: [] Name_And_Type) -> string {
        builder: String_Builder;
        defer free_buffers(*builder);

        for array  print_to_builder(*builder, "%: %;\n", it.name, it.type);
        
        return builder_to_string(*builder);
    }
    
        
    fill_array :: () -> [] Name_And_Type {
        array: [..] Name_And_Type;

        x := array_add(*array);
        x.name = "hello";
        x.type = string;

        x = array_add(*array);
        x.name = "sailor";
        x.type = float;

        x = array_add(*array);
        x.name = "whatever";
        x.type = *[17] **void;
        
        return array;
    }

    string_1  :: #run make_bindings(fill_array());
    container_1: Container(string_1);

    print("container_1 is: %\n", container_1);

    // Since these are strings, we can goof around;
    // for example, let's change each name so that they
    // are capitalized, except for 'e' and 'o':

    string_2  :: #run make_bindings(kinda_capitalize(fill_array()));
    container_2: Container(string_2);

    print("container_2 is: %\n", container_2);


    kinda_capitalize :: (a: [] Name_And_Type) -> [] Name_And_Type {
        for * a {
            it.name = kinda_capitalize(it.name);
        }

        return a;
        
        kinda_capitalize :: (s: string) -> string {
            t := copy_string(s);

            for i: 0..t.count-1 {
                c := t[i];
                if c == #char "o" continue;
                if c == #char "e" continue;

                if (c >= #char "a") && (c <= #char "z") {
                    c -= 32;  // Lower-case!
                }

                t[i] = c;
            }

            return t;
        }
    }
}


// #insert's argument has to be known to the compiler at compile-time!
// You can't #insert code at runtime, because this is a statically-typed
// language where all code is resolved at compile-time.

// Uncommenting the following procedure will generate an error, because
// it's trying to insert a runtime argument. (Try it!)

/*
uncomment_me :: (s: string) {
    #insert s;
}
*/



// #insert can operate on Code that is already represented as a tree,
// in memory -- in the same format that you see the code from the
// message loop of a metaprogram. Not quite all the features are in place
// for easy manipulation of the Code type, but it's coming soon.

// Here we use a macro to do some code N times, with the majority of the
// executions of the Code argument happening in an unrolled body, 
// to minimize loop overhead:

loop_unroll :: (n: int, code: Code) #expand {
    UNROLL_SIZE :: 4;

    big_loops   := n / UNROLL_SIZE;
    small_loops := n % UNROLL_SIZE;

    print("[unroll]:\n");
    for 1..big_loops {
        // We just paste the code in 4 times, so that we have no overhead between the iterations.
        #insert code;
        #insert code;
        #insert code;
        #insert code;
    }

    print("[remainder]:\n");
    for 1..small_loops {
        #insert code;
    }
}

unroll_example :: () {
    x := 3;
    loop_unroll(9, #code { x += 1; print("x is now %.\n", x); });
}


// Show #insert in polymorphic structs and procedures.


// So far, we've just been using #insert at the statement level,
// but you can use it at the expression level also:

expression_inserts :: () {
    a :: "factorial(7);";  // But the expression has to parse with a semicolon as a statement on its own; this is kinda a weird thing that we will probably change.

    x := 1 - #insert a;
    print("x = %\n", x);

    factorial :: (n: int) -> int {
        if n <= 1 return 1;
        return n * factorial(n-1);
    }


    // I heard you like #insert, so I put an #insert in your #insert:

    b :: "factorial(#insert argument);";

    argument :: "5;";

    x = 1 + #insert b;

    print("x = %\n", x);
}

multi_line_inserts :: () {
    // When using #insert at a statement level, you can insert strings that contain
    // several statements, as we did above.

    // But when you try to use #insert as an expression, only one expression can be
    // in the string (otherwise, where would the other ones go?), and that expression
    // has to be a thing that you could normally use as an expression.
    
    // We can insert a string containing multiple statements:
    multi_string :: "a := 7; b := 5;";
    #insert multi_string;

    print("a is %, b is %\n", a, b);

    // But you can't #insert multiple statements at an expression level:
    multi_expression :: "7; 3; 5;";

    // If you uncomment the assignment below, it is an error. 
    // x := #insert multi_expression;
    // print("x is: %\n", x);

    // Neither can you #insert a non-expression as an expression.
    // For example:

    decl :: "y := 123.4;";

    // We can insert decl at statement level as usual:

    #insert decl;
    print("y is: %\n", y);

    // ... but, if you uncomment this assignment to z, it is an error!
    // z := 1 + #insert decl;
}

main :: () {
    print("\n");

    some_procedure();

    print("\n");

    bookender_example();

    print("\n");

    holder_example();

    print("\n");

    matrix_example();

    print("\n");
    
    container_example();

    print("\n");
    
    unroll_example();

    print("\n");

    expression_inserts();

    print("\n");

    multi_line_inserts();
}

