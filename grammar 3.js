const Precedence = {
  Declaration : 1,
  Declaration_With_Block :  2, // declaration + 1... this javascript is useless dude.
};


module.exports = grammar({
  name: 'jai',
  extras: $ =>
   [
    $.inline_comment,
    $.block_comment,
    /\s+/,
  ],

  word: $ => $.identifier,

  conflicts: $ =>[
    [$.comma_separated_args],    
  ],

  rules: {

    source_file: $ => repeat(
        $._statement,
      ),

      note: $ => choice(
        choice($.note_with_args, $.note_simple)
      ),
  
      note_simple: $ => /@[a-zA-Z_][a-zA-Z_0-9]*/,
      note_with_args: $ => token(seq(
        /@[a-zA-Z_][a-zA-Z_0-9]*/,
        "(",
        repeat(/./),
        ")",
      )),
  
      identifier: $ => /\$?[a-zA-Z_][a-zA-Z_0-9]*/,
  
      number: $ => /\d[\d_]*\.\d+|\d[\d_]*|\.\d[\d_]*|0(h|x|X)[a-fA-F0-9_]+|0b[01_]+/,
      
      scientific_notation: $ => token(seq(
        /\d[\d_]*\.\d+|\d[\d_]*|\.\d[\d_]*|0(h|x|X)[a-fA-F0-9_]+|0b[01_]+/,
        "e",
        choice("+","-"),
        /\d[\d_]*\.\d+|\d[\d_]*|\.\d[\d_]*|0(h|x|X)[a-fA-F0-9_]+|0b[01_]+/,
        )),
  
  
        array_specifier: $ => seq(
          "[",
          optional(choice($.expression, "..")),
          "]"
        ),
  
        type_instantiation: $ => prec.left(-2,
           seq
           (repeat(choice("*", "$", "..", $.array_specifier)),
            choice($.identifier, $.built_in_type, $.procedure_header))), // this can be a lambda type, array, pointer_to, or type
  
        declaration: $=>prec.left(Precedence.Declaration,
         seq(
            choice($.type_instantiation,
            seq($.identifier,
              ":",
              choice( 
                seq(
                  optional($.type_instantiation), choice(":", "="), $.expression
                ),
                $.type_instantiation
              ), // choice
            ) // seq
          ), //choice
          repeat($.note)
        )),
        
        unary_operator: $ => choice(
          prec.right(1, seq("..", $.expression)),
          prec.left( seq("-", $.expression)),
          prec.right( seq("xx", $.expression)),
        ),

        binary_operator: $ => choice(
          prec.left(seq($.expression, "==", $.expression)),
          prec.right(seq($.expression, "[", $.expression, "]")),
          prec.left(seq($.expression, "*", $.expression)),
          prec.left(seq($.expression, "-", $.expression)),
          prec.left(seq($.expression, "/", $.expression)),
          prec.right(seq($.expression, "=", $.expression)),
          prec.right( seq($.expression, "+=", $.expression)),
        ),

        declaration_with_block: $=>prec.left(Precedence.Declaration_With_Block,
          seq($.identifier,
             ":",
             optional($.type_instantiation),
             seq(
               choice(":", "="),
               choice($.procedure_definition, $.enum_definition),
             ),
           repeat($.note)
         )),


        argument: $=>prec(2, seq( // precedence over "comma separated args"
          optional(seq($.identifier, "=")),
          $.expression
        )),
  
        compound_declaration: $=> prec.left(1, seq(
          $.comma_separated_args,
          ":",
          choice( 
            seq(
              optional($.type_instantiation), choice(":", "="), $.expression
            ),
            $.type_instantiation
          ),
          repeat($.note)
        )),
  
      
        comma_separated_args: $ => prec.left( seq(
          $.expression, repeat1(prec.left(seq(",", $.expression)))
        )),


        trailing_return_types: $ => prec.right(1, seq(
          "->",
          choice(
            CommaSep1(seq($.declaration, optional("#must"))),
            seq(
              "(",
              CommaSep1(prec(1, seq($.declaration, optional("#must")))),
              ")"
            )
            ),
        )),
  

  
        procedure_header: $=> prec.left(seq(
          "(",
          field("arguments", CommaSep($.declaration)), 
          ")",
            optional($.trailing_return_types),
          ),
        ),
          
        block : $=> seq(
            "{",
             repeat($._statement),
             "}",
          ),

        procedure_definition: $ =>  seq($.procedure_header, $.block),



      return_statement: $ => seq(
        'return',
        CommaSep($.argument),
        ';'
        ),
          
      procedure_call: $ => seq(
        field("procedure", $.expression),
        "(",
          CommaSep($.argument),
        ")"
      ),



      using_statement: $ => prec(1, seq( // precedence over unary using
        "using",
        choice(
          $.declaration,
          $.expression_statement,
        )
      )),
  
  

      enum_definition: $ => seq(
        choice("enum", "enum_flags"),
        optional($.type_instantiation),
        optional("#specified"),
        $.block
      ),


      range: $ => prec.right(seq(
        $.expression,
        optional(
          seq('..', $.expression))
        )),
  
      for_specifier: $=>prec.left( 6,
        seq(
          choice("<", "*"),
          optional(seq("=", $.expression))
      )),
  
      for_loop: $ => seq(
        "for",
        //repeat($.for_specifier),
        //optional(seq(
       //    seq(optional("`"), CommaSep1($.identifier)),
      //      ":")),
        $.range,
        $._statement,
      ),

 

    struct_literal: $ => prec(5, seq( // precedence over member access
        optional($.type_instantiation),
        ".","{",
        CommaSep(prec(5, $.expression)),
          "}"
      )),

    compile_time_array_literal: $ => prec(5, seq( // precedence over member access
      optional($.type_instantiation),
      ".", "[",
      CommaSep(prec(5, $.expression)),
        "]"
    )),



    expression: $ => choice(
      $.comma_separated_args,
      $.identifier,
      $.number,
      $.scientific_notation,
      $.string_literal,
      $.uninitialized_token,
      //$.declaration,
      $.compound_declaration,
      $.procedure_call,
      $.binary_operator,
      $.unary_operator,
      $.compile_time_array_literal,
      $.struct_literal,
    ),




    _statement: $ => choice(
      $.declaration_with_block,
      $.block,
      $.using_statement,
      $.expression_statement,
      $.return_statement,
      $.import_statement,
      //seq($.compound_assignment, ";"),
      //$.for_loop,
    ),

    expression_statement: $ => seq( $.expression, ";"),

      // stolen from the c grammar.
      inline_comment: $ => token(seq('//', /.*/)),
      block_comment: $ => seq(
        '/*',
        repeat(choice(/./, $.block_comment)),
        '*/'
      ),
      



    uninitialized_token: $ => "---",


    // taken from c grammar
    string_literal: $ => seq(
      '"',
      repeat(choice(
        token.immediate(prec(1, /[^\\"\n]+/)),
        $.escape_sequence
      )),
      '"',
    ),

    escape_sequence: $ => token(prec(1, seq(
      '\\',
      choice(
        /[^xuU]/,
        /\d{2,3}/,
        /x[0-9a-fA-F]{2,}/,
        /u[0-9a-fA-F]{4}/,
        /U[0-9a-fA-F]{8}/
      )
    ))),

   


    built_in_type: $ => choice(
      'bool',
      'float32',
      'float64',
      'float',
      'int',
      'char',
      'string',
      's8',
      's16',
      's32',
      's64',
      'u8',
      'u16',
      'u32',
      'u64',
      'void',
    ),



    import_statement: $ =>  prec(1, seq( // precedence over unary import
      '#import',
      field("name", $.string_literal),
      ";"
    )),


  }
}
);

function CommaSep(rule) {
return optional(CommaSep1(rule))
}

function CommaSep1(rule) {
return seq(
  rule,
  repeat(seq(
    ',',
    rule
  ))
)
}


