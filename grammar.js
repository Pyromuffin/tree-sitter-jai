module.exports = grammar({
    name: 'jai',
    inline: $ => [$.constant_declaration, $.variable_reference, $.type_expression],
    extras: $ => [$.inline_comment, $.block_comment, /[ \n\r\t]*/],
    word: $ => $.identifier,
    
    rules: {

      source_file: $ => repeat(choice($._definition, $._import_statement, $.if_directive, $.export_scope_directive, $.file_scope_directive)),

      _expression: $ => choice(
        $.number,
        $.string_literal,
        $._binary_expression,
        $._unary_expression,
        $.cast_expression,
        $.autocast_expression,
        $.function_call,
        $.directive_call,
        $.parenthetical,
        $.built_in_type,
        $.type_directive,
        $.char_directive,
        $.uninitialized_token,
        $.identifier,
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
        $._assignment,
        $.while_loop,
        $.defer_statement,
        $.switch_statement,
        $.case_statement,
        $.continue_statement,
        $.if_directive,
        $._definition,
      ),
      

      _definition: $ => seq(choice(
        $.constant_definition,
        $.namespace_definition,
        $.struct_definition,
        $.enum_definition,
        $.function_definition,
        $.variable_decl),
        repeat($.note),
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

      type_directive: $ => seq(
        "#type",
        $.function_declaration
      ),

      import_directive: $ => seq(
        '#import',
        $.string_literal
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

      struct_definition: $ => seq(
        $.constant_declaration,
        "struct",
        $.block
      ),

      enum_member: $ =>seq(
        $.identifier,
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

      constant_definition: $ => seq(
        $.constant_declaration,
        $._expression,
        ";"
      ),

      /*
      parenthesized_return_decl: $ => seq(
        "->",
        "(",
          optional($.parameter_decl),
          repeat(seq(",", $.parameter_decl)),
        ")",
      ),
      */

      function_declaration: $ => prec.left(seq(
        "(",
          optional($._parameter_decl),
          repeat(seq(",", $._parameter_decl)),
        ")",
          optional(seq(
            "->",
            $._return_decl,
            repeat(prec.left(seq(",", $._return_decl))))
          )
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
          field("type", $.type_expression),
          seq(field("type", $.type_expression), "=", $._expression),
          seq( "=", $._expression),
        ),
      ),

      _return_decl: $ =>
      choice($.return_decl_simple, $.named_return_decl),

      return_decl_simple: $ => prec(10, $.type_expression),

      named_return_decl: $ => prec(10, seq(
        field("name", $.identifier),
        ':',
        field("type", $.type_expression),
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

      type_expression : $ => seq(
        //repeat("$"),
        repeat($.array_decl),
        repeat($.pointer_decl),
        $._expression,
      ),
    
      block: $ => seq(
        '{',
        repeat($._statement),
        '}'
      ),
  
      
      variable_decl: $ => seq(
        repeat(seq(field("names", $.identifier), ',')),
        field("name", $.identifier),
        ':',
        choice(
          field("type", $.type_expression),
          seq( field("type", $.type_expression), "=", $._expression),
          seq("=", $._expression),
          ),
        ';'
      ),
      

      using_statement: $ => seq(
        "using",
        optional(seq($.identifier, ":")),
        choice(field("type", $.type_expression), $.enum_definition),
        ';'
      ),

      _assignment: $ => choice(
        $.assignment_equal,
        $.assignment_add,
        $.assignment_multiply,
        $.assignment_subtract,
        $.assignment_divide),

      assignment_equal: $ => seq(
        $.variable_reference,
        "=",
        $._expression,
        ";"
      ),

      assignment_add: $ => seq(
        $.variable_reference,
        "+=",
        $._expression,
        ";"
      ),

      assignment_subtract: $ => seq(
        $.variable_reference,
        "-=",
        $._expression,
        ";"
      ),

      assignment_multiply: $ => seq(
        $.variable_reference,
        "*=",
        $._expression,
        ";"
      ),

      assignment_divide: $ => seq(
        $.variable_reference,
        "/=",
        $._expression,
        ";"
      ),

      defer_statement: $ => seq(
        "defer",
        $._expression,
        ";"
      ),


      case_statement: $ => seq(
        "case",
        optional($._expression),
        ";"
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
        optional($._expression),
        ';'
      ),

  
      variable_reference: $ =>
        $._expression,
  


      _unary_expression: $ => choice(
        prec.left(5, seq('-', $._expression)),
        prec.left(5, seq('!', $._expression)),
        prec.left(5, field("pointer_to", seq("*", $._expression))),
        prec.left(5, field("dereference", seq("<<", $._expression))),
        prec.left(-1, field("expand", seq("..", $._expression))),
      ),

      member_access: $ => prec.left(4, seq($._expression, '.', $._expression)),
      subscript: $ => prec.left(4, seq($._expression, '[', $._expression, "]")),
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
        field("type", $.type_expression),
        ")",
        $._expression
      )),

      autocast_expression: $ => prec.left(seq(
        "xx",
        $._expression
      )),

      function_arg: $ => seq(
      optional(seq($.identifier, "=")), $._expression
      ),

      function_args: $ => seq(
        repeat(seq($.function_arg,",")),
        $.function_arg
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

      note: $ => /@[a-zA-Z_][a-zA-Z_0-9]*/,
      identifier: $ => /[a-zA-Z_][a-zA-Z_0-9]*/,
  
      number: $ => /([\d_]+\.[\d_]+|[\d_]+|\.[\d_]+|0(h|x|X)[a-fA-F0-9_]+|0b[01_]+)/,
      
    }
  }
);