group_lookup {

    instance_type_groups [
        { entry instance_type merger infer:merge_default }
    ]

    type_groups [
        { entry identifier merger infer:merge_default }
        { entry parameters merger infer:merge_parameters }
        { entry return_type merger infer:merge_type }
        { entry intrinsic merger infer:merge_default }
    ]
}

#functions {

    infer {

        done function(node: map) {
            set pass := node:#pass:infer
            return pass == $[] || pass == $[infer:skip]
        }

        with_pass function(node: map, pass: identifier) {
            set node:#pass:infer := list(path($infer, pass))
            return node
        }

        skip function(self, [parameters]) {
            return self
        }

        merge_default function(first, second) {
            if first != second {
                error($"failed to merge " ~ first ~ $" and " ~ second)
            }
            return first
        }

        merge_type_group function(kind: identifier, first: map, second: map) {
            set group_lookup := &root:group_lookup[kind]

            iterate group_lookup as _, field {
                set entry := field:entry

                if ?present(second:entries, entry) {
                    if ?present(first:entries, entry) {
                        set new_value := call(field:merger, first:entries[entry], second:entries[entry])
                        set first:entries := overwrite(first:entries, entry, new_value)
                    } else {
                        set first:entries := insert(first:entries, entry, second:entries[entry])
                    }
                }
            }

            return first
        }

        merge_type function(first: map, second: map) {
            set first := call($infer:merge_type_group, $type_groups, first, second)
            set first := call($infer:merge_type_group, $instance_type_groups, first, second)
            return first
        }

        merge_parameters function(first: list, second: list) {

            if length(first) != length(second) {
                error($"expected " ~ length(first) ~ $" parameters but got " ~ length(second))
            }

            set index := $1
            while index <= length(first) {
                set first_type_path := path($#scope:first, index, $entries:type)
                set second_type_path := path($#scope:second, index, $entries:type)
                set *first_type_path := call($infer:merge_type, *first_type_path, *second_type_path)
                set index := index + $1
            }

            return first
        }

        existing_group function(kind: identifier, type: path, namespace: path) {
            set groups_path := path(namespace, kind)
            set groups := *groups_path

            iterate groups as index, group {
                if ?contains(group:types, type) {
                    set group_path := path(groups_path, index)
                    return group_path
                }
            }

            return $none
        }

        create_group function(kind: identifier, types: list, namespace: path) {

            set groups_path := path(namespace, kind)
            set groups := *groups_path

            set new_group := map($entries := ${}, $types := types)
            set groups := append(groups, new_group)
            set *groups_path := groups

            set group_path := path(groups_path, length(groups))
            return group_path
        }

        get_group function(kind: identifier, type: path, namespace: path) {

            set group_path := call($infer:existing_group, kind, type, namespace)
            if group_path != $none {
                return group_path
            }

            set group_types := list(type)
            set group_path := call($infer:create_group, kind, group_types, namespace)
            return group_path
        }

        get_field_merger function(kind: identifier, field: identifier) {
            iterate &root:group_lookup[kind] as _, entry {
                if entry:entry == field {
                    return entry:merger
                }
            }
            error($"field " ~ field ~ $" not found")
        }

        set_group_entries function(kind: identifier, group_path: path, field: identifier, value) {
            set group := *group_path

            if ?present(group:entries, field) {
                set previous_value := group:entries[field]
                set merger := call($infer:get_field_merger, kind, field)
                set new_value := call(merger, group:entries[field], value)
                set group:entries := overwrite(group:entries, field, new_value)
                set *group_path := group
                return previous_value != group:entries[field]
            }

            set group:entries := insert(group:entries, field, value)
            set *group_path := group
            return $!true
        }

        merge_group function(kind: identifier, first_group_path: path, second_group_path: path, namespace: path) {

            set first_group := *first_group_path
            set second_group := *second_group_path
            set group_lookup := &root:group_lookup[kind]

            set first_group:types := merge(first_group:types, second_group:types)

            iterate group_lookup as _, field {
                set entry := field:entry

                if ?present(second_group:entries, entry) {
                    if ?present(first_group:entries, entry) {
                        set new_value := call(field:merger, first_group:entries[entry], second_group:entries[entry])
                        set first_group:entries := overwrite(first_group:entries, entry, new_value)
                    } else {
                        set first_group:entries := insert(first_group:entries, entry, second_group:entries[entry])
                    }
                }
            }

            set second_group:entries := ${}
            set second_group:types := $[]

            set *first_group_path := first_group
            set *second_group_path := second_group
        }

        identical_group function(kind: identifier, first: path, second: path, namespace: path) {

            set first_group_path := call($infer:existing_group, kind, first, namespace)
            set second_group_path := call($infer:existing_group, kind, second, namespace)

            if first_group_path != $none && second_group_path != $none {
                if first_group_path == second_group_path {
                    terminate
                }
                call($infer:merge_group, kind, first_group_path, second_group_path, namespace)
                terminate
            }

            if first_group_path != $none {
                set first_group := *first_group_path
                set first_group:types := append(first_group:types, second)
                set *first_group_path := first_group
                terminate
            }

            if second_group_path != $none {
                set second_group := *second_group_path
                set second_group:types := append(second_group:types, first)
                set *second_group_path := second_group
                terminate
            }

            set group_types := list(first, second)
            call($infer:create_group, kind, group_types, namespace)
        }

        reference_instance_type function(reference: path, real: path, instance_type: identifier, namespace: path) {
            set reference_group := call($infer:get_group, $instance_type_groups, reference, namespace)
            set real_group := call($infer:get_group, $instance_type_groups, real, namespace)

            call($infer:set_group_entries, $instance_type_groups, reference_group, $instance_type, instance_type)
            call($infer:set_group_entries, $instance_type_groups, real_group, $instance_type, $real)
        }

        base_instance_type function(type: path, namespace: path) {
            set type_group := call($infer:get_group, $instance_type_groups, type, namespace)
            call($infer:set_group_entries, $instance_type_groups, type_group, $instance_type, $real)
        }

        get_type_entry function(type_path: path) {

            @ CHECK IF TYPE EXISTS OR INSTANCIATE THE TYPE IF ITS A TEMPLATE TYPE

            set type := *type_path
            set type_entry_path := path($#build:namespace:types, string(type:entries:identifier)) @ REMOVE THE STRING
            return type_entry_path
        }

        create_empty_parameters function(length: integer) {
            set parameters := $[]
            set count := $0

            while count < length {
                set parameter := ${ entries { type { entries {} } } #pass { infer [] } }
                set parameters := append(parameters, parameter)
                set count := count + $1
            }

            return parameters
        }

        reference_type function(self, prefix: path, namespace: path) {
            return call($infer:with_pass, self, $skip)
        }

        parameter function(self, prefix: path, namespace: path) {
            set type_prefix := path(prefix, $entries:type)
            set self:entries:type := pass(self:entries:type, type_prefix, namespace)

            if ?present(self:entries, $default_value) {
                set default_value_path := path(prefix, $entries:default_value)
                set self:entries:default_value := pass(self:entries:default_value, type_prefix, default_value_path, namespace)

                if not(call($infer:done, self:entries:default_value)) {
                    return call($infer:with_pass, self, $parameter)
                }
            }

            return call($infer:with_pass, self, $skip)
        }

        function_type function(self, prefix: path, namespace: path) {

            set return_type_prefix := path(prefix, $entries:return_type)
            set self:entries:return_type := pass(self:entries:return_type, return_type_prefix, namespace)
            set parameters_done := $!true

            iterate self:entries:parameters as index, parameter {
                set parameter_prefix := path(prefix, $entries:parameters, index)
                set parameter := pass(parameter:item, parameter_prefix, namespace)
                set self:entries:parameters := overwrite(self:entries:parameters, index, parameter)
                set parameters_done := parameters_done && call($infer:done, parameter)
            }

            if not(parameters_done) {
                return call($infer:with_pass, self, $function_type)
            }

            return call($infer:with_pass, self, $skip)
        }

        type function(self, prefix: path, namespace: path) {
            set data := pass(self:entries:data, prefix, namespace)

            @ CHECK IF TYPE IS RESOLVED COMPLETELY

            if ?present(self:entries, $instance_type) {
                set self:entries := insert(data:entries, $instance_type, self:entries:instance_type)
            } else {
                set self:entries := data:entries
            }

            return call($infer:with_pass, self, $skip)
        }

        structure function(self, namespace: path) {

            iterate self:entries:fields as field_index, field_data {
                set field_path := path(namespace, $types, string(self:entries:identifier), $entries:fields, field_index, $item) @ REMOVE STRING INSTRUCTION
                set field_data := pass(field_data, field_path, namespace)
                set self:entries:fields := overwrite(self:entries:fields, field_index, field_data)
            }

            return call($infer:with_pass, self, $skip)
        }

        immediate function(self, inferance_type: path, prefix: path, namespace: path) {

            set type_prefix := path(prefix, $entries:type)
            set self:entries:type := pass(self:entries:type, type_prefix, namespace)

            call($infer:identical_group, $type_groups, inferance_type, type_prefix, namespace)
            call($infer:identical_group, $instance_type_groups, inferance_type, type_prefix, namespace)

            return call($infer:with_pass, self, $skip)
        }

        referenced_instance function(self, inferance_type: path, prefix: path, namespace: path) {

            set adapter_type := path(prefix, $entries:type)
            set instance_type := self:entries:instance_type

            call($infer:identical_group, $type_groups, inferance_type, adapter_type, namespace)
            call($infer:reference_instance_type, inferance_type, adapter_type, instance_type, namespace)

            set instance_path := path(prefix, $entries:instance)
            set self:entries:instance := pass(self:entries:instance, adapter_type, instance_path, namespace)

            if not(call($infer:done, self:entries:instance)) {
                return call($infer:with_pass, self, $referenced_instance)
            }

            return call($infer:with_pass, self, $skip)
        }

        labeled_instance function(self, inferance_type: path, prefix: path, namespace: path) {

            @ CHECK THAT LABEL EXISTS AND RESOLVE ITS NAMESPACE
            set label_type_prefix := path(namespace, $labels, self:entries:identifier, $entries:type)

            call($infer:identical_group, $type_groups, inferance_type, label_type_prefix, namespace)
            call($infer:base_instance_type, inferance_type, namespace)

            return call($infer:with_pass, self, $skip)
        }

        instance_field function(self, inferance_type: path, prefix: path, namespace: path) {

            set data_type_path := path(prefix, $entries:type)
            set instance_path := path(prefix, $entries:instance)

            set self:entries:instance := pass(self:entries:instance, data_type_path, instance_path, namespace)
            if not(call($infer:done, self:entries:instance)) || ?not_present(self:entries:type:entries, $identifier) {
                return call($infer:with_pass, self, $instance_field)
            }

            set type_entry_path := call($infer:get_type_entry, data_type_path)
            set type_entry := *type_entry_path

            iterate type_entry:entries:fields as field_index, field_data {
                if field_data:item:entries:identifier == self:entries:field {
                    set field_type := path(type_entry_path, $entries:fields, field_index, $item:entries:type)

                    call($infer:identical_group, $type_groups, inferance_type, field_type, namespace)
                    call($infer:base_instance_type, inferance_type, namespace)

                    return call($infer:with_pass, self, $skip)
                }
            }

            error($"struct of type ??? has no field named " ~ self:entries:field)
        }

        if function(self, inferance_type: path, prefix: path, namespace: path) {

            set type_prefix := path(prefix, $entries:type)
            set self:entries:type := pass(self:entries:type, type_prefix, namespace)

            set instance_path := path(prefix, $entries:instance)
            set self:entries:instance := pass(self:entries:instance, type_prefix, instance_path, namespace)
            if not(call($infer:done, self:entries:instance)) {
                return call($infer:with_pass, self, $if)
            }

            return call($infer:with_pass, self, $skip)
        }

        call_parameter function(self, inferance_type: path, prefix: path, namespace: path) {
            ensure(?not_present(self:entries, $field), $"call parameters with field names are not implemented yet")

            set instance_path := path(prefix, $entries:instance)
            set self:entries:instance := pass(self:entries:instance, inferance_type, instance_path, namespace)
            if not(call($infer:done, self:entries:instance)) {
                return call($infer:with_pass, self, $call_parameter)
            }

            return call($infer:with_pass, self, $skip)
        }

        call function(self, inferance_type: path, prefix: path, namespace: path) {

            set data_type_path := path(prefix, $entries:type)
            set instance_path := path(prefix, $entries:instance)
            set self:entries:type := pass(self:entries:type, data_type_path, namespace)

            if ?not_present(self:entries:type:entries, $parameters) {
                set parameter_count := length(self:entries:parameters)
                set empty_parameters := call($infer:create_empty_parameters, parameter_count)
                set self:entries:type:entries:parameters := empty_parameters
            }

            set self:entries:instance := pass(self:entries:instance, data_type_path, instance_path, namespace)
            if not(call($infer:done, self:entries:instance)) {
                return call($infer:with_pass, self, $call)
            }

            set return_type_path := path(data_type_path, $entries:return_type)
            call($infer:identical_group, $type_groups, inferance_type, return_type_path, namespace)
            call($infer:base_instance_type, inferance_type, namespace)
            set parameters_done := $!true

            iterate self:entries:parameters as index, parameter {
                set parameter_path := path(prefix, $entries:parameters, index, $item)
                set function_parameter_path := path(data_type_path, $entries:parameters, index, $entries:type)
                set parameter := pass(parameter, function_parameter_path, parameter_path, namespace)
                set self:entries:parameters := overwrite(self:entries:parameters, index, parameter)
                set parameters_done := parameters_done && call($infer:done, parameter:item)
            }

            if not(parameters_done) {
                return call($infer:with_pass, self, $call)
            }

            return call($infer:with_pass, self, $skip)
        }

        equasion function(self, inferance_type: path, prefix: path, namespace: path) {
            set terms_done := $!true

            iterate self:entries:terms as index, term {
                set term_path := path(prefix, $entries:terms, index, $item)
                set term := pass(term, inferance_type, term_path, namespace)
                set self:entries:terms := overwrite(self:entries:terms, index, term)
                set terms_done := terms_done && call($infer:done, term:item)
            }

            if not(terms_done) {
                return call($infer:with_pass, self, $equasion)
            }

            return call($infer:with_pass, self, $skip)
        }

        mutability_definition function(self, inferance_type: path, prefix: path, namespace: path) {

            set instance_path := path(prefix, $entries:instance)
            set self:entries:instance := pass(self:entries:instance, inferance_type, instance_path, namespace)

            if not(call($infer:done, self:entries:instance)) {
                return call($infer:with_pass, self, $mutability_definition)
            }

            return call($infer:with_pass, self, $skip)
        }

        function_body function(self, inferance_type: path, prefix: path, namespace: path) {

            if ?present(self:entries, $parameters) {
                set parameters := $[]
                set default_values := $[]

                iterate self:entries:parameters as index, parameter {
                    set parameter_prefix := path(prefix, $entries:type:entries:parameters, index)
                    set parameter := pass(parameter:item, parameter_prefix, namespace)
                    set parameters := append(parameters, parameter)
                }

                set self:entries:type:entries:parameters := parameters
            }

            set type_prefix := path(prefix, $entries:type)
            set self:entries:type := pass(self:entries:type, type_prefix, namespace)

            call($infer:identical_group, $type_groups, inferance_type, type_prefix, namespace)
            call($infer:identical_group, $instance_type_groups, inferance_type, type_prefix, namespace)

            return call($infer:with_pass, self, $skip)
        }

        instance function(self, inferance_type: path, prefix: path, namespace: path) {

            set data_prefix := path(prefix, $entries:data)
            set self:entries:data := pass(self:entries:data, inferance_type, data_prefix, namespace)

            if not(call($infer:done, self:entries:data)) {
                return call($infer:with_pass, self, $instance)
            }

            return call($infer:with_pass, self, $skip)
        }

        assign function(self, namespace: path) {

            set type_prefix := path(namespace, $labels, self:entries:identifier, $entries:type)
            set self:entries:type := pass(self:entries:type, type_prefix, namespace)

            set value_prefix := path(namespace, $labels, self:entries:identifier, $entries:value)
            set self:entries:value := pass(self:entries:value, type_prefix, value_prefix, namespace)

            if not(call($infer:done, self:entries:value)) {
                return call($infer:with_pass, self, $assign)
            }

            return call($infer:with_pass, self, $skip)
        }

        combine_type function(kind: identifier, group_path: path, type_path: path) {
            set group_lookup := &root:group_lookup[kind]
            set group_changed := $!false
            set type := *type_path

            iterate group_lookup as _, field {
                set entry := field:entry
                if ?present(type:entries, entry) {
                    set group_changed := group_changed || call($infer:set_group_entries, kind, group_path, entry, type:entries[entry])
                }
            }

            return group_changed
        }

        combine function(kind: identifier) {
            set changed := $!false

            iterate &build:namespace[kind] as index, group {
                set group_path := path($#build:namespace, kind, index)
                set group_changed := $!false
                @print_line(group:types)

                iterate group:types as __index, type_path {
                    set group_changed := group_changed || call($infer:combine_type, kind, group_path, type_path)
                }

                if group_changed {
                    set group := *group_path
                    set changed := $!true

                    iterate group:types as _, type_path {
                        set *type_path := call($infer:merge_type, *type_path, group)
                    }
                }

                @set group := *group_path
                @print_line($"data: " ~ group:entries)
            }

            return changed
        }

        top function(self) {

            if &root:debug {
                set start_time := time()
            }

            set changed := $!true
            set pass_count := $0

            while changed {
                set changed := $!false
                set pass_count := pass_count + $1

                set &build:namespace:types := pass(&build:namespace:types, $#build:namespace)
                set &build:namespace:labels := pass(&build:namespace:labels, $#build:namespace)

                set changed := changed || call($infer:combine, $type_groups)
                set changed := changed || call($infer:combine, $instance_type_groups)

                @set changed |= call($infer:combine, $type_groups)
                @set changed |= call($infer:combine, $instance_type_groups)
            }

            if &root:debug {
                set elapsed_time := (time() - start_time)  / $1000.0
                set tag := call($shego:tag, &root:colors:green, $"completed")
                call($shego:print_pass, $infer, tag ~ $" " ~ pass_count ~ $" passes in " ~ elapsed_time ~ $"s")
            }

            return self
        }
    }
}
