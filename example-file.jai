#import "Basic";


// Before too long we are going to renumber these. Array literals will probably
// come before struct literals in the how_to.

// But, anyway, array literals work like struct literals now, in an exactly
// analogous way. You say .[a, b, c] to denote an array literal, and can use
// these directly as expressions to procedures and whatever. The type inference
// works just like struct literals.

// Note to beta testers:
//
// For now, struct literals use .{} and array literals use .[], but we might
// be able to make them the same thing eventually ... I'm just not sure yet, so
// I am being conservative on this for now. They can probably be the same thing
// when there is no type written to the left of the . but the problem is, when
// there is a type there, are we making an array of a struct, or just a struct?
// We could use a parsing hack to disambiguate that I guess, because if it's
// an array of a struct, the first thing has to be another struct literal ...
// But what if the first part of that literal is a complicated type expression?
// There could be no way to reasonably do this within the parser. I dunno man.


main :: () {

    // Later on we will fill this file out so that it's a nicer, better example,
    // but for now here's some stuff:

    add_numbers :: (numbers: [] int) -> int {  // Just a procedure that operates on an array of numbers...!
        sum := 0;
        for numbers sum += it;
        return sum;
    }

    numbers := int.[1, 3, 5, 7, 9];
    for numbers print("numbers[%] = %\n", it_index, it);

    sum1 := add_numbers(numbers);
    sum2 := add_numbers(.[1, 2, 3, 4, 5]);

    print("sum1 is %, sum2 is %\n", sum1, sum2);

    print("\n");


    // Sometimes you want to return an empty array...
    get_strings :: (x: int) -> (success: bool, result: [] string) {
        if x & 1 {
            return true, .["The", "number", "is", "odd."];
        }

        return false, .[];
    }

    success1, strings1 := get_strings(5);
    success2, strings2 := get_strings(6);

    for strings1 print("strings1[%] = '%'\n", it_index, it);
    for strings2 print("strings2[%] = '%'\n", it_index, it);  // This will print nothing since strings2 is empty!

    print("\n");

    
    // Empty array literals will have their count pointer not only set to 0,
    // but their data pointer is guaranteed to be null.
    // This was not true in previous versions of the compiler.
    // This is nice because you can return an empty array literal from a function
    // that otherwise allocates, and someone later can free the data pointer on that array,
    // and if it was an empty array, the data pointer will be null (so that free will do nothing),
    // rather than some random pointer to 0 elements in static space somewhere.

    a := string.[];
    print("a.count is %, data is %.\n", a.count, a.data);
    print("a.data is %\n", a.data);

    b: [] string = string.[];
    print("b.count is %; b.data is %\n", b.count, b.data);
    print("type_of(b) is %\n", type_of(b));

    c: [] string = test_global_array;
    print("c.count is %; c.data is %\n", c.count, c.data);

    print("test_global_array.count is %; test_global_array.data is %\n", test_global_array.count, test_global_array.data);

    // And let's go check strings2, which was returned as an empty array from get_strings:
    // @Incomplete:
    // A better example later on probably has get_strings dynamically allocate stuff,
    // so we can explicitly show the free thing:

    print("strings2.count is %; strings2.data is %\n", strings2.count, strings2.data);
    

    print("\n");
    
    // Using short names with array literals:
    Fruit_That_Is_Good :: enum {
        APPLE      :: 1;
        BANANA     :: 2;
        BANANANA   :: 3;
        KIWI       :: 4;
        GRAPE      :: 5;
        STRAWBERRY :: 6;
    }

    what_i_want :: Fruit_That_Is_Good . [ .APPLE, .GRAPE, .KIWI, .BANANANA, .APPLE];

    for what_i_want print("[%] %\n", it_index, it);


    f :: (a: [] s8) {
        for a print("f[%] = %\n", it_index, it);
    }

    f(.[1, 2, 3, 4, 99]);


    using Fruit_That_Is_Good;
    array := Fruit_That_Is_Good.[APPLE, KIWI];

    // @Incomplete: Finally fix the enclosing_scope problem with := vs ::!!!
    // Right now this actually doesn't work. Beta users beware!
    // It will be fixed.
//    array :: Fruit_That_Is_Good.[APPLE, KIWI];



    g :: () -> [] string {
        return .[];
    }

    r := g();
    print("r.count is %\n", r.count);
    print("g().data is %\n", r.data);


    luminance_color_ramp := ([3] float).[.[0,0,0],  // black
                                         .[0,0,1],  // blue
                                         .[0,1,1],  // cyan
                                         .[0,1,0],  // green
                                         .[1,1,0],  // yellow
                                         .[1,0,0],  // red
                                         .[1,0,1],  // magenta
                                         .[1,1,1]]; // white

    for luminance_color_ramp print("% % %\n", it[0], it[1], it[2]);


    s := join(.. .["foo", "bar", "puf"], ", ");
    print("s is %\n", s);
}

#import "String";

test_global_array := string.[];
