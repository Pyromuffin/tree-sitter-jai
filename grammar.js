module.exports = grammar({
    name: 'jai',
    inline: $ => [$.constant_declaration, $.variable_reference, $.type_expression],
    extras: $ => [$.inline_comment, $.block_comment, /[ \n\r\t]*/, $.note],
    word: $ => $.identifier,
    

    rules: {

      source_file: $ => repeat(choice(
        $._definition,
        $._import_statement,
        $.if_directive,
        $.load_statement,
        $.export_scope_directive,
        $.file_scope_directive,
        $.assert_statement,
      )),

      _expression: $ => choice(
        $.number,
        $.string_literal,
        $._binary_expression,
        $._unary_expression,
        $.cast_expression,
        $.function_call,
        $.directive_call,
        $.parenthetical,
        $.built_in_type,
        $.type_directive,
        $.char_directive,
        $.uninitialized_token,
        $.run_directive,
        $.load_directive,
        $.identifier,
        $.caller_location
        // TODO: other kinds of expressions
      ),

      _statement: $ => choice(
        $.return_statement,
        $.using_statement,
        $.if_statement,
        $.for_loop,
        $.implicit_for_loop,
        $.block,
        $.function_call_statement,
        $.assignment,
        $.compound_assignment,
        $.while_loop,
        $.defer_statement,
        $.switch_statement,
        $.case_statement,
        $.continue_statement,
        $.if_directive,
        $._definition,
        $.break_statement,
        $.load_statement,
        $.backtick_statement,
        $.assert_statement,
      ),
      

      _definition: $ => choice(
        $.constant_definition,
        $.namespace_definition,
        $.struct_definition,
        $.enum_definition,
        $.function_definition,
        $.macro_definition,
        $.variable_decl,
        $.type_definition,
        $.compound_variable_decl,
      ),
  
      inline_comment: $ => seq('//', /.*/),
      block_comment: $ => seq(
        '/*',
        repeat(/./),
        '*/'
      ),

      uninitialized_token: $ => "---",

      char_directive: $ => seq(
        "#char",
        $.string_literal,
      ),

      string_literal: $ => seq(
        '"',
        repeat(choice(/./, '\\"')),
        '"'
      ),

      backtick_statement: $ => seq(
        "`",
        $._statement
      ),

      caller_location: $ => "#caller_location",

      type_directive: $ => seq(
        "#type",
        $.function_declaration
      ),

      import_directive: $ => seq(
        '#import',
        field("name", $.string_literal)
      ),

      file_scope_directive: $ => seq(
        '#scope_file'
      ),

      export_scope_directive: $ => seq(
        '#scope_export'
      ),


      
      _import_statement: $ => seq(
        $.import_directive, ";"
      ),
      
      function_definition: $ => seq(
        $.constant_declaration,
        $.function_declaration,
        $.block
      ),

      macro_definition: $ => seq(
        $.constant_declaration,
        $.macro_declaration,
        $.block
      ),


      type_definition: $ => seq(
        $.constant_declaration,
        $.type_expression,
        ";"
      ),

      struct_definition: $ => seq(
        $.constant_declaration,
        "struct",
        $.block
      ),

      enum_member: $ =>seq(
        field("name", $.identifier),
        optional(
          seq("=", $._expression)),
          ";"
      ),

      enum_definition: $ => seq(
        "enum",
        "{",
        repeat($.enum_member),
        "}"
      ),

      namespace_definition: $ => seq(
        $.constant_declaration,
        $._import_statement,
      ),

      constant_declaration: $ => seq(
        field("name", $.identifier),
        ':',
        optional($.type_expression),
        ':'
      ),

      constant_definition: $ => prec(1, seq(
        $.constant_declaration,
        $._expression,
        ";"
      )),


      _return_sequence: $ =>prec.left(
      seq(
        "->",
        optional("("),
        $._return_decl,
        repeat(seq(",", $._return_decl)),
        optional(")")
        )),

      function_declaration: $ => prec.left(seq(
        optional("inline"),
        "(",
          optional($._parameter_decl),
          repeat(seq(",", $._parameter_decl)),
        ")",
        optional($._return_sequence),
        optional("#compiler") // no idea what this does. 
      )),

      macro_declaration: $ => prec.left(seq(
        "(",
          optional($._parameter_decl),
          repeat(seq(",", $._parameter_decl)),
        ")",
          optional($._return_sequence),
          "#expand"
      )),

      _parameter_decl: $ =>
      choice($.parameter_decl_simple, $.named_parameter_decl),

      parameter_decl_simple: $ => $.type_expression,

      named_parameter_decl: $ => seq(
        optional(choice(
          field("maybe_constant", "$$"),
          field("constant_type", "$")
          )),
        field("name", $.identifier),
        ':',
        optional(".."),
        choice(
          $.parameter_type_expression,
          seq($.parameter_type_expression, "=", $._expression),
          seq( "=", $._expression),
        ),
      ),

      _return_decl: $ =>prec.left(seq(
      choice($.return_decl_simple, $.named_return_decl),
      optional("#must"),
      )),

      return_decl_simple: $ => prec(10, $.type_expression),

      named_return_decl: $ => prec(10, seq(
        field("name", $.identifier),
        ':',
        $.type_expression,
      )),


  
      array_decl: $ => seq(
        "[",
        optional(choice($._expression, "..")),
        "]"
      ),

      pointer_decl: $ => "*",

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
        'enum',
        'enum_flags',
        "Any"
      ),

      parameter_type_expression : $ => seq(
        repeat(choice($.array_decl, $.pointer_decl, "$")),
        $._expression,
      ),

      type_expression : $ => seq(
        repeat(choice($.array_decl, $.pointer_decl)),
        $._expression,
      ),
    
      block: $ => seq(
        '{',
        repeat($._statement),
        '}'
      ),
  
      
      variable_decl: $ => seq(
        field("name", $.identifier),
        ':',
        choice(
          $.type_expression,
          seq( $.type_expression, "=", $._expression),
          seq("=", $._expression),
          ),
        ';'
      ),
      
      _expression_list: $ => seq(
        field("name", $._expression),
        repeat1(seq(",", field("name", $._expression)))
      ),

      compound_variable_decl: $ => seq(
        field("names", $._expression_list),
        ":",
        choice(
          $.type_expression,
          seq( $.type_expression, "=", $._expression),
          seq("=", $._expression),
          ),
        ';'
      ),

      using_statement: $ => seq(
        "using",
        optional(seq(field("name", $.identifier), ":")),
        choice($.type_expression, $.enum_definition),
        ';'
      ),

      compound_assignment: $ => prec.left(seq(
          $._expression_list,
          "=",
          $._expression,
          ";"
        )),

      assignment: $ => choice(
        seq( $.variable_reference, "=", $._expression, ";"),
        seq( $.variable_reference, "+=", $._expression, ";"),
        seq( $.variable_reference, "-=", $._expression, ";"),
        seq( $.variable_reference, "/=", $._expression, ";"),
        seq( $.variable_reference, "*=", $._expression, ";"),
        seq( $.variable_reference, "|=", $._expression, ";"),
        seq( $.variable_reference, "&=", $._expression, ";"),
        seq( $.variable_reference, "~=", $._expression, ";"),
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
        ";"
        ),

      switch_statement: $ => seq(
        "if",
        optional("#complete"),
        $._expression,
        "==",
        $.block
      ),


      return_statement: $ => seq(
        'return',
        optional(seq($._expression, repeat(seq(",", $._expression)))),
        ';'
      ),

      break_statement: $ => seq(
        'break',
        ';'
      ),

  
      variable_reference: $ =>
        $._expression,

      _unary_expression: $ => choice(
        prec.left(5, seq('-', $._expression)),
        prec.left(5, seq('!', $._expression)),
        prec.left(5, field("pointer_to", seq("*", $._expression))),
        prec.left(5, field("dereference", seq("<<", $._expression))),
        prec.left(5, field("bitwise_not", seq("~", $._expression))),
        prec.left(5, field("bitwise_not", seq("~", $._expression))),
        prec.left(5, field("autocast", seq("xx", $._expression))),
        prec.left(5, field("inline", seq("inline", $._expression))),
        prec.left(-1, field("expand", seq("..", $._expression))),
      ),

      member_access: $ => prec.left(6, seq($._expression, '.', $._expression)),
      subscript: $ => prec.left(6, seq($._expression, '[', $._expression, "]")),
      range: $ => prec.left(0, seq($._expression, '..', $._expression)),

      _binary_expression: $ => choice(
        $.range,
        $.member_access,
        $.subscript,
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

      for_loop: $ => seq(
        "for",
        field("name", $.identifier),
        optional(seq(",", field("names", $.identifier))),
        ":",
        $._expression,
        $._statement,
      ),

      implicit_for_loop: $ => seq(
        "for",
        $._expression,
        $._statement,
      ),

      directive_call: $=> seq(
        "#",
        $.identifier,
        "(",
        optional($.function_args),
        ")"
      ),

      cast_expression: $ => prec.left(seq(
        field("name", "cast"),
        optional(",no_check"),
        "(",
        $.type_expression,
        ")",
        $._expression
      )),


      _function_arg: $ => seq(
      optional(seq($.identifier, "=")), $._expression
      ),

      function_args: $ => seq(
        repeat(seq($._function_arg,",")),
        $._function_arg
      ),


      function_call: $ => seq(
        field("name", $.variable_reference),
        "(",
        optional($.function_args),
        ")"
      ),

      function_call_statement: $ => seq(
        $.function_call,
        ";"
      ),


      parenthetical: $ => prec(-1, seq(
        "(",
        $._expression,
        ")"
      )),

      run_directive: $ => prec.left(seq(
        "#run",
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

      load_directive: $ => seq(
      "#load",
      field("name", $.string_literal)
      ),

      load_statement: $ => seq(
        $.load_directive,
        ";"
      ),

      assert_statement: $ => seq(
        "#assert",
        "(",
        $._expression,
        ")",
        ";"
      ),


      note: $ => /@[a-zA-Z_][a-zA-Z_0-9]*/,
      identifier: $ => /[a-zA-Z_][a-zA-Z_0-9]*/,
  
      number: $ => /([\d_]+\.[\d_]+|[\d_]+|\.[\d_]+|0(h|x|X)[a-fA-F0-9_]+|0b[01_]+)/,
      
    }
  }
);