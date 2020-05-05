#import "Basic";

// XXX Incomplete: Talk about structs having a namespace.

// Mental Organization
// Physical Organization

// XXX Organization: passing many elements around.
/*

  This language also has structs, which are collections of other data types
  packed together. These are mostly the same as structs in C, if you are familiar
  with those.

  The reason you'd collect values together in a struct is for purposes of organization.
  Structs help you think about what your program is trying to accomplish, by grouping
  smaller variables together in a way that engages the human mind's ability to "chunk"
  concepts together. In this way they help you see a program in your mind.

  As an example, suppose you want to store information about people you know. You might
  put that information together into a struct:

*/

Person :: struct {
    name:         string;
    address:      Address;
    phone_number: Phone_Number;
    year_born:    int;
    month_born:   int;
    day_born:     int;
}

Address :: struct {
    street_number: int;
    street_name:   string;
}

Phone_Number :: [9] u8;

/*

  and so forth. Then, you can just think of your program as something that manipulates
  these batches of information about people, without having to think about all the
  individual pieces of information like address and phone_number as having separate
  and very divergent existences.

  You can write procedures that take a Person as an argument, instead of a bunch of
  loose fields. You can assign a variable of type Person to another variable of type
  Person.

  In addition to this mental organization, structs also perform physical organization:
  they control how the memory, that stores all the struct's fields, is laid out. 
  We'll talk about this in more detail later on, but it's worth mentioning here. 

  Some might say that it's confusing for structs to be performing these two different
  tasks that ought to be orthogonal. As an example, people from 'functional language' schools
  of thought might say that "implementation should be totally decoupled from semantics":
  that the way data is stored doesn't really matter, and the compiler should take care of that,
  and you should concern yourself with the mental part, and ignore the physical part, because
  that means you as the programmer don't have to think about as many things, which 
  means you are doing less work.

  That sounds good, but things rarely work that way in reality, unless you are talking about
  programming languages for beginners, or for people who are not themselves
  professional programmers, and just want to do some programming incidentally so that they 
  can get some other work done, like scientific research, or customizing the behavior of
  some overly-complex piece of software. 

  In reality, compilers just aren't very smart, and any decisions they make regarding
  data layout are not going to be as good as the choices that would be made by a skilled
  programmer who is experienced at laying out data. So there is nearly no benefit to
  rearranging the way things are stored in a struct; so it actually makes programs simpler
  when the compiler doesn't do this. Because if structs can be rearranged, there are
  two concepts in play: the mental order of the struct, and the physical order of the struct,
  and to understand what is actually happening on the computer, you need to know both of these.
  Furthermore, there are added complications that can happen, for example, maybe the compiler
  makes different choices about how to lay out a struct between one run and the next, and this
  surprises you when your program gets appreciably slower for no reason you can see (and no
  reason under your control to fix).

  On the other hand, if the conceptual and physical orders are the same, you only 
  need to know one thing, and it will never change.

  Furthermore, when programs are efficient, the conceptual order and the physical order
  tend to be the same naturally. There are lots of strange ideas about how to program,
  for example "Object Oriented Programming", where it is often taught to beginners that
  you should choose data structures that reflect a physical object's behavior in the real world.
  (This is a misunderstanding of OOP propagated by teachers who are insufficiently experienced
  at programming, but nevertheless, it is what actually happens in many schools).
  If you do this, programs often become complicated quickly, because the operations you want
  to perform on the objects' data do not seem to align very well with the operations
  that you would abstractly think of as occurring in the Real World. (This is hard to explain
  without a concrete example, and this explanation is already pretty long, so we'll leave this
  statement somewhat vague for now.)

  When programs are efficient, both in terms of speed and in terms of structural simplicity, 
  data structures are actually designed around the job that the computer is physically 
  trying to do. Because what matters to you as the programmer is not what an average person
  off the street thinks should be happening with some conceptual object, but rather,
  what you know a computer needs to do in order to successfully perform complex algorithms.
  As programmers get more experienced, they learn to think about programs such that the 
  collections of data in the code -- the things you would build structs around -- are naturally
  the things that the program wants to manipulate most directly. Because that's your job,
  to make sure the program correctly manipulates the data.

  Specifying the physical layout of the data, and it being the same as the conceptual layout
  of the data, is exactly what the programmer wants at this stage of experience.

*/

// The following is a struct for an axis-aligned rectangle:

