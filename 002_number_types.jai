#import "Basic";

main :: () {
    // The basic numeric types are named after their sizes.

    // There are types for unsigned integers, with names starting
    // with the letter 'u' followed by the number of bits:
    // u8, u16, u32, u64.

    a: u8  = 10;
    b: u16 = 50;
    c: u32 = 0x78f;  // You can write numbers in hexadecimal by starting with 0x.
    d: u64 = 0xfade_deaf_cafe_babe;  // You can put underscores into numeric constants for readability.

    // There are corresponding types for signed integers:

    e: s8  = -7;
    f: s16 = 0b101101101;    // You can write numbers in binary by starting with 0b.
    g: s32 = -5_069_105;
    h: s64 = 987654321;

    // If you try to assign one of these values to a constant that is too big,
    // the compiler will give you an error at compile time.

    // Compile-time errors are gifts! They mean you don't have to debug
    // running code in order to find the problem. We like compile-time errors.

    // i: s16 = 80000;  // This number won't fit into 16 bits. Try uncommenting this line and see.
    // j: u32 = -1;     // -1 is signed, so it is out of range of what a u32 can store. Try uncommenting and see.

    
    // Any integer numeric constant is s64 by default, so that's the type you get
    // if you let the compiler infer a type automatically:

    k := 7;
    print("k is %; type_of(k) is %.\n", k, type_of(k));

    // But these numeric constants will automatically convert to other types
    // if they fit (which is why the above assignments of a, b, c, etc work!)
    // So in this language, you don't need to suffix numeric constants 
    // in order to make the typechecking work.

    // It's important to understand that numeric constants are special, in that
    // they automatically cast to various types very easily. But general variables
    // do not behave like this. In this language, unlike C or C++, numeric variables
    // will only implicitly cast to each other, for example when assigning one value
    // to another value, if the target of the assignment is big enough to hold the
    // entire range of the source variable. For example:

    b = a;  // This is okay, since u16 is bigger than u8.
    // a = b;  // This produces an error if you uncomment it. Try it!

    h = c;  // This is okay, because s64 contains all of u32.

    // d = e;  // This produces an error. Even though d is much bigger than e, it can't hold negative numbers!
    // d = f;  // This also produces an error. Though f happens to hold a positive number, the type of f is something that can hold negative numbers, and that's what determines the validity of the operation.

    // If you want to squeeze a bigger type into a smaller type, you
    // can use an explicit cast.

    a = cast(u8) b;  // Though b is bigger, we cast it down to u8!

    // To help catch mistakes, cast operations check the range of the value
    // they are casting; if information is lost, that's an error (but it's a runtime
    // error, so, not as convenient as a compile-time error).

    // a = cast(u8) c;  // This will report an error at runtime if uncommented. Try it!

    // If you know you want to discard information, intentionally, you can turn off
    // the check with a ,no_check modifier:

    a = cast,no_check(u8) c;
    print("c is %; after casting this to u8, a is now %.\n", c, a);

    // Cast bounds checks can be turned off at compile time,
    // for builds that you want to run at maximum speed.


    // There's one more name of an integer type, 'int', which is just an alias for s64.
    // Why have another name for it?  It's to signal intent.  If you want an integer variable
    // but don't want to think precisely about how big it needs to be, just use int.
    // Then someone who reads the code will know, for example, that it may not necessarily
    // be true that this value needs to be 64 bits for any good reason. Whereas if you
    // just write s64 everywhere, people won't know which ones are 64-bit for
    // functionally necessary reasons, and which are just that way arbitrarily.

    my_int: int = 7;

    int_matching := type_of(my_int) == type_of(h);   // You can compare types! We'll talk about this later.
    print("int_matching: %\n", int_matching);


    
    // There are two floating-point types, float32 and float64.

    l: float32 = 123.005;
    m: float64 = 500.321;

    print("l is of type %, % bytes large.\n", type_of(l), size_of(type_of(l)));
    print("m is of type %, % bytes large.\n", type_of(m), size_of(type_of(m)));


    // Any floating-point numeric constant is float32 by default, if it is of sufficient
    // precision to fit into a 32-bit IEEE-754 floating-point number. Otherwise
    // it's float64.

    n := 1.111;
    o := 1.11111111111111111;

    print("n is %, of type %.\n", n, type_of(n));
    print("o is %, of type %.\n", o, type_of(o));  // Right now we don't print all the trailing digits of o, though.


    print("\n");  // This prints a newline, to format our output more nicely.
    
    
    // You can use the 0h prefix to specify floats in hex, in IEEE-754 format.
    // This lets us straightforwardly specify weird values if we want to.
    
    nan32   := 0h7fbf_ffff;             // This is a NaN.
    weird64 := 0h8000_0000_0000_0000;  // Negative zero, 64-bit version.

    print("nan32 is: %\n", nan32);
    print("weird64 is: %\n", weird64);


    // The type 'float' is an alias for float32.

    x: float32 = 111.0;
    y: float   = x;

    float_matching := type_of(x) == type_of(y);
    print("float_matching: %\n", float_matching);     // y and x are the same type.
}    
