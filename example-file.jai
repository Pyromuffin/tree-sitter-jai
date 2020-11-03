//
// This will be developed into more of a fluid explanation about the various
// procedure-calling features...!
//

#import "Basic";

default_arguments :: () {
    hello :: (a: int = 9, b: int = 9) -> int, int {
        return a, b;
    }

    out1, out2 := hello(1, 2);

    out1, out2 = hello(1);

    out1, out2 = hello();
}

named_arguments :: () {
    Colors :: enum {
        BLUE;
        RED;
        YELLOW;
        ORANGE;
        MAUVE;
        CHARTREUSE;
        NONE_MORE_BLACK;
    }

    using Colors;

    make_character :: (name: string, catch_phrase: string, favorite_color: Colors, least_favorite_color: Colors) {
        assert(name == "Fred", "Expected % but got %\n", "Fred", name);
        assert(catch_phrase == "Hot Damn!", "Expected % but got %\n", "Hot Damn!", catch_phrase);
        assert(favorite_color == BLUE, "Expected % but got %\n", BLUE, favorite_color);
        assert(least_favorite_color == MAUVE, "Expected % but got %\n", MAUVE, least_favorite_color);
    }

    make_character("Fred", "Hot Damn!", BLUE, MAUVE);

    // By using the names of arguments, you can provide the arguments in various orders:
    make_character(catch_phrase = "Hot Damn!", name = "Fred", 
                   least_favorite_color = MAUVE, favorite_color = BLUE);

    make_character(favorite_color = BLUE, catch_phrase = "Hot Damn!",
                   least_favorite_color = MAUVE, name = "Fred");

    make_character("Fred", 
                   favorite_color = BLUE, catch_phrase = "Hot Damn!",
                   least_favorite_color = MAUVE);

    
    // Named arguments also help when you have default arguments.
    many_things :: (s : string, a := 1, b := 2, c := 3, d := "The New Originals", e := 5.5, f := 6.0, g := false) {
        // Do whatever in here.
    }

    many_things("My Call");
    many_things(s = "My Call");

    // It makes sense to have a non-default argument after a default argument because you can name them!
    curious :: (pre: string, index: u16 = 0, post: string) {
        // Do stuff in here...
    }

    curious(pre = "Hello,", post = "Sailor!");
}

