; locals.scm

(block) @local.scope
(source_file) @local.scope
(variable_decl name: (identifier) @local.definition)
(variable_decl names: (identifier) @local.definition)
(implicit_variable_decl name: (identifier) @local.definition)
(parameter_decl name: (identifier) @local.definition)
(for_loop name: (identifier) @local.definition)
(for_loop names: (identifier) @local.definition)
(constant_value_definition name: (identifier) @local.definition)
(struct_decl name: (identifier) @local.definition)
(function_definition name: (identifier) @local.definition)

(identifier) @local.reference