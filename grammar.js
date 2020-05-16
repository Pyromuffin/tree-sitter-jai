module.exports = grammar({
    name: 'jai',
    inline: $ => [$.variable_reference, $.type_expression],
    extras: $ => [$.inline_comment, $.block_comment, /[ \n\r\t]*/, $.note, $.compiler_directive],
    word: $ => $.identifier,
    externals: $ => [
      $.here_string_body,
    ],

    rules: {

      source_file: $ => repeat(
        $._statement,        
      ),

      _expression: $ => choice(
        $.number,
        $.string_literal,
        $._binary_expression,
        $._unary_expression,
        $.cast_expression,
        $.parenthetical,
        $.built_in_type,
        $.type_directive,
        $.char_directive,
        $.uninitialized_token,
        $.run_directive,
        $.load_directive,
        $.identifier,
        $.caller_location,
        $.func_type_decl,
        $.func_call,
        $.parameter_decl,
        $.named_arg,
        $.array_literal,
      ),

      _expression_with_block: $ => choice(
        $.func_defn,
        $.enum_definition,
        $.struct_definition,
        $.union_definition,
        $.here_string,
      ),

      _statement: $ => choice(
        $.return_statement,
        $.using_statement,
        $.if_statement,
        $.for_loop,
        $.implicit_for_loop,
        $.block,
        $._func_call_statement,
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
        $.remove_statement,
        $.empty_statement,
        $._import_statement,
        $.union_definition,
      ),
      

      _definition: $ => choice(
        $.constant_definition,
        $.namespace_definition,
        $.variable_decl,
        $.compound_variable_decl,
      ),
  
      inline_comment: $ => seq('//', /.*/),
      block_comment: $ => seq(
        '/*',
        repeat(choice(/./, $.block_comment)),
        '*/'
      ),

      here_string: $ => seq(
        "#string",
        $.here_string_body,
        //repeat(/./),
        //$.here_string_terminator,
        ),
      

      uninitialized_token: $ => "---",

      remove_statement: $ => seq(
        "remove",
        $._expression,
        ";"
      ),

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

      type_directive: $ => prec.left(seq(
        "#type",
        $._expression
      )),

      import_directive: $ => seq(
        '#import',
        field("name", $.string_literal)
      ),

      file_scope_directive: $ =>
        '#scope_file',

      export_scope_directive: $ =>
        '#scope_export',

      
      _import_statement: $ => seq(
        $.import_directive, ";"
      ),
      
      struct_definition: $ => seq(
        optional("*"),
        "struct",
        $.block
      ),

      union_definition: $ => seq(
        optional("*"),
        "union",
        $.block
      ),

      enum_member: $ =>seq(
        field("name", $.identifier),
        optional(
          seq( choice("=", "::"), $._expression)),
          ";"
      ),

      // slightly higher precedence so that we prefer this to identifier :: enum_declaration expressions.
      enum_definition: $ => seq(
        choice("enum", "enum_flags"),
        optional($._expression),
        "{",
          repeat($.enum_member),
        "}"
      ),

      namespace_definition: $ => seq(
        $._constant_declaration,
        $._import_statement,
      ),

      _constant_declaration: $ => seq(
        field("name", $.identifier),
        ':',
        optional($.type_expression),
        ':'
      ),

      constant_definition: $ => seq(
        $._constant_declaration,
        choice(
          seq($._expression, ";"),
          $._expression_with_block,
        )
      ),
      
  
      relative_pointer_decl: $ => prec.left(seq(
        "*~",
        $.type_expression
      )),

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

      named_arg: $ =>prec(-1,seq(
        $.identifier,
        "=",
        $._expression,
      )),

      func_call: $ =>prec(1, seq(
        $._expression,
        $._enclosed_expression_list,
        )),
        
        _func_call_statement: $ => seq(
          $.func_call,
          ";"
        ),

        _expr_list: $ => prec.left(seq(
          $._expression,
          repeat(prec.left(seq(",", $._expression))),
        )),

        _enclosed_expression_list : $ => seq(
          "(",
          optional($._expression),
          repeat(seq(",", $._expression)),
          ")",
        ),

        trailing_return_types: $ => prec(1,seq(
          "->",
          choice($._expr_list, $._enclosed_expression_list)
        )),

        func_type_decl : $ => prec.left(seq(
          $._enclosed_expression_list,
          optional($.trailing_return_types),
          repeat(prec.left(choice($._directive_with_expression, $.compiler_directive)))
        )),

        func_defn : $ => seq(
          optional("inline"),
          $.func_type_decl,
          $.block,
        ),
        
      type_expression : $ => seq(
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
          $._expression_with_block,
          seq( $.type_expression, "=", $._expression),
          seq("=", $._expression),
          ),
        ';'
      ),
      
      parameter_decl: $ => prec.left(-1, seq(
        field("name", $.identifier),
        ':',
        choice(
          $.type_expression,
          seq( $.type_expression, "=", $._expression),
          seq("=", $._expression),
          )
      )),

      _expression_list: $ => seq(
        field("name", $._expression),
        repeat1(seq(",", field("name", $._expression)))
      ),

      compound_variable_decl: $ => seq(
        field("names", $._expression_list),
        ":",
        choice(
          $.type_expression,
          seq( $.type_expression, "=", choice($._expression_list, $.func_call)),
          seq("=", choice($._expression_list, $.func_call)),
          ),
        ';'
      ),

      using_statement: $ => seq(
        "using",
        choice(
          seq($._expression, ";"),
           $._expression_with_block,
           $._definition,
           ),
      ),

      compound_assignment: $ => prec.left(seq(
          $._expression_list,
          "=",
          choice($._expression_list, $.func_call),
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

      empty_statement: $ => ";",


      return_statement: $ => seq(
        'return',
        optional($._expr_list),
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
        prec.left(5, field("polymorph", seq("$", $._expression))),
        prec.left(5, field("using", seq("using", $._expression))),
        prec.left(5, field("must", seq($._expression, "#must"))),
        prec.left(5, seq($.array_decl, $._expression)),
        prec.left(5, seq($.relative_pointer_decl, $._expression)),
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

      cast_expression: $ => prec.left(seq(
        field("name", "cast"),
        optional(",no_check"),
        "(",
        $.type_expression,
        ")",
        $._expression
      )),

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

      add_context: $ => seq(
        "#add_context",
        $._statement,
      ),

      foreign_directive: $ => prec.left(seq(
        "#foreign",
        optional(seq($._expression, optional($.string_literal))),
      )),

      deprecated_directive: $ => prec.left(seq(
        "#deprecated",
        $.string_literal,
      )),

      _directive_with_expression: $ =>prec.left(choice(
        $.foreign_directive,
        $.deprecated_directive,
        $.run_directive,
        seq($.compiler_directive, $._expression),
      )),

      array_literal: $ => seq(
        "{",
          ":",
          $._expression,
          ":",
          optional($._expression),
          repeat(seq(",", $._expression)),
          optional(","),
        "}"
      ),

      compiler_directive: $ =>  /\#[a-zA-Z_][a-zA-Z_0-9]*/,
      note: $ => /@[a-zA-Z_][a-zA-Z_0-9]*/,
      identifier: $ => /[a-zA-Z_][a-zA-Z_0-9]*/,
  
      number: $ => /([\d_]+\.[\d_]+|[\d_]+|\.[\d_]+|0(h|x|X)[a-fA-F0-9_]+|0b[01_]+)/,
      
    }
  }
);