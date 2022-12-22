{self, typedef', typeError}:
# Struct checking is more involved than the simpler types above.
# To make the actual type definition more readable, several
# helpers are defined below.
with builtins; let
  # checkField checks an individual field of the struct against
  # its definition and creates a typecheck result. These results
  # are aggregated during the actual checking.
  checkField = def: name: value: let
    result = def.checkType value;
  in rec {
    ok = def.checkToBool result;
    err =
      if !ok && isNull value
      then "missing required ${def.name} field '${name}'\n"
      else "field '${name}': ${def.toError value result}\n";
  };
  # checkExtraneous determines whether a (closed) struct contains
  # any fields that are not part of the definition.
  checkExtraneous = def: has: acc:
    if (length has) == 0
    then acc
    else if (hasAttr (head has) def)
    then checkExtraneous def (tail has) acc
    else
      checkExtraneous def (tail has) {
        ok = false;
        err =
          acc.err + "unexpected struct field '${head has}'\n";
      };
  # checkStruct combines all structure checks and creates one
  # typecheck result from them
  checkStruct = isClosed: def: value: let
    init = {
      ok = true;
      err = "";
    };
    extraneous = checkExtraneous def (attrNames value) init;
    checkedFields = map (
      n: let
        v =
          if hasAttr n value
          then value."${n}"
          else null;
      in
        checkField def."${n}" n v
    ) (attrNames def);
    combined =
      foldl' (
        acc: res: {
          ok = acc.ok && res.ok;
          err =
            if !res.ok
            then acc.err + res.err
            else acc.err;
        }
      )
      init
      checkedFields;
  in {
    ok =
      combined.ok
      && (
        if isClosed
        then extraneous.ok
        else true
      );
    err =
      combined.err
      + (
        if isClosed
        then extraneous.err
        else ""
      );
  };
  struct' = name: isClosed: def:
    typedef' {
      inherit name def;
      checkType = value:
        if isAttrs value
        then (checkStruct isClosed (self.attrs self.type def) value)
        else {
          ok = false;
          err = typeError name value;
        };
      toError = _: result:
        "expected '${name}'-struct, but found:\n" + result.err;
    };
in {
  struct = arg:
    if isString arg
    then struct' arg true
    else struct' "anon" true arg;

  openStruct = arg:
    if isString arg
    then struct' arg false
    else struct' "anon" false arg;
}