Rectangle :: struct {  // It is my personal style to capitalize the names of my structs, but it's not required.
    x0: float;   // X coordinate of lower-left corner.
    y0: float;   // Y coordinate of lower-left corner.
    x1: float;   // X coordinate of upper-right corner.
    y1: float;   // Y coordinate of upper-right corner.

    color_name: string;   // Maybe the name of a color we use to draw this, or ... something.
}

// You may often want code to look at these values at the same time, for drawing rectangles,
// testing the mouse pointer against their coordinates, saving and loading rectangles, and
// so forth.

main :: () {
    r: Rectangle;   // This declares a Rectangle on the stack. All its members are initialized to their default values.

    // We can print the entire struct very easily; the print function will show us all its members:

    print("Initially, r is: %\n", r);

    // Let's set some of the members.

    r.x0 = 10;
    r.y0 = 5;
    r.x1 = 50;
    r.y1 = 55;

    r.color_name = "chartreuse";

    print("Later, r is: %\n", r);

    print("\n");
    
    foo := 3;
    
    // Structs are stored in memory in the order in which their members are declared,
    // with no surprises. Thus if you write a struct to a file, or copy it to somewhere
    // else in memory, you have a good idea what is happening.

    // This is different from the idea in some other programming languages, where data structures
    // are specified semantically, but not in terms of implementation: the compiler could move
    // members around, or something like that. In this language, that's prohibited. The order
    // in which you declare members of the struct, along with their types, uniquely determines
    // the placement of each member. This placement does not depend on the target platform
    // or any other implementation detail that would change behind your back. Thus it's very
    // simple and will not make you worry.
    
    // Later we will talk about advanced struct stuff like controlling alignment and initialization,
    // but for now, you can see how things are stored in memory relative to the address where
    // the struct begins:

    // The unary * operator means you're taking the address of a value: the memory location where
    // that value is stored.
    
    // Since r is a struct, *r means the memory address at which the struct r is stored.
    
    print("The base of r is %.\n", *r);

    print("The address of r.x0 is %. (The same as r!)\n", *r.x0);
    print("The address of r.x1 is %.\n", *r.x1);


    // Bad teaching has made a lot of people scared of pointers, or convinced them
    // that pointers are very mysterious.

    // But in modern computers, a pointer is just an integer. It is the location in memory,
    // as managed by the operating system, where the struct's data is stored. (In very rare
    // computer architectures where a pointer is more complicated than one integer, it can
    // still be mapped to integers straightforwardly, so don't worry about it.)


    // You can assign a struct to another struct.
    // It works just as you'd expect:

    print("\n");
    
    s := r;

    print("s is %\n", s);

    print("\n");


    // You can call a procedure with a struct as argument, again, like anything else:

    rotate_rectangle :: (r: Rectangle) -> s: Rectangle {
        s: Rectangle;
        s.color_name = r.color_name;  // Don't change the color!

        // Rotate the rectangle by 90 degrees counterclockwise around the origin.
        // note that after you do this, these points no longer represent the
        // lower-left and upper-right corners, so maybe this function
        // is a bad idea, but it's just an example.
        
        s.x0 = -r.y0;
        s.x1 = -r.y1;
        s.y0 =  r.x0;
        s.y1 =  r.x1;
        
        return s;
    }

    other_r := rotate_rectangle(r);
    

    // Structs can be defined locally to a procedure, like right here:

    Vector3 :: struct {
        x, y, z: float;  // Compound declaration: all of x, y, and z are floats.
    }

    // Structs can contain other structs:

    Line_Segment :: struct {
        start: Vector3;
        end:   Vector3;
        color: string;
    }


    segment: Line_Segment;
    print("segment is: %\n", segment);

    print("\n");
    

    // You can set default values for struct members, just using the same
    // declaration syntax you would use for declaring local variables:

    Ice_Cream_Info :: struct {
        temperature := -10.0;
        flavor      := "vanilla";
        num_scoops  := 2;
    }
    
    serving1: Ice_Cream_Info;   // serving1 will get the defaults.

    print("serving1 is: %\n", serving1);

    serving2: Ice_Cream_Info;   // serving2 will get the defaults, but then we will change some!
    serving2.temperature = -17.8;
    serving2.flavor      = "peppermint";
    
    print("serving2 is: %\n", serving2);
    

    // You can even set default values of sub-structs inside a struct, using an = operation.

    Ice_Cream_Store_Display :: struct {
        brightness: float;

        info: Ice_Cream_Info;       // Use the default ice cream info...
        info.flavor = "chocolate";  // But set the flavor to chocolate! But leave the rest of the defaults.

        position: Vector3;
        position.z = 1.5;           // Raise up the display in Z.

        brightness = 101.2;         // Kind of goofy to declare brightness up top then set it down here, but there you go.
    }


    print("\n");
    
    display: Ice_Cream_Store_Display;
    print("display is: %\n", display);
    
    print("\n");


    // Maybe 'using' should be in its own file, but:
    // You can use the keyword 'using' to locally manipulate the variables
    // in a struct. For example, if I want to start messing around with
    // 'display' in a short-hand manner, I can do the following:

    // First, let's open up a new scope to keep the names from the 'using' contained,
    // so they don't mess with our main routine here:

    {
        using display;   // Now all display's members are local names for us.

        brightness = 375.4;           // The same as saying display.brightness = 375.4;

        info.flavor = "strawberry";   // The same as saying display.info.flavor = etc.

        position.x = 1;

        print("After first using, display is: %\n", display);

        print("\n");
        
        
        // Let's say I want to manipulate x, y, and z in super-shorthand...
        // I can say using display.position, or since position is already a local name,
        // I can say:

        using position;

        x += 1;   // This is display.position.x!
        y = -3;
        z *= 4;

        print("After second using, display is: %\n", display);

        // I don't encourage heavy use of this unless it really shortens a program, though.
        // The ability to do this seems neat, but often it adds a great deal of legibility
        // to your program to just dereference things fully.

        // If you try to use 'using' to import multiple variables that have the same name,
        // this will be a compile-time error. We'll talk about how to avoid that later,
        // in the special chapter on 'using'.
    }

    
    print("\n\n");


    // The size of a struct, measured in bytes of memory, includes enough storage for all
    // its elements, including potential padding between elements. Different platforms
    // may have different alignment requirements. So your struct could end up being different
    // sizes on different target machines, *but*, you are able to query everything about the struct
    // and know these facts at compile time.
    // 
    // Furthermore, you can control padding and alignment manually with compiler directives,
    // which we'll talk about much later in a different file.

    // You can use size_of to get the size.
    
    print("size_of(Rectangle) = %\n", size_of(Rectangle));


    // size_of accepts a Type as its argument. This may seem inconvenient if you are
    // coming from C, where you could also pass a value.
    //
    // But, this is intentional, to protect against an easily-makeable mistake.
    // Types are "first-class" in this language and we use them directly all the time.
    // So, you might have some variable of type Type, and this can introduce
    // ambiguities; exactly how is left as an exercise for the advanced reader.
    // (If having a variable of type Type seems confusing, see the how_to file
    // a little later on where we talk about this!)

    // If this explanation doesn't make sense to you, don't worry about it, it's
    // not important unless you want to know why you can't say size_of(r)!
    // Just say size_of(type_of(r)) instead.
    
    print("size_of(type_of(r)) = %\n", size_of(type_of(r)));


    // You can copy structs around in memory, manually, if you want.
    // Here we'll copy a struct into an array, and then back into another struct.

    print("\n");
    
    t: Rectangle;
    print("Before copy, t is: %\n", t);

    temporary: [size_of(Rectangle)] u8;
    memcpy(temporary.data, *r, size_of(Rectangle));   // Copy r's data into temporary.

    print("\n");
    print("Contents of 'temporary', in bytes: ");
    for temporary print("% ", formatInt(it, base=16, minimum_digits=2));  // Integer formatting is kind of verbose right now.
    print("\n");

    memcpy(*t, temporary.data, size_of(Rectangle));   // Copy temporary's data into t.

    print("After copy, t is: %\n", t);


    // You know what? Things don't need to be structs in order for you to copy them
    // in memory like this. It's just a common thing to do with structs. For example,
    // when you remove an element from an [..] array, the element in the last slot is
    // copied into the element in the empty slot.

    // I guess this example could be more focused. We kind of left the topic of structs.
    // Oh well.
}



/*

    We don't have reasonable struct literals yet in this language. They are coming soon!
    When fully implemented, we'll cover them here.

 */

// Let's do something about anonymous structs in a later chapter.

// A way to get more magic here: Build sequentially from sphere, to ice cream scoop, to multi-scoop display?
// Also, format the print output more nicely.
