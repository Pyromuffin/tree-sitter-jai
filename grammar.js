module.exports = grammar({
  name: 'jai',
  //inline: $ => [$.note_simple, $.number],
  //inline: $ => [$.parameter],
  extras: $ =>
   [
    $.inline_comment,
    $.block_comment,
    /\s+/,
  ],

  word: $ => $.identifier,
  externals: $ => [$.here_string],

  conflicts: $ =>[
    [$.switch, $.binary_expression],
    //[$.parenthesized_trailing_return_types, $.unparenthesized_trailing_return_types],
    //[$.trailing_return_types, $.function_header],
    [$._expression, $.type_instantiation],
  ],

  rules: {

    source_file: $ => repeat(
        $._statement,
      ),


      expression_like_directive: $ => token(choice(
        "#caller_location",
        "#location",
        "#file",
        "#line",
        "#filepath",
        "#through",
      )),



    


    _expression: $ => choice(
      $.number,
      $.identifier,
      $.string_literal,
      $.parenthesis,

      $.scientific_notation,
      $.binary_expression,
      $.unary_expression,
      $.cast_expression,
      $.uninitialized_token,
      $.array_literal,
      $._expression_with_block,
      $.lambda_expression,
      $.expression_like_directive,
      $.ternary_expression,

      $.code_directive,
      $.comma_separated_args,

      // these guys add 500kb
      $.implicit_struct_literal, 
      //$.typed_struct_literal,
      $.implicit_compile_time_array_literal,
      //$.typed_compile_time_array_literal,

      // $.named_decl, // adds 700 kb
      // $.function_header,

      // hahahah this goes from 2 mb to 7 mb
      //prec(-1, $.type_instantiation),
      $.built_in_type

    ),

    parenthesis: $ => prec(0, seq( // lower than trailing return types
      "(",
      $._expression, // not optional as an expression!
      ")",
    )),
    

    _expression_with_block: $ => choice(
      $.function_definition,
      $.enum_definition,
      $.struct_definition,
      $.union_definition,
      //$.here_string,
    ),

    _type_definition: $ => prec(1, choice(
      $.enum_definition,
      $.struct_definition,
      $.union_definition,
    )),

    _statement: $ => choice(
      $.return_statement,
      $.using_statement,
      $.if_statement,
      $.for_loop,
      $.while_loop,
      $.defer_statement,
      $.switch_statement,
      $.case_statement,
      $.continue_statement,
      $.if_directive,
      $.break_statement,
      $.backtick_statement,
      $.remove_statement,
      $.empty_statement,
      $.push_context_statement,
      $.expression_statement,
      $.declaration_with_block,
      $.insert_lol,
      $.operator_definition,
      $.import_statement,
      $.file_scope_directive,
      $.export_scope_directive,
      $.program_export,
      $.load_statement,
      $.imperative_scope,
      $.run_statement,
      $._type_definition,
      $.assert_directive,
      seq($.named_decl, ";"),
    ),

    expression_statement: $ => seq( $._expression, ";"),

      inline_comment: $ => token(seq('//', /.*/)),
      block_comment: $ => seq(
        '/*',
        repeat(choice(/./, $.block_comment)),
        '*/'
      ),

      

      lambda_expression: $ => prec(-1, seq(
        choice($._parameter_list, $.identifier),
        '=>',
        field('body', choice($.imperative_scope, $._expression))
      )),


    uninitialized_token: $ => "---",

    remove_statement: $ => seq(
      "remove",
      $._expression,
      ";"
    ),

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

    backtick_statement: $ => seq(
      "`",
      $._statement
    ),

// is this where directives live?
    code_directive: $ => prec.left( seq( 
      "#code",
      choice($._expression, $.imperative_scope)
    )),

    assert_directive: $ =>
    seq(
        "#assert",
      $._expression,
      optional($.string_literal),
      ";",
    ),

    file_scope_directive: $ =>
      '#scope_file',

    export_scope_directive: $ =>
      '#scope_export',

    import_statement: $ =>  prec(1, seq( // precedence over unary import
      '#import',
      field("name", $.string_literal),
      ";"
    )),

    struct_definition: $ => seq(
      "struct",
      optional("#XXX_temporary_no_type_info"),
      optional($._parameter_list),
      $.data_scope,
      optional("#no_padding")
    ),

    
   
    typed_struct_literal: $ => prec(5, seq( // precedence over member access
        $.type_instantiation,
        "." , "{",
          optional($._expression),
          "}"
      )),

    implicit_struct_literal: $ => prec(1, seq( // precedence over unary left .
      "." , "{",
      optional($._expression),
        "}"
    )),

 
    /*
    typed_compile_time_array_literal: $ => prec(5, seq( // precedence over member access
      $.type_instantiation,
      $.array_literal_op,
      optional($._expression),
        "]"
    )),
    */

    implicit_compile_time_array_literal: $ => prec(1, seq( 
      ".", "[",
      optional($._expression),
        "]"
    )),

    union_definition: $ => seq(
      "union",
      optional($._parameter_list),
      $.data_scope
    ),

    enum_definition: $ => seq(
      choice("enum", "enum_flags"),
      optional($.built_in_type),
      optional("#specified"),
      $.data_scope
    ),

    array_decl: $ => seq(
      "[",
      optional(choice($._expression, "..")),
      "]"
    ),

    
    built_in_type: $ => token(choice(
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
    )),


    
      comma_separated_args: $ => prec.right( seq( // lower than lambda ... this might be wrong
        $._expression, repeat1(prec.left( seq(",", $._expression)))
      )),

      _parameter_list: $ => seq(
        '(',
          CommaSep($.parameter),
        ')'
      ),
  
      // so if we dont have a special rule for what can go into a function header, then we end up parsing (1 + 2) as a function header.
      parameter: $ => prec(0, seq( choice(
        $.named_decl,
        $.type_instantiation),
        )),


      parenthesized_returns: $ => prec(1, seq(
        "(",
        $.parameter,
        repeat(seq(",", $.parameter)),
        ")"
      )),


      naked_returns: $ => prec.left(seq(
          $.parameter,
          repeat(seq(",", $.parameter)),
      )),

      trailing_return_types: $ =>prec.right( seq( // higher than parameter list
        "->", 
        choice(
          $.parenthesized_returns,
          $.naked_returns,
          ),
      )),

   

      function_header : $ =>  prec.left(seq(
        $._parameter_list,
        optional($.trailing_return_types),
        repeat($.trailing_directive)
      )),

      function_definition : $ => seq( // precedence over if {}
        //optional("inline"),
        $.function_header,
        $.imperative_scope,
      ),


      _operator_symbol: $=>token(choice(
        "==",
        "!=",
        "+",
        "-",
        "/",
        "*",
        "[]",
        ">",
        "<",
        ">=",
        "<="
      )),

      operator_definition: $ => seq(
        "operator",
        $._operator_symbol,
        "::",
        $.function_definition,
      ),
      
  
    block_end: $ => "}",

    data_scope: $ => seq(
      '{',
      repeat($._statement),
      $.block_end,
    ),

    imperative_scope: $ => seq(
      '{',
      repeat($._statement),
      $.block_end,
    ),


    deprecated_directive: $ => prec.left(seq(
      "#deprecated",
      optional($.string_literal),
    )),

    trailing_directive: $ =>choice(
      $.foreign_directive,
      $.deprecated_directive,
      token(choice(
      "#c_call",
      "#expand",
      "#compiler",
      "#no_abc",
      "#symmetric",
      "#runtime_support",
      "#intrinsic",
      "#modify",
      "#no_alias",
      ))  
      
      ),
  



    declarer: $ => seq(
      $._expression,
      ":",
    ),

    _initializer: $ =>prec.left( seq(
      choice(":", "="), $._expression 
    )),

    _block_initializer: $ =>prec(1, seq(
      choice(":", "="), $._expression_with_block 
    )),
  
    _type_declaration: $ =>seq(
      $.declarer,
      $.type_instantiation
    ),
    
    _typed_named_decl: $=>prec.left(seq(
        $._type_declaration, optional($._initializer),
    )),

    _implicit_named_decl: $=>prec.left(seq(
      $.declarer, $._initializer,
    )),

    named_decl: $=> prec.left(seq(
      choice(
        $._implicit_named_decl,
        $._typed_named_decl),
      repeat($.note)
    )),


    _typed_block_decl: $=> prec(1, seq(
      $._type_declaration, $._block_initializer,
    )),

    _implicit_block_decl: $=> seq(
      $.declarer, $._block_initializer,
    ),
   
    declaration_with_block: $=>prec(1, seq(
      choice(
        $._implicit_block_decl,
        $._typed_block_decl),
      repeat($.note)
    )),


     

     type_instantiation: $ => prec.left(
      seq(
        repeat(prec(10,$.unary_operator_left)),
        choice($.identifier, $.built_in_type, $.function_header), // this can be a lambda type, array, pointer_to, or type, or even a member expression
        optional("#must")
      )), 



    using_statement: $ => prec(1, seq( // precedence over unary using
      "using",
      choice(
        seq($.named_decl, ";"),
        $.expression_statement,
      )
      
    )),



    
    defer_statement: $ => seq(
      "defer",
      $._statement,
    ),


    case_statement: $ => seq(
      "case",
      optional($._expression),
      ";",
    ),

    continue_statement: $ => seq(
      "continue",
      optional($._expression), 
      ";"
      ),

    switch_statement: $ => prec(1, seq(
      "if",
      optional("#complete"),
      $.switch,
    )),

    empty_statement: $ => ";",

    push_context_statement: $ => seq(
      "push_context",
      $._expression,
      $._statement,
    ),



    return_statement: $ => seq(
      'return',
      optional($._expression),
      ';'
    ),

    break_statement: $ => seq(
      'break',
      optional($._expression),
      ';'
    ),

    relative_pointer: $ =>prec.left(seq(
      "*~",
      $._expression
    )),


  

    run_statement: $ => prec(1, seq(
      token(choice("#run", "#run_and_insert", "#add_context")),
      $._statement,
    )),

    operator_like_directive: $ => token(choice(
      "#type",
      "#import",
      "#foreign_library",
      "#foreign_system_library",
      "#char",
      "#bake_arguments",
      "#run",
      "#insert_internal",
      "#place",
      "#placeholder",
    )),

    unary_operator_left: $ => choice(
    "-", "+", "!", "*", "<<", "~", "xx", "xx,no_check", "$", 
     "inline", "using",  "..", ".",
      $.array_decl,
      $.relative_pointer,
      $.operator_like_directive,
     ),


    unary_expression: $ =>prec.right(9, seq(
      $.unary_operator_left, 
      $._expression
    )),
      


    member_access: $ => prec.left(4, seq($._expression, '.', $._expression)),
    subscript: $ => prec.left(4, seq($._expression, '[', $._expression, "]")),
    call: $ => prec.left(4, seq($._expression, '(', optional($._expression), ")")),
    switch: $ => prec.right( seq( $._expression, "==", $.imperative_scope)),

    foreign_directive: $ => prec.left(seq(
      "#foreign",
      optional(
        seq(
          $.identifier,
          optional($.string_literal)
          ),
    ))),

    _assignment_operator: $=> token(choice(
      "=", 
      "+=",
      "-=",
      "/=",
      "*=",
      "|=",
      "&=",
      "~=",
      "^=",
      "%=",
  )),

  assignment: $ => prec.right(3, seq(
    $._expression,
    $._assignment_operator, 
    $._expression,
  )),


    _tokens_high_precedence: $ => 
    token(choice(
      //"==",
      "!=",
      "||",
      "&&",
      ">",
      "<",
      ">=",
      "<=",
      "#align",
    )),


    binary_expression: $ => choice(
      $.member_access,
      $.subscript,
      $.switch,
      $.assignment,
      $.call,
      prec.left(3, seq($._expression, ".", "[", $._expression, "]")),
      prec.left(3, seq($._expression, "==", $._expression)),
      prec.left(3, seq($._expression, $._tokens_high_precedence, $._expression)),
      prec.left(2, seq($._expression, '&', $._expression)),
      prec.left(2, seq($._expression, '|', $._expression)),
      prec.left(2, seq($._expression, '^', $._expression)),
      prec.left(2, seq($._expression, '<<', $._expression)),
      prec.left(2, seq($._expression, '>>', $._expression)),
      prec.left(2, seq($._expression, '*', $._expression)),
      prec.left(2, seq($._expression, '/', $._expression)),
      prec.left(2, seq($._expression, '%', $._expression)),
      prec.left(1, seq($._expression, '+', $._expression)),
      prec.left(1, seq($._expression, '-', $._expression)),
      prec.left(1, seq($._expression, '..', $._expression)),
      // ...
    ),


    while_loop: $ =>seq(
      "while",
      $._expression,
      $._statement
    ),

    for_specifier: $=>prec.left( 6,
      seq(
        choice("<", "*"),
        optional(seq("=", $._expression))
    )),

    for_loop: $ => prec(1, seq(
      "for",
      repeat($.for_specifier),
      optional(
         seq(optional("`"), $.identifier, optional(seq(",", $.identifier)), ":"  )),
      $._expression,
      $._statement,
    )),

    // good luck lol!
    insert_lol: $ => token(seq(
      "#insert",
      /.*/,
    )),

    ternary_expression: $ => prec.left(seq(
      "ifx",
      $._expression,
      "then",
      $._expression,
      "else",
      $._expression,
    )),

    cast_expression: $ => prec.left(seq(
      "cast",
      repeat(choice(",no_check", ",trunc")),
      "(",
      $._expression,
      ")",
      $._expression
    )),

    if_directive: $ => prec.left(seq(
      "#if",
      $._expression,
      $._statement,
      optional($.else_statement)),
    ),

    if_statement: $ => prec.left(seq(
      "if",
      $._expression,
      optional("then"),
      $._statement,
      optional($.else_statement),
    )),

    else_statement: $ => seq(
      "else",
      $._statement
    ),

    _load_directive: $ => seq(
    "#load",
    $.string_literal,
    ),

    load_statement: $ => seq(
      $._load_directive,
      ";"
    ),

    array_literal: $ => seq(
      "{",
        ":",
        $.type_instantiation,
        ":",
        optional($._expression),
        optional(","),
      "}"
    ),


    program_export : $ =>prec(1, seq(
      "#program_export",
      optional($.string_literal),
      $.named_decl
    )),


    note: $ => prec.right(choice(
      choice($.note_with_args, $.note_simple)
    )),

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



  }
}
)



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