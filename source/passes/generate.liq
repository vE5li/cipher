#functions {

    generate {

        mangle_float function(width: integer) {
            if width == $16 {
                return $"short"
            } else width == $32 {
                return $"float"
            } else width == $64 {
                return $"double"
            } else width == $128 {
                return $"fp128"
            }
        }

        @ TODO:
        format_float function(value: float, width: integer) {
            if width == $16 {
                return $"" ~ value
            } else width == $32 {
                return $"" ~ value
            } else width == $64 {
                return value ~ $"00000e+00"
            } else width == $128 {
                return $"" ~ value
            }
        }

        mangle function(namespace: map, prefix: string) {

            iterate namespace:types as identifier, entry {

                if entry:type == $integer {
                    set mangled_name := $"i" ~ entry:width
                } else entry:type == $float {
                    set mangled_name := call($generate:mangle_float, entry:width)
                } else entry:type == $byte {
                    set mangled_name := $"i8"
                } else entry:type == $alias {
                    set mangled_name := $"%type." ~ prefix ~ identifier
                } else entry:type == $structure {
                    set mangled_name := $"%type." ~ prefix ~ identifier
                }

                print_line($"mangled path for type " ~ identifier ~ $" is " ~ mangled_name)

                set mangled_name_path := path($#scope:namespace:types, identifier, $mangled_name)
                set *mangled_name_path := mangled_name
            }

            iterate namespace:labels as identifier, entry {
                set mangled_name_path := path($#scope:namespace:labels, identifier, $mangled_name)
                set mangled_name := $"@label." ~ prefix ~ identifier
                set *mangled_name_path := mangled_name
            }

            iterate namespace:namespaces as identifier, entry {
                set new_prefix := prefix ~ identifier ~ $"."
                set new_entry := call($generate:mangle, entry, new_prefix)
                set namespace:namespaces := overwrite(namespace:namespaces, identifier, new_entry)
            }

            return namespace
        }

        level function(namespace) {
            set types := ${}
            set labels := ${}

            iterate namespace:types as identifier, entry {
                if entry:type != $integer && entry:type != $float && entry:type != $byte {
                    set types := insert(types, entry:mangled_name, entry)
                }
            }

            iterate namespace:labels as identifier, entry {
                set labels := insert(labels, entry:mangled_name, entry)
            }

            iterate namespace:namespaces as identifier, entry {
                set namespace_entries := call($generate:level, entry)
                set &scope := merge(&scope, namespace_entries)
            }

            return map($types := types, $labels := labels)
        }

        type_code function(type_lookup: map) {
            set code := $"\n; types\n"

            iterate type_lookup as identifier, entry {

                @ ?
                print_line($"generating code for type " ~ identifier)

                if entry:type == $alias {

                    @ MAKE IT SO THAT MULTIPLE ALIASES CAN GET RESOLVED
                    set provider_type := *entry:alias
                    set code := code ~ identifier ~ $" = type " ~ provider_type:mangled_name ~ $"\n"

                } else entry:type == $structure {
                    set field_code := $" "

                    iterate entry:fields as index, field {

                        @ MAKE IT SO THAT MULTIPLE ALIASES CAN GET RESOLVED
                        set provider_type := *field:real_type
                        set field_code := field_code ~ provider_type:mangled_name

                        if field:instance_type != $real {
                            set field_code := field_code ~ $"*"
                        }

                        if index < length(entry:fields) {
                            set field_code := field_code ~ $", "
                        } else {
                            set field_code := field_code ~ $" "
                        }
                    }

                    set code := code ~ identifier ~ $" = type {" ~ field_code ~ $"}\n"
                }
            }

            return code
        }

        label_code function(label_lookup: map) {
            set code := $"\n; labels\n"

            iterate label_lookup as identifier, entry {

                set provider_type := *entry:type:real_type
                set provider_name := provider_type:mangled_name

                if ?string(entry:value) {
                    set item_code := $""
                    set string_length := length(entry:value)

                    iterate entry:value as index, character {
                        set item_code := item_code ~ $"%type.main.Character " ~ integer(character)
                        if index < string_length {
                            set item_code := item_code ~ $", "
                        }
                    }

                    set array_identifier := $"[" ~ string_length ~ $" x %type.main.Character]"
                    set code := code ~ identifier ~ $"$constant = constant " ~ array_identifier ~ $" [" ~ item_code ~ $"]\n"
                    set code := code ~ identifier ~ $"$pointer = constant %type.main.Character* getelementptr inbounds (" ~ array_identifier ~ $", " ~ array_identifier ~ $"* " ~ identifier ~ $"$constant, i32 0, i32 0)\n"
                    set code := code ~ identifier ~ $" = constant " ~ provider_name ~ $" { %type.main.Pointer_Character { i64 ptrtoint (%type.main.Character** " ~ identifier ~ $"$pointer to i64) }, i64 " ~ string_length ~ $", i64 " ~ string_length ~  $" }\n"
                } else ?integer(entry:value) {
                    set code := code ~ identifier ~ $" = constant " ~ provider_name ~ $" " ~ entry:value ~ $"\n"
                } else ?float(entry:value) {
                    set code := code ~ identifier ~ $" = constant " ~ provider_name ~ $" " ~ call($generate:format_float, entry:value, provider_type:width) ~ $"\n"
                } else ?character(entry:value) {
                    set code := code ~ identifier ~ $" = constant " ~ provider_name ~ $" " ~ integer(entry:value) ~ $"\n"
                } else ?boolean(entry:value) {
                    set code := code ~ identifier ~ $" = constant " ~ provider_name ~ $" " ~ entry:value ~ $"\n"
                } else {
                    error($"unhandled label value " ~ type(entry:value))
                }
            }

            return code
        }

        top function(self) {
            print_line($"[ pass ] generate")

            set code := $""

            @ debug log
            print_line($"generating type names")

            set &build:namespace := call($generate:mangle, &build:namespace, $"main.")
            set leveled := call($generate:level, &build:namespace)

            @print_line($"dealias types")
            @set code := code ~ call($generate:dealias_types, leveled:types)

            print_line($"generating type data")
            set code := code ~ call($generate:type_code, leveled:types)

            @print_line($"dealias labels")
            @set code := code ~ call($generate:dealias_labels, leveled:labels)

            print_line($"generating label data")
            set code := code ~ call($generate:label_code, leveled:labels)

            @ temp
            set code := code ~ $"\n; temporary\n"
            set code := code ~ $"@constant.run_message = constant [21 x i8] c\"Hello from Lugge%i!\\0A\\00\"\n"
            set code := code ~ $"declare i32 @printf(i8*, ...)\n"

            set code := code ~ $"\n; main\n"
            set code := code ~ $"define i32 @main(i32 %argc, i8** %argv) {\n"
            set code := code ~ $"    %temp = call i32 (i8*, ...) @printf(i8* getelementptr ([21 x i8], [21 x i8]* @constant.run_message, i64 0, i64 0), i64 ptrtoint (%type.main.Character** @label.main.test_string$pointer to i64))\n"
            set code := code ~ $"    ret i32 0\n}\n"

            set &build:code := code
            return self
        }
    }
}
