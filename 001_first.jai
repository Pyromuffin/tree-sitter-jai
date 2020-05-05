// You can import different modules to provide different functions.
// Here, "Basic" gives us a bunch of functionality, including the
// print function.

#import "Basic";
#import "System";

// Like in C++, everything after a //, until the end of the line,
// is a comment.
/*
  This is another form of comment, 

  that you can use

  if you don't want to have a //

  at the start of each line,

  or if you want to comment something mid-line.

 */


/*

    You can declare variables.
    The format for a declaration is:

    

    name : type = value;


 */


a_variable : float = 37.0;
zebra := 100;

/*

    Except, you don't need to provide both type and value.
    If you skip the value, you'll get a default value.
    If you skip the type, then the type will be inferred from the value.

    The type will always be known at compile-time.
    This is a strongly, statically-typed programming language.

 */

b_variable : float;    // b_variable will get a default value of 0.

c_variable : = 111.0;  // c_variable's type will be inferred, as float.


// You can use a : instead of the =,
// which indicates that a value is constant.
// Attempting to reassign this value would be an error.

d_variable : float : -123.45;
z_variable := d_variable;


/*
    Procedures follow this same declaration format.
    For them we don't usually write the type -- we let it be inferred,
    because the syntax for writing a procedure tells us all the type
    information anyway.

    And we usually declare procedures as constant, with two colons,
    because you usually don't want to rebind them at runtime.

    The procedure where your program begins is called main.

 */

#import "Process";
Compiler :: #import "Compiler";

build_steps :: (message : *Compiler.Compiler_Message, item : int)
{
    using Compiler.Compiler_Message.Kind;
    if message.kind == CODE_TYPECHECKED {
        tc := cast(*Compiler.Compiler_Message_Code_Typechecked) message; 
         for decl : tc.declarations {
             print("%", decl);
         }
    }
}



cool :: (any : Any, t: Type) 
{
}

bad_type :: #type (int) -> int, int, int;

main :: () {  // The parentheses are the argument list. The {} enclose the body of the procedure.
 

    cool( #type (int) -> int, int, int );
    // Unlike C, our print function knows the types of things.
    // We just use % in the string to say that the next value
    // in the argument list should be printed in that spot.

    // Note that we can explicitly refer to types. We'll come
    // back to this later
    
    print("A is of type %, value %.\n", type_of(a_variable), a_variable);
    print("B is of type %, value %.\n", type_of(b_variable), b_variable);
    print("C is of type %, value %.\n", type_of(c_variable), c_variable);
    print("D is of type %, value %.\n", type_of(d_variable), d_variable);
}
    

/*

    To build this program, run:

        jai 001_first.jai

    To run it:

        001_first

 */


Printer :: #type (builder: *String_Builder, any: Any, expansion: *Formatter) -> void;