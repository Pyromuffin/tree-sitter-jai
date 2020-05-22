module.exports = grammar({
    name: 'jai',
    inline: $ => [$.type_expression],
    extras: $ => [$.inline_comment, $.block_comment, /[ \n\r\t]*/, $.note, $.compiler_directive_simple],
    word: $ => $.identifier,
    externals: $ => [
      $.here_string_body,
    ],

    conflicts: $ =>[
      //[$.argument_list, $.parameter_list], 
      [$.function_pointer_type, $.parameter_list],
      [$.function_pointer_type, $.parenthesis],
      [$.lambda_identifiers, $._expression]

    ],

    rules: {

      source_file: $ => repeat(
        choice(

          $._statement,
        )),


        expression_like_directive: $ => choice(
          "#caller_location",
          "#location",
          "#file",
          "#line",
        ),
        // anonymous functions can only exist as r-values.

      _expression: $ => choice(
        $.number,
        $.scientific_notation,
        $.string_literal,
        $._binary_expression,
        $._unary_expression,
        $.cast_expression,
        $.parenthesis,
        $.built_in_type,
        $.uninitialized_token,
        $.identifier,
        $.func_call,
        $.array_literal,
        $._expression_with_block,
        $.quick_lambda,
        $.expression_like_directive,
        $.type_directive,
      ),

      parenthesis: $ => seq(
        "(",
        $._expression, // not optional as an expression!
        ")",
      ),
      

      _expression_with_block: $ => choice(
        $.function_definition,
        $.enum_definition,
        $.struct_definition,
        $.union_definition,
        $.here_string,
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
        $.block,
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
        $.assignment,
        $.push_context_statement,
        $._expression_statement,
        $.named_block_decl,
        $.named_decl,
        $._type_definition,
        $.directive_statement,
        $.insert_lol,
        $.operator_definition,
        $.import_statement,
        $.file_scope_directive,
        $.export_scope_directive,
        $.program_export,
      ),
  
      _expression_statement: $ => seq( $._expression, ";"),
  
  
      inline_comment: $ => seq('//', /.*/),
      block_comment: $ => seq(
        '/*',
        repeat(choice(/./, $.block_comment)),
        '*/'
      ),

      here_string: $ => seq(
        "#string",
        $.here_string_body,
        ),
      
        lambda_identifiers: $ =>seq(
          "(",
          CommaSep($.identifier),
          ")"
        ),

        lambda_header: $=> choice(
          $.identifier,
          $.lambda_identifiers,
        ),

      quick_lambda: $ => prec.left(seq(
        $.lambda_header,
        "=>",
        $._expression,
      )),

      uninitialized_token: $ => "---",

      remove_statement: $ => seq(
        "remove",
        $._expression,
        ";"
      ),

      escape_sequence: $ => /\\./,
      normal_char: $=> /./,

      string_literal: $ => seq(
        '"',
        repeat(choice(/./, /\\./, "//", "/*", "*/")),
        '"'
      ),

      backtick_statement: $ => seq(
        "`",
        $._statement
      ),


      file_scope_directive: $ =>
        '#scope_file',

      export_scope_directive: $ =>
        '#scope_export',

      import_statement: $ =>  seq(
        '#import',
        field("name", $.string_literal),
        ";"
      ),

      struct_definition: $ => seq(
        "struct",
        optional($.parameter_list),
        $.block,
      ),

      union_definition: $ => seq(
        "union",
        optional($.parameter_list),
        $.block
      ),

      enum_definition: $ => seq(
        choice("enum", "enum_flags"),
        optional($._expression),
        $.block
      ),

      array_decl: $ => seq(
        "[",
        optional(choice($._expression, "..")),
        "]"
      ),

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


        argument_name: $ => seq(
          $.identifier,
          "="
        ),

        argument: $ => prec(1, seq(
          optional($.argument_name),
          $._expression,
        )),

        argument_list: $ =>prec(1, seq(
          "(",
          CommaSep($.argument),
          ")",
        )),

        func_call: $ =>seq(
          $._expression,
          $.argument_list,
        ),
          
        
        return_type: $ => prec.left(1, 
          choice(
            $.type_expression,
            seq(
              $.identifier,
              ":",
              choice(
                $.type_expression,
                seq(optional($.type_expression), $.default_value),
              ),
            )),
        ),

        return_type_list: $ => prec.left(CommaSep1($.return_type)),

        parenthesized_return_type_list: $ => prec(1, seq(
          "(",
          CommaSep($.return_type),
          ")"
        )),


        trailing_return_types: $ => seq(
          "->",
          choice(
            $.return_type_list,
            $.parenthesized_return_type_list
            ),
        ),

        default_value: $ =>prec.left( seq(
          "=",
          $._expression
        )),

        parameter: $ => seq(
          $._expression,
          ":",
          choice(
            $.type_expression,
            seq(optional($.type_expression), $.default_value),
            ),
        ),

        parameter_list: $ => seq(
          "(",
          CommaSep($.parameter),
          ")",
        ),

        function_header : $ =>  seq(
          $.parameter_list,
          optional($.trailing_return_types),
          repeat($.trailing_directive)
        ),

        function_definition : $ => seq(
          $.function_header,
          choice(
            $.block,
            ";"
            ),
        ),

        type_directive: $=>prec.left( seq(
          "#type",
          $.type_expression,
        )),


        _operator_symbol: $=>choice(
          "==",
          "+",
          "-",
          "/",
          "*",
          "[]",
        ),
  
        operator_definition: $ => seq(
          "operator",
          $._operator_symbol,
          "::",
          $.function_definition,
        ),
        
      type_expression : $ =>
      choice(
        $._expression,
        $.function_pointer_type
      ),
      
    
      block: $ => seq(
        '{',
        repeat($._statement),
        '}'
      ),

      directive_with_expression: $ => prec.left(seq(
        $.compiler_directive_simple,
        repeat1(prec.left($._expression)),
      )),

      trailing_directive: $ =>prec.left(
        choice($.directive_with_expression, $.compiler_directive_simple)),
    

      function_pointer_type: $ => prec.left( seq(
        "(",
          CommaSep(choice(
            $._expression,
            $.parameter,
          )),
        ")",
        optional($.trailing_return_types),
        repeat($.trailing_directive)
      )),

      named_block_decl: $ => prec(1, seq( // precedence over named decl
        $._expression,
        ":",
        optional($.type_expression), 
        choice("=", ":"),
        optional("inline"),
        $._expression_with_block
      )),
      

      named_decl: $ => seq(
        CommaSep1($._expression),
        ":",
        choice(
          $.type_expression,
          seq(optional($.type_expression), choice("=", ":"), CommaSep1($._expression)),
          ),
          ";",
      ),

      using_statement: $ => prec(1, seq( // precedence over unary using
        "using",
        choice(
          $.named_decl,
          $.named_block_decl,
          $._expression_statement,
        )
      )),


      _assignment_operator: $=> choice(
            "=", 
            "+=",
            "-=",
            "/=",
            "*=",
            "|=",
            "&=",
            "~=",
            "^="
        ),

      assignment: $ => seq(
        CommaSep1($._expression),
        $._assignment_operator, 
        CommaSep1($._expression),
        ";"
        ),
  
      
      defer_statement: $ => seq(
        "defer",
        $._statement,
      ),


      case_statement: $ => seq(
        "case",
        optional($._expression),
        ";",
        optional(seq("#through", ";"))
      ),

      continue_statement: $ => seq(
        "continue",
        optional($._expression), 
        ";"
        ),

      switch_statement: $ => seq(
        "if",
        $._expression,
        "==",
        $.block
      ),

      empty_statement: $ => ";",

      push_context_statement: $ => seq(
        "push_context",
        $._expression,
        $._statement,
      ),

      named_return: $ => seq(
        $.identifier,
        "=",
        $._expression,
      ),

      return_statement: $ => seq(
        'return',
        choice(
          CommaSep($._expression),
          CommaSep1($.named_return),
          ),
        ';'
      ),

      break_statement: $ => seq(
        'break',
        ';'
      ),

      relative_pointer: $ =>prec.left(seq(
        "*~",
        $._expression
      )),

      unary_operator_left: $ => choice(
      "-", "!", "*", "<<", "~", "xx", "xx,no_check",
       "inline", "$", "using", $.array_decl, "..", ".", $.relative_pointer
       ),

       _unary_expression: $ =>
       choice($._unary_expression_left, $._unary_expression_right),

      _unary_expression_left: $ =>prec.right(seq(
        $.unary_operator_left, 
        $._expression
      )),
        
      unary_operator_right: $ => choice(
        "#must"
         ),
  
        _unary_expression_right: $ =>prec.left(seq(
          $._expression,
          $.unary_operator_right, 
        )),
          
        
      member_access: $ => prec.left(4, seq($._expression, '.', $._expression)),
      subscript: $ => prec.left(4, seq($._expression, '[', $._expression, "]")),

      _binary_expression: $ => choice(
        $.member_access,
        $.subscript,
        prec.left(3, seq($._expression, '#align', $._expression)),
        prec.left(3, seq($._expression, '==', $._expression)),
        prec.left(3, seq($._expression, '!=', $._expression)),
        prec.left(3, seq($._expression, '||', $._expression)),
        prec.left(3, seq($._expression, '&&', $._expression)),
        prec.left(3, seq($._expression, '>', $._expression)),
        prec.left(3, seq($._expression, '<', $._expression)),
        prec.left(3, seq($._expression, '>=', $._expression)),
        prec.left(3, seq($._expression, '<=', $._expression)),
        prec.left(2, seq($._expression, '&', $._expression)),
        prec.left(2, seq($._expression, '|', $._expression)),
        prec.left(2, seq($._expression, '^', $._expression)),
        prec.left(2, seq($._expression, '<<', $._expression)),
        prec.left(2, seq($._expression, '>>', $._expression)),
        field("multiply", prec.left(2, seq($._expression, '*', $._expression))),
        field("divide", prec.left(2, seq($._expression, '/', $._expression))),
        field("mod", prec.left(2, seq($._expression, '%', $._expression))),
        field("add", prec.left(1, seq($._expression, '+', $._expression))),
        field("sub", prec.left(1, seq($._expression, '-', $._expression))),
        // ...
      ),


      while_loop: $ =>seq(
        "while",
        $._expression,
        $._statement
      ),

      range: $ => prec.right(seq(
        $._expression,
        optional(
          seq('..', $._expression))
        )),

      for_specifier: $=>prec.left( 6,
        seq(
          choice("<", "*"),
          optional(seq("=", $._expression))
      )),

      for_loop: $ => seq(
        "for",
        repeat($.for_specifier),
        optional(seq(
           seq(optional("`"), CommaSep1($.identifier)),
            ":")),
        $.range,
        $._statement,
      ),

      // good luck lol!
      insert_lol: $ => seq(
        "#insert",
        /.*/,
      ),


      cast_expression: $ => prec.left(seq(
        "cast",
        repeat(choice(",no_check", ",trunc")),
        "(",
        $._expression,
        ")",
        $._expression
      )),

 
      directive_statement: $ => seq(
        $.compiler_directive_simple,
        $._statement
      ),

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

      /*
      load_directive: $ => seq(
      "#load",
      field("name", $.string_literal)
      ),

      load_statement: $ => seq(
        $.load_directive,
        ";"
      ),
    */


      array_literal: $ => seq(
        "{",
          ":",
          $._expression,
          ":",
          CommaSep($._expression),
          optional(","),
        "}"
      ),


      program_export : $ =>prec(1, seq(
        "#program_export",
        optional($.string_literal),
        choice($.named_block_decl, $.named_decl)
      )),

      compiler_directive: $ => choice(
        $.compiler_directive_simple,
        $.compiler_directive_call,
      ),

      compiler_directive_simple: $ => /\#[a-zA-Z_][a-zA-Z_0-9]*/,
        
      compiler_directive_call: $ => seq(
        $.compiler_directive_simple,
        $.argument_list,
      ),


      note: $ => /@[a-zA-Z_][a-zA-Z_0-9]*/,
      identifier: $ => /[a-zA-Z_][a-zA-Z_0-9]*/,
  
      number: $ => /\d[\d_]*\.\d+|\d[\d_]*|\.\d[\d_]*|0(h|x|X)[a-fA-F0-9_]+|0b[01_]+/,
      scientific_notation: $ => seq(
        $.number,
        "e",
        choice("+","-"),
        $.number,
        )
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