arguments_with_varargs :: () {

    // We can also create procedures that take a variable number of arguments:
    
    varargs_strings :: (i: int = 42, names: .. string) {
        // 'names' is declared as being of type .. string, which means you can pass any number of arguments
        // and they all get collected into 'names'. The arguments must all be strings in this case.

        // The actual type of 'names' is [] string, as you can see:

        print("The type of 'names' is %.\n", type_of(names));

        // So, the .. in the argument declaration means, this is a [], but we automatically create the array
        // at calling time, based on the arguments you pass in from elsewhere.

        for names print("i is %, and names[%] is %.\n", i, it_index, it);

        
        // Unlike the headaches of variable arguments in languages like C and C++,
        // here, if you want to pass 'names' to any other variable-argument procedure,
        // you can use the .. operator to say, hey, don't make an array out of these,
        // as they are already an array of the thing you want!

        print_strings_together(..names);

        // The input array doesn't have to come from varargs; it can come from anywhere!

        FRUITS :: string.["Banana", "Blueberry", "Grape", "Plantain", "CinnamonBear", "Aardvark"];
        print_strings_together(..FRUITS);

        // But because print_strings_together takes variable arguments, you can call it with separate
        // arguments, of course, that's the whole point!

        print_strings_together("Ohio", "Oregon", "Oslo", "Oceania");
    }

    print_strings_together :: (strings: .. string) {
        for strings print("%", it);
        print("\n");
    }

    varargs_strings(11, "Fred", "Alfred", "Alan", "Frederick", "Joe");

    print("\n");
    

    // There is a type called Any, which matches any other type in the language.
    // When the compiler is able, it creates an implicit conversion between the types.
    // You can see an explanation of this in 030_any.jai. For now let's just take for granted
    // that it happens.
    varargs_strings_and_ints :: (s: string = "Hello", i: int = 2, v: .. Any) {
        print("s is '%'; i is %.\n", s, i, v);

        // The type of v is [] Any.
        print("The type of v is %.\n", type_of(v));

        print("The values of v are:\n");
        for v print("    [%] %\n", it_index, it);

        print("\n");
    }

    // Pass no arguments. s and i get their default values, while v is an empty array.
    varargs_strings_and_ints();

    // Pass a bunch of stuff! The first argument must be a string, because 's' is the first argument.
    // The second argument must be an integer, because 'i' is the second argument.
    // After that, everything gets put into 'v', so they can be whatever type we want.
    varargs_strings_and_ints("What", 1, "is", "the", "matter", 9, 100, "dudes", 12000, "and dudettes", float);

    varargs_strings_and_ints(i = 5, s = "How", v = "are", "you", "there?");

    // In the next example, we start using varargs with v, then every argument
    // afterward contributes to v until we use "i = " to switch to argument i. This is an exception
    // to the "can't use unnamed arguments after named ones" rule.
    varargs_strings_and_ints(s = "Where", v = 1, "are", "you", "going", "to", i = 3);

    // We can also use the .. argument-spreading operator with the Any case.
    array : [6] Any;
    array[0] = "did";
    array[1] = "that";
    array[2] = "thing";
    array[3] = "you";
    array[4] = 0xfedcba9876543210;
    array[5] = "showed";

    // varargs with spread. First, in the simple way, no named arguments:
    varargs_strings_and_ints("Who", -9, ..array);

    // Now with names:
    varargs_strings_and_ints(s = "Why", v = ..array);
    varargs_strings_and_ints(v = ..array, i = -999);
}

multiple_return_values :: () {
    foo :: () -> int, int {
        return 3, 5;
    }

    x : int;
    y : int;

    x, y = foo();

    // You can have any number of return values!
    coefficients :: (x: float) -> float, float, float, float, float, float {
        return 3*x*x*x*x*x, -1.5*x*x*x*x, 2*x*x*x, 0, 8*x, -1;
    }

    c5, c4, c3, c2, c1, c0 := coefficients(5);

    // Implicit casts work fine:
    get_u8s :: () -> u8, u8 {
        return 100, 200;
    }

    z : u16;
    w : u16;

    z, w = get_u8s();

    assert(z == 100);
    assert(type_of(z) == u16);

    assert(w == 200);
    assert(type_of(w) == u16);

    // The following is not valid since u8 will not implicitly cast to float.
/*
    f1 : float;
    f2 : float;

    f1, f2 = get_u8s();
*/

    // Can name the return values.
    foo2 :: () ->  a: int, b: int  {
        return 3, 5;
    }

    a, b := foo2();

    // Can optionally put parentheses here:
    foo3 :: () -> (a: int, b: int)  {
        return 3, 5;
    }

    a, b = foo3();

    // You can have arbitrary lvalues on the left of a comma-separated assignment:
    N :: 4;
    array : [N] u32;
    for 0..N-1  array[it] = xx it;

    // Add the output of get_u8s to two successive elements of the array.
    // This involves an implicit cast from u8 to u32 and array math to make the lvalues.
    for 0..N-2  array[it], array[it+1] += get_u8s();
}

