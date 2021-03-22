#comment_tokenizer comment_tokenizer() {

    note("TODO ", todo)
    note("FIX ", fix)
    note("WIP ", wip)

    block_comment("@@", "@@")
    line_comment("@")
}

#number_tokenizer number_tokenizer() {

    system(binary, '0', '1')
    system(decimal, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
    system(duodecimal, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'X', 'E')
    system(hexadecimal, '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')

    format(decimal, $none, $none)

    format(binary, "0b", $none)
    format(decimal, "0d", $none)
    format(duodecimal, "0z", $none)
    format(hexadecimal, "0x", $none)

    format(binary, $none, "B")
    format(decimal, $none, "D")
    format(duodecimal, $none, "Z")
    format(hexadecimal, $none, "X")

    float('.')
}

#character_tokenizer character_tokenizer() {

    delimiter("\'", "\'")

    replace("null", '\0')
    replace("backslash", '\\')
    replace("backspace", '\b')
    replace("character", '\'')
    replace("string", '\"')
    replace("newline", '\n')
    replace("tab", '\t')
    replace("return", '\r')
    replace("escape", '\e')
    replace("open", '{')
    replace("close", '}')
}

#string_tokenizer string_tokenizer() {

    delimiter("\"", "\"")

    replace("{null}", '\0')
    replace("{backslash}", '\\')
    replace("{backspace}", '\b')
    replace("{character}", '\'')
    replace("{string}", '\"')
    replace("{newline}", '\n')
    replace("{tab}", '\t')
    replace("{return}", '\r')
    replace("{escape}", '\e')
    replace("{open}", '{')
    replace("{close}", '}')
}

#operator_tokenizer operator_tokenizer() {

    translate("==", equals)
    translate("!=", not_equals)
    translate(">=", grater_equal)
    translate("<=", smaller_equal)
    translate(":=", assign)
    translate("+=", add_assign)
    translate("-=", subtract_assign)
    translate("/=", divide_assign)
    translate("*=", multiply_assign)
    translate("&=", and_assign)
    translate("|=", or_assign)
    translate("^=", xor_assign)
    translate("%=", modulo_assign)
    translate("^^", logical_xor)
    translate("||", logical_or)
    translate("&&", logical_and)
    translate("::", contains)
    translate("->", case)
    translate('>', bigger)
    translate('<', smaller)
    translate('+', add)
    translate('-', subtract)
    translate('/', divide)
    translate('*', multiply)
    translate('|', or)
    translate('&', and)
    translate('!', invert)
    translate('~', concatinate)
    translate('^', xor)
    translate('%', modulo)
    translate('?', macro)
    translate('{', open_curly)
    translate('}', close_curly)
    translate('(', open_round)
    translate(')', close_round)
    translate('[', open_square)
    translate(']', close_square)
    translate('#', selector)
    translate('$', image)
    translate(':', colon)
    translate(',', comma)
    translate('.', dot)

    ignored('\r', '\t', '\n', ' ')
    invalid('\\', ';', '=')
}

#keyword_tokenizer keyword_tokenizer() {

    translate(true, true)
    translate(false, false)
    translate(public, public)
    translate(label, label)
    translate(loop, loop)
    translate(while, while)
    translate(iterate, iterate)
    translate(if, if)
    translate(else, else)
    translate(module, module)
    translate(namespace, namespace)
    translate(import, import)
    translate(export, export)
    translate(case, case)
    translate(alias, alias)
    translate(macro, macro)
    translate(match, match)
    translate(trait, trait)
    translate(any, any)
    translate(implement, implement)
    translate(derive, derive)
    translate(structure, structure)
    translate(enumeration, enumeration)
    translate(native, native)
    translate(not, not)
    translate(as, as)
    translate(for, for)
    translate(return, return)
    translate(pass, pass)
    translate(terminate, terminate)
    translate(continue, continue)
    translate(break, break)
    translate(final, final)
    translate(mutable, mutable)
    translate(implied, implied)
    translate(self, self)
    translate(super, super)
    translate(root, root)
    translate(base, base)
    translate(scope, scope)
}

#identifier_tokenizer identifier_tokenizer() {

    type_prefix($alphabet_upper_case)
    type_prefix(_)

    prefix($alphabet_lower_case)
    prefix(_)
}
