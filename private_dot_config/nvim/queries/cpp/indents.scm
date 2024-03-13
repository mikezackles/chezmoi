; extends

((namespace_definition
    body: (_ "}" @indent.end))
  @_namespace
  @indent.begin (#has-ancestor? @_namespace namespace_definition))