comma_separated_assignments :: () {
/*
    We can also use commas for multi-variable declarations 
    (either with explicit types or using type inference.)
*/
    foo :: () -> int, int {
        return 3, 5;
    }

    x, y: int;
    x, y = foo();

    z, w := foo();

    assert(type_of(z) == int);
    assert(type_of(w) == int);

    // You can also assign to a series of comma-separated expressions.
    i, j: int;
    i, j = x+1, y+1;

    //Now we can actually say... as a one-liner
    Vector3 :: struct {
        x, y, z: float;
    }

    v : Vector3;
    v.x, v.y, v.z = 1, 4, 9;

    // You can use comma-separated declarations with type inference:
    wacky :: () -> int, float, string, bool {
        return 3, 1.0, "Cowabunga!!", true;
    };


    // Multiple return values are *not* implemented by the compiler as tuples,
    // as you see in some programming languages. There are no tuples in this language at all.
    // Why? Because we don't want to rely on compiler optimization to kick in, in order
    // to generate good code ... because sometimes that may fail, due to aliasing, or
    // any of the many reasons that compilers give up on optimizing.
    // Internally, multiple return values work just like 'out parameters', where a value
    // is passed back by filling the contents of a pointer. So if you return big values,
    // it's not needlessly inefficient like in C where you have extra copies all over the place.

    // But, multiple return values are better than 'out' parameters, because
    // there is no confusion about pointers potentially being null, and there is
    // no worry about those pointers being aliased to something else.
    // So you can expect better code to be generated.
    a, b, c, d := wacky();

    e, f, g, h := a, b, c, d;

    assert(type_of(e) == int);
    assert(type_of(f) == float);
    assert(type_of(g) == string);
    assert(type_of(h) == bool);

    // Actually this comma-separated stuff should go into its own file maybe:
    
    // If the right-hand side of a comma-separated declaration or assignment
    // is a single value, that value is individually assigned to all variables:
    mask, lower, upper : u32 = 0xffffffff;    // Declaration version

    assert(mask == 0xffffffff &&
                 lower == 0xffffffff &&
                 upper == 0xffffffff);

    mask, lower, upper = 0x81818181;          // Assignment version.

    assert(mask == 0x81818181 &&
                 lower == 0x81818181 &&
                 upper == 0x81818181);


    // Equivalent way of saying C's (mask = lower = upper = 0x81818181) and 
    // may be generally better anyway.
    
    // By the way, all this works with any assignment operator:

    mask, lower -= 0x81000000;
    assert(mask == 0x818181 &&
                 lower == 0x818181);

    upper, mask += 0x0000007e;
    assert(upper == 0x818181FF &&
                 mask == 0x8181FF);

    // Even on heterogeneous types, as long as the RHS can infer to the left.
    // Recall that a is int and b is float.
    // One might get nervous about this but I think it's fine.

    a, b += 1;


    a, b *= 2;

    // If you uncomment this, it's an error. This won't pass typechecking because a is integer:
    // a, b -= 1.1;

    // We don't currently do multiple-assignments if the right-hand procedure
    // has only one return value. That would be more versatile but might be
    // confusing as code changes, because the meaning of your assignment would
    // mysteriously change in a way that you might not notice:
    /*
    some_function :: () -> int, string {
        return 5, "Fight for your right to party!";
    }

    r, s := some_function();
    */
}

default_return_values :: () {
    print("\n");

    fun :: (x: int) -> first: string = "Hello", second: string = "Sailor!" {
        if x == 0 return;
        if x == 1 return "Simple";
        if x == 2 return "Simple", "Simon";
        if x == 3 return second = "Simple", first = "Simon";

        return second = "Dolly";
    };

    a, b: string;

    a, b = fun(0);
    print("a is '%', b is '%'.\n", a, b);
    
    a, b = fun(1);
    print("a is '%', b is '%'.\n", a, b);

    a, b = fun(2);
    print("a is '%', b is '%'.\n", a, b);

    a, b = fun(3);
    print("a is '%', b is '%'.\n", a, b);

    a, b = fun(4);
    print("a is '%', b is '%'.\n", a, b);

    
    //  
    // A possibly-more-practical example:
    // 
    Status :: enum {
        SUCCESS;
        NEGATIVE_NUMBERS_CONFUSE_MY_API;
        EVEN_NUMBERS_ARE_FOR_LOSERS;
    }

    using Status;

    Vector3 :: struct {
        x, y, z: float;
    }

    Entity :: struct {
        using position : Vector3;
        id : u32;
    }

    complicated_function :: (input : int) -> result: *Entity = null, status := SUCCESS {
        if input < 0    return status = NEGATIVE_NUMBERS_CONFUSE_MY_API;
        if !(input % 2) return status = EVEN_NUMBERS_ARE_FOR_LOSERS;

        e := New(Entity);
        e.id = cast(u32) input;

        return result = e;
    }

    result : *Entity;
    status : Status;

    result, status = complicated_function(-1);

    result, status = complicated_function(20);

    result, status = complicated_function(13);
    free(result);

    // But then, this does make sense. Maybe it's confusing, or maybe it's a nice
    // thing for functional programming styles.
    bar :: (x: int) -> x: int {
        result := 3*x*x - 5*x + 1;
        return x = result;
    }    

    // There is potential to be confusing. Still feeling it out!
    baz :: (x: int) -> x: int {
        return x = x + 1;         // This does not modify local variable x!
    }    

    // If we don't like this, we could forbid return values from having the same names
    // as local variables. However, next demo, we'll show a case where we may want to
    // permit it. So maybe this is the right thing, or maybe this is one of those horrible
    // decisions like making C switch-statements non-breaking so that Duff's Device will work.
}

must_directive :: () {
    Vector3 :: struct {
        x, y, z: float;
    }

    Vector2 :: struct {
        x, y: float;
    }

    // We have a culture in C, C++, etc that paying attention to return values is optional.
    // Let's keep that as a default, but provide a way to ensure return values get noticed
    // if ignoring them is an error (for example, they point to allocated memory):
    producer :: (count: int) -> [] Vector3 #must, [] Vector2 #must, bool {
        is_even := (count % 2) == 0;

        return NewArray(count, Vector3), NewArray(count*2, Vector2), is_even;
    }

    r1 : [] Vector3;
    r2 : [] Vector2;
    r3 : bool;

    r1, r2, r3 = producer(5);     // This is valid.

    r1, r2 = producer(7);         // This is valid.

    a1, a2, a3 := producer(5);    // As you'd expect, this works fine with declarations.

    // To try and catch similar problems in C/C++, we'd probably use pointer parameters, and
    // enforce that they aren't NULL, and only catch the problem at runtime.
    // Here we catch it at compile time.


    // A function call's expression value is just the first return value,
    // so #must is useful for catching things like this:

    //    other_function(producer(5));  // Implicitly drops the *Vector2 on the floor.

    // (The above call will generate a compile-time error if you uncomment it).
}


a_note_about_struct_literals :: () {
    // You can use struct literals as default values to procedure arguments and returns.
    // The behavior is exactly what you'd expect if you think about the structs as atomic values,
    // but seeing subsets of struct literal names might confuse a newcomer as to what's going on,
    // so let's talk about it.

    // If you don't remember struct literals very well, you can go back and look at
    // 007_struct_literals.jai for a refresher.
    
    Ice_Cream_Info :: struct {
        temperature   := -10.0;
        flavor        := "vanilla";
        num_scoops    := 2;
        cone_style    := "waffle";
        add_sprinkles := false;
    }

    eat :: (info: Ice_Cream_Info = .{cone_style="cake", num_scoops=1}) {
        print("Eating a % cone with % scoops of % inside.\n",
              info.cone_style, info.num_scoops, info.flavor);
    }

    eat(.{flavor="chocolate", add_sprinkles=true});
    eat();

    // Make sure you think clearly about what's happening here! The default value
    // for the argument of 'eat' doesn't mean, "take whatever argument the user passes,
    // then set 'cone_style' and 'num_scoops'. Just like with scalars, the default value
    // does not ever combine with anything you pass as an argument.
    //
    // As always, you either get the entire struct represented by your argument,
    // or the entire struct represented by the default value (if you didn't supply the argument).
}
    
main :: () {
    default_arguments();
    named_arguments();
    arguments_with_varargs();
    multiple_return_values();
    comma_separated_assignments();
    default_return_values();
    must_directive();

    a_note_about_struct_literals();
}
