#templates {

    boolean template(resolve[resolve:boolean]) {
        [ keyword(true) | state := $!true ]
        [ keyword(false) | state := $!false ]
    }

    integer template(resolve[resolve:number]) {
        [ operator(subtract) | negative := $!true | value := integer() ]
        [ negative := $!false | value := integer() ]
    }

    float template(resolve[resolve:number]) {
        [ operator(subtract) | negative := $!true | value := float() ]
        [ negative := $!false | value := float() ]
    }

    immediate template(infer[infer:immediate], resolve[resolve:immediate]) {
        [ value := template(boolean) | type := template(boolean_type_data) ]
        [ value := template(integer) | type := template(integer_type_data) ]
        [ value := template(float) | type := template(float_type_data) ]
        [ value := character() | type := template(character_type_data) ]
        [ value := string() | type := template(string_type_data) ]
    }

    arithmatic_operator template() {
        [ operator(bigger) | operator(bigger) | operator := $shift_left ]
        [ operator(smaller) | operator(smaller) | operator := $shift_right ]
        [ operator := operator(bigger) ]
        [ operator := operator(smaller) ]
        [ operator := operator(add) ]
        [ operator := operator(subtract) ]
        [ operator := operator(divide) ]
        [ operator := operator(multiply) ]
        [ operator := operator(and) ]
        [ operator := operator(or) ]
        [ operator := operator(xor) ]
    }

    reassignment_operator template() {
        [ operator := operator(assign) ]
        [ operator := operator(add_assign) ]
        [ operator := operator(subtract_assign) ]
        [ operator := operator(divide_assign) ]
        [ operator := operator(multiply_assign) ]
        [ operator := operator(and_assign) ]
        [ operator := operator(or_assign) ]
        [ operator := operator(xor_assign) ]
    }

    logical_operator template() {
        [ operator := operator(logical_xor) ]
        [ operator := operator(logical_or) ]
        [ operator := operator(logical_and) ]
        [ operator := operator(equals) ]
        [ operator := operator(not_equals) ]
    }

    mutability template() {
        [ mutability := keyword(mutable) ]
        [ mutability := keyword(final) ]
        [ mutability := keyword(implied) ]
    }

    mutability_prefix template() {
        [ merge(mutability) ]
        [ ]
    }

    default_value template() {
        [ operator(assign) | default_value := template(instance) ]
        [ ]
    }

    parameter template(infer[infer:parameter]) {
        [ merge(mutability_prefix) | name := identifier() | operator(colon) | type := template(type) | merge(default_value) ]
        [ merge(mutability_prefix) | name := identifier() | type := template(infered_type) | merge(default_value) ]
        [ merge(mutability_prefix) | type := template(type) | merge(default_value) ]
        [ template(self_parameter) ]
        [ template(tuple_expansion) ]
    }

    tuple_expansion template() {
        [ operator(open_round) | list(template(parameter, tuple_expansion), operator(comma)) | operator(close_round) ]
    }

    self_parameter template() {
        [ merge(mutability) | keyword(self) ]
        [ operator(image) | keyword(self) ]
        [ operator(and) | keyword(self) ]
        [ keyword(self) ]
    }

    parameter_list template() {
        [ operator(open_round) | parameters := list(template(parameter), operator(comma)) | operator(close_round) ]
        [ operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    function_start template() {
        [ type_identifier(Function) | merge(template_list) | merge(parameter_list) ]
    }

    function_type template(infer[infer:function_type], resolve[resolve:function_type]) {
        [ intrinsic := $function | merge(function_start) | operator(case) | return_type := template(type) ]
        [ intrinsic := $function | merge(function_start) | operator(case) | keyword(not) | return_type := template(type_not) ]
        [ intrinsic := $function | merge(function_start) | return_type := template(type_none) ]
    }

    redirect template() {
        [ type_identifier := type_identifier() | merge(subtype_list) | operator(contains) ]
        [ identifier := identifier() | operator(contains) ]
    }

    redirection [
        [ [ #keyword [ any ] ] [ #merge [ subtype_list ] ] [ #operator [ contains ] ] [ #list [ #template [ redirect ] ] ] ]
        [ [ #keyword [ any ] ] [ #merge [ subtype_list ] ] [ #operator [ contains ] ]                                      ]
        [                                                                             [ #list [ #template [ redirect ] ] ] ]
        [                                                                                                                  ]
    ]

    tuple_type_field template() {
        [ name := identifier() | operator(colon) | type := template(type) ]
        [ type := template(type) ]
    }

    tuple_type template(infer[infer:tuple_type]) {
        [ operator(open_round) | fields := list(template(tuple_type_field), operator(comma)) | operator(close_round) ]
    }

    integer_type template(infer[infer:integer_type]) {
        [ size := integer() ]
    }

    any_type template() {
        [ keyword(any) | merge(subtype_list) ]
    }

    reference_type template(infer[infer:reference_type]) {
        [ merge(redirection) | identifier := type_identifier() | merge(subtype_list) ]
    }

    real_type template() {
        [ data := template(any_type) ]
        [ data := template(function_type) ]
        [ data := template(tuple_type) ]
        [ data := template(integer_type) ]
        [ data := template(reference_type) ]
    }

    type template(infer[infer:type], resolve[resolve:type]) {
        [ data := template(any_type) ]
        [ operator(image) | instance_type := $image | merge(real_type) ]
        [ operator(and) | instance_type := $mirror | merge(real_type) ]
        [ instance_type := $real | merge(real_type) ]
    }

    infered_type template(resolve[resolve:type]) {
        [ ]
    }

    boolean_type_data template(resolve[resolve:type]) {
        [ intrinsic := $native | identifier := $Boolean | instance_type := $real ]
    }

    integer_type_data template(resolve[resolve:type]) {
        [ intrinsic := $native | identifier := $Integer | instance_type := $real ]
    }

    float_type_data template(resolve[resolve:type]) {
        [ intrinsic := $native | identifier := $Float | instance_type := $real ]
    }

    string_type_data template(resolve[resolve:type]) {
        [ intrinsic := $native | identifier := $String | instance_type := $real ]
    }

    character_type_data template(resolve[resolve:type]) {
        [ intrinsic := $native | identifier := $Character | instance_type := $real ]
    }

    function_type_data template(resolve[resolve:type]) {
        [ intrinsic := $function | return_type := template(infered_type) ]
    }

    type_none template(resolve[resolve:type]) {
        [ intrinsic := $none ]
    }

    type_not template(resolve[resolve:type]) {
        [ intrinsic := $not ]
    }

    field template() {
        [ keyword(public) | public := $!true | identifier := identifier() | operator(colon) | type := template(type) ]
        [ public := $!false | identifier := identifier() | operator(colon) | type := template(type) ]
    }

    field_list template() {
        [ operator(open_curly) | fields := list(template(field)) | operator(close_curly) ]
        [ operator(open_curly) | operator(close_curly) ]
    }

    structure template(register[register:structure], infer[infer:structure], resolve[resolve:structure]) {
        [ keyword(structure) | identifier := type_identifier() | merge(template_list) | operator(assign) | type := template(real_type) ]
        [ keyword(structure) | identifier := type_identifier() | merge(template_list) | merge(field_list) ]
    }

    native template(register[register:native], resolve[resolve:native]) {
        [ keyword(native) | identifier := type_identifier() | operator(assign) | type := template(type) ]
    }

    variant_field template() {
        [ name := identifier() | operator(colon) | type := template(type) ]
    }

    variant [
        [ [ #type_identifier name ] [ #operator [ open_curly ] ] [ #list [ #template [ variant_field ] ] [ #operator [ comma ] ] ] [ #operator [ close_curly ] ] ]
        [ [ #type_identifier name ] [ #operator [ open_round ] ] [ #list [ #template [ type ] ] [ #operator [ comma ] ] ] [ #operator [ close_round ] ] ]
        [ [ #type_identifier name ] [ #operator [ open_curly ] ] [ #operator [ close_curly ] ] ]
        [ [ #type_identifier name ] [ #operator [ open_round ] ] [ #operator [ close_round ] ] ]
        [ [ #type_identifier name ]                                                                                                                     ]
    ]

    variant_list [
        [ [ #operator [ open_curly ] ] [ #list variants [ #template [ variant ] ] ] [ #operator [ close_curly ] ] ]
        [ [ #operator [ open_curly ] ]                                              [ #operator [ close_curly ] ] ]
    ]

    enumeration [ @macro
        [ [ #keyword [ enumeration ] ] [ #type_identifier name ] [ #merge [ template_list ] ] [ #operator [ assign       ] ] [ #template type [ type ] ] ]
        [ [ #keyword [ enumeration ] ] [ #type_identifier name ] [ #merge [ template_list ] ] [ #merge    [ variant_list ] ]                             ]
    ]

    while [
        [ [ #keyword [ while ] ] [ #template [ instance ] ] [ #template scope [ scope ] ] ]
    ]

    loop [
        [ [ #keyword [ loop ] ] [ #template scope [ scope ] ] ]
    ]

    if template(infer[infer:if]) {
        [ keyword(if) | type := template(boolean_type_data) | instance := template(instance) | scope := template(scope) | else := list(template(else)) ]
        [ keyword(if) | type := template(boolean_type_data) | instance := template(instance) | scope := template(scope) ]
    }

    else [
        [ [ #keyword [ else ] ] [ #template [ instance ] ] [ #template scope [ scope ] ] ]
        [ [ #keyword [ else ] ]                                                                                           [ #template scope [ scope ] ] ]
    ]

    @ reverse iterate
    iterate [
        [ [ #keyword [ iterate ] ] [ #template [ range    ] ] [ #keyword [ as ] ] [ #template [ tuple_expansion ] ] [ #template [ scope ] ] ]
        [ [ #keyword [ iterate ] ] [ #template [ range    ] ] [ #keyword [ as ] ] [ #identifier iterator ] [ #template [ scope ] ] ]
        [ [ #keyword [ iterate ] ] [ #template [ range    ] ]                                              [ #template [ scope ] ] ]
        [ [ #keyword [ iterate ] ] [ #template [ instance ] ] [ #keyword [ as ] ] [ #template [ tuple_expansion ] ] [ #template [ scope ] ] ]
        [ [ #keyword [ iterate ] ] [ #template [ instance ] ] [ #keyword [ as ] ] [ #identifier iterator ] [ #template [ scope ] ] ]
        [ [ #keyword [ iterate ] ] [ #template [ instance ] ]                                              [ #template [ scope ] ] ]
    ]

    trait [
        [ [ #keyword [ trait ] ] [ #type_identifier name ] [ #merge [ template_list ] ] [ #operator [ open_curly ] ] [ #list [ #template [ field ] ] ] [ #operator [ close_curly ] ] ]
    ]

    implement_list [
        [ [ #operator [ open_curly ] ] [ #list [ #template [ block ] ] ] [ #operator [ close_curly ] ] ]
        [ [ #operator [ open_curly ] ]                                   [ #operator [ close_curly ] ] ]
    ]

    implement_selector [
        [ [ #keyword [ implement ] ] [ #merge [ template_list ] ] [ #type_identifier trait ] [ #merge [ subtype_list ] ] [ #keyword [ for ] ] [ #template type [ type ] ] ]
        [ [ #keyword [ implement ] ] [ #merge [ template_list ] ] [ #type_identifier trait ]                             [ #keyword [ for ] ] [ #template type [ type ] ] ]
        [ [ #keyword [ implement ] ] [ #merge [ template_list ] ]                                                                             [ #template type [ type ] ] ]
    ]

    implement [
        [ [ #template [ implement_selector ] ] [ #merge [ template_list ] ] [ #merge [ implement_list ] ] ]
    ]

    derive template() {
        [ keyword(derive) | merge(template_list) | trait := type_identifier() | merge(subtype_list) | keyword(for) | type := template(type) ]
        [ keyword(derive) | merge(template_list) | trait := type_identifier() | keyword(for) | type := template(type) ]
    }

    alias template(register[register:alias]) {
        [ keyword(alias) | identifier := type_identifier() | merge(template_list) | operator(assign) | type := template(type) ]
    }

    subtype_list template() {
        [ operator(smaller) | subtypes := list(template(type), operator(comma)) | operator(bigger) ]
        [ ]
    }

    template_list template() {
        [ operator(smaller) | subtypes := list(type_identifier(), operator(comma)) | operator(bigger) ]
        [ ]
    }

    label template() {
        [ keyword(label) | tuple_expansion := template(tuple_expansion) ]
        [ keyword(label) | identifier := identifier() | operator(colon) | type := template(type) ]
        [ keyword(label) | identifier := identifier() | type := template(infered_type) ]
    }

    assign template(register[register:assign], infer[infer:assign], resolve[resolve:assign]) {
        [ merge(label) | operator(assign) | value := template(instance) ]
    }

    reassign template() {
        [ destintion := template(instance) | template(reassignment_operator) | value := template(instance) ]
    }

    inclusiveness template() {
        [ operator(dot) | operator(dot) | operator(dot) | inclusive := $!true ]
        [ operator(dot) | operator(dot) | inclusive := $!false ]
    }

    range template() {
        [ start := template(instance) | merge(inclusiveness) | end := template(instance) ]
        [ start := template(instance) | merge(inclusiveness) ]
        [ merge(inclusiveness) | end := template(instance) ]
        [ merge(inclusiveness) ]
    }

    module template() {
        [ keyword(module) | name := identifier() | keyword(as) | as := identifier() ]
        [ keyword(module) | name := identifier() ]
    }

    call template(infer[infer:call]) {
        [ instance := template(instance) | type := template(infered_type) | operator(open_round) | parameters := list(template(call_parameter), operator(comma)) | operator(close_round) ]
        [ instance := template(instance) | type := template(infered_type) | operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    new_variant_field template() {
        [ field := identifier() | operator(colon) | template(instance) ]
    }

    new_variant template() {
        [ merge(redirection) | type_identifier := type_identifier() | operator(open_curly) | list(template(new_variant_field), operator(comma)) | operator(close_curly) ]
        [ merge(redirection) | type_identifier := type_identifier() | operator(open_round) | list(template(instance), operator(comma)) | operator(close_round) ]
        [ merge(redirection) | type_identifier := type_identifier() | operator(open_curly) | operator(close_curly) ]
        [ merge(redirection) | type_identifier := type_identifier() | operator(open_round) | operator(close_round) ]
        [ merge(redirection) | type_identifier := type_identifier() ]
    }

    tuple_field template() {
        [ name := identifier() | operator(colon) | instance := template(instance) ]
        [ instance := template(instance) ]
    }

    tuple template() {
        [ operator(open_round) | fields := list(template(tuple_field), operator(comma)) | operator(close_round) ]
    }

    referenced_instance template(infer[infer:referenced_instance], resolve[resolve:referenced_instance]) {
        [ operator(image) | instance_type := $image | instance := template(instance) | type := template(infered_type) ]
        [ operator(and) | instance_type := $mirror | instance := template(instance) | type := template(infered_type) ]
    }

    labeled_instance template(infer[infer:labeled_instance], resolve[resolve:labeled_instance]) {
        [ merge(redirection) | identifier := identifier() ]
    }

    instance_field template(infer[infer:instance_field]) {
        [ instance := template(instance) | type := template(infered_type) | operator(dot) | field := identifier() ]
    }

    mutability_definition template(infer[infer:mutability_definition]) {
        [ mutability := template(mutability) | instance := template(instance) ]
    }

    function_body template(infer[infer:function_body]) {
        [ merge(parameter_list) | type := template(function_type_data) | scope := template(scope) ]
        [ type := template(function_type_data) | scope := template(scope) ]
    }

    arithmatic_equasion template(infer[infer:equasion]) {
        [ terms := confirmed(template(instance), template(arithmatic_operator)) ]
    }

    logical_equasion template(infer[infer:equasion]) {
        [ terms := confirmed(template(instance), template(logical_operator)) ]
    }

    type_cast template(infer[infer:type_cast]) {
        [ instance := template(instance) | keyword(as) | type := template(type) ]
    }

    instance [ { infer [ infer:instance ] resolve [ resolve:instance ] }
        [ [ #template   collection  [ instance                    ] ] [ #operator              [ open_square                                    ] ] [ #template   range [ range       ] ] [ #operator [ close_square ] ] ]
        [ [ #template   collection  [ instance                    ] ] [ #operator              [ open_square                                    ] ] [ #template   index [ instance    ] ] [ #operator [ close_square ] ] ]
        [ [ #template   tuple       [ tuple                       ] ]                                                                                                                                                    ]
        [ [ #template   _           [ variant_condition           ] ]                                                                                                                                                    ]


        [ [ #template data [ immediate ] ] ]
        [ [ #template data [ referenced_instance ] ] ]
        [ [ #template data [ labeled_instance ] ] ]
        [ [ #template data [ instance_field ] ] ]
        [ [ #template data [ mutability_definition ] ] ]
        [ [ #template data [ call ] ] ]
        [ [ #template data [ function_body ] ] ]
        [ [ #template data [ type_cast ] ] ]
        @ inverted instance - aka. !instance
        @ wrapped instance - aka. [instance]
        @ size comparisson - aka. instance < instance
        [ [ #template data [ if ] ] ]

        [ [ #template   new_variant [ new_variant                 ] ]                                                                                                                                                    ]
        [ [ #template   macro       [ macro                       ] ]                                                                                                                                                    ]
        [ [ #template   match       [ match                       ] ]                                                                                                                                                    ]
        [ [ #template   match_iterate       [ match_iterate                       ] ]                                                                                                                                                    ]
        [ [ #template   while       [ while                       ] ]                                                                                                                                                    ]
        [ [ #template   loop        [ loop                        ] ]                                                                                                                                                    ]
        [ [ #template   iterate     [ iterate                     ] ]                                                                                                                                                    ]


        [ [ #template data [ arithmatic_equasion ] ] ]
        [ [ #template data [ logical_equasion ] ] ]
    ]

    key template() {
        [ type_identifier := type_identifier() ]
        [ identifier := identifier() ]
    }

    path template() {
        [ operator(open_round) | list(template(path), operator(comma)) | operator(close_round) ]
        [ list(template(key), operator(contains)) | operator(contains) | keyword(any) ]
        [ list(template(key), operator(contains)) | keyword(as) | template(key) ]
        [ list(template(key), operator(contains)) ]
        [ list(template(key), operator(contains)) | operator(contains) | template(path) ]
    }

    import template() {
        [ keyword(import) | template(path) ]
    }

    export template() {
        [ keyword(export) | operator(open_round) | list(template(path), operator(comma)) | operator(comma) ]
        [ keyword(export) | template(path) ]
    }

    variant_comparison template() {
        [ variant := type_identifier() | operator(colon) | fields := list(identifier(), operator(comma)) ]
        [ variant := type_identifier() | operator(colon) | expansion := template(tuple_expansion) ]
        [ variant := type_identifier() ]
        [ variant := keyword(any) | operator(colon) | identifier := identifier() ]
        [ variant := keyword(any) ]
    }

    variant_condition template() {
        [ template(variant_comparison) | operator(equals) | template(instance) ]
        [ template(variant_comparison) | operator(not_equals) | template(instance) ]
    }

    case template() {
        [ keyword(case) | template(variant_comparison) ]
        [ keyword(case) | template(instance) ]
        [ keyword(case) | template(range) ]
    }

    arm template() {
        [ cases := list(template(case), operator(or)) | operator(case) | template(scope) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(call) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(macro) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(reassign) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(terminate) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(return) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(continue) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(break) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(match) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(match_iterate) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(pass) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(if) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(while) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(loop) ]
        [ cases := list(template(case), operator(or)) | operator(case) | template(iterate) ]
    }

    match template() {
        [ keyword(match) | instance := template(instance) | operator(open_curly) | arms := list(template(arm)) | operator(close_curly) ]
        [ keyword(match) | instance := template(instance) | operator(open_curly) | operator(close_curly) ]
    }

    match_iterate template() {
        [ keyword(match) | keyword(iterate) | instance := template(instance) | operator(open_curly) | arms := list(template(arm)) | operator(close_curly) ]
        [ keyword(match) | keyword(iterate) | instance := template(instance) | operator(open_curly) | operator(close_curly) ]
    }

    call_parameter template(infer[infer:call_parameter]) {
        [ field := identifier() | operator(colon) | instance := template(instance) ]
        [ instance := template(instance) ]
    }

    macro template() {
        [ identifier := identifier() | operator(macro) | operator(open_round) | parameters := list(template(call_parameter), operator(comma)) | operator(close_round) ]
        [ identifier := identifier() | operator(macro) | operator(open_round) | parameters := $[] | operator(close_round) ]
        [ identifier := keyword() | operator(macro) | operator(open_round) | parameters := list(template(call_parameter), operator(comma)) | operator(close_round) ]
        [ identifier := keyword() | operator(macro) | operator(open_round) | parameters := $[] | operator(close_round) ]
    }

    public template() {
        [ keyword(public) | public := $!true ]
        [ public := $!false ]
    }

    block template() {
        [ merge(public) | block := template(assign) ]
        [ merge(public) | block := template(alias) ]
        [ merge(public) | block := template(structure) ]
        [ merge(public) | block := template(enumeration) ]
        [ merge(public) | block := template(native) ]
        [ merge(public) | block := template(namespace) ]
        [ merge(public) | block := template(trait) ]
        [ merge(public) | block := template(module) ]
        [ merge(public) | block := template(macro) ]
        [ block := template(implement) ]
        [ block := template(derive) ]
        [ block := template(import) ]
        [ block := template(export) ]
    }

    statement template() {
        [ statement := template(assign) ]
        [ statement := template(reassign) ]
        [ statement := template(call) ]
        [ statement := template(macro) ]
        [ statement := template(alias) ]
        [ statement := template(subscope) ]
        [ statement := template(terminate) ]
        [ statement := template(return) ]
        [ statement := template(continue) ]
        [ statement := template(break) ]
        [ statement := template(match) ]
        [ statement := template(match_iterate) ]
        [ statement := template(pass) ]
        [ statement := template(if) ]
        [ statement := template(while) ]
        [ statement := template(loop) ]
        [ statement := template(iterate) ]
    }

    namespace template(register[register:namespace]) {
        [ keyword(namespace) | identifier := identifier() | operator(open_curly) | blocks := list(template(block)) | operator(close_curly) ]
        [ keyword(namespace) | identifier := identifier() | operator(open_curly) | operator(close_curly) ]
    }

    terminate template() {
        [ keyword(terminate) ]
    }

    continue template() {
        [ keyword(continue) ]
    }

    break template() {
        [ keyword(break) ]
    }

    return template() {
        [ keyword(return) | value := template(instance) ]
    }

    pass template() {
        [ keyword(pass) | value := template(instance) ]
    }

    scope template() {
        [ operator(open_curly) | statements := list(template(statement)) | operator(close_curly) ]
        [ operator(open_curly) | operator(close_curly) ]
    }

    subscope template() {
        [ keyword(scope) | scope := template(scope) ]
    }

    #top template(register[register:top], resolve[resolve:top], generate[generate:top], infer[infer:top]) {
        [ blocks := list(template(block)) ]
        [ ]
    }
}
