#functions {

    resolve {

        reference_type function(self, namespace) {
            print_line($"resolving reference type " ~ self:entries:type_identifier ~ $" in namespace " ~ namespace)
            set concrete_name := string(self:entries:type_identifier)

            if ?present(self:entries, $subtypes) {
                set concrete_name := concrete_name ~ $"<"

                iterate self:entries:subtypes as index, subtype {
                    set subtype := pass(subtype:item, namespace)

                    if subtype:instance_type == $image {
                        set concrete_name := concrete_name ~ $"$"
                    } else subtype:instance_type == $mirror {
                        set concrete_name := concrete_name ~ $"&"
                    }

                    set concrete_name := concrete_name ~ subtype:real_type
                    if index < length(self:entries:subtypes) {
                        set concrete_name := concrete_name ~ $", "
                    }
                }

                set concrete_name := concrete_name ~ $">"
                print_line(concrete_name)
            }

            return path(namespace, $types, concrete_name)
        }

        integer_type function(self, namespace) {
            print_line($"resolving integer type " ~ self:entries:size)
            return self:entries:size
        }

        type function(self, namespace: path) {
            set data :=  pass(self:entries:data, namespace)
            set real_type := pass(self:entries:real_type, namespace)
            set instance_type := self:entries:instance_type

            @ ensure ?not_integer(real_type) || instance_type == $real
            @ ensure not(?integer(real_type) && instance_type != $real)

            return map($real_type := real_type, $instance_type := instance_type)
        }

        structure function(self, namespace: path) {

            if ?present(self:entries, $type) {
                set alias := pass(self:entries:type, namespace)
                return map($type := $alias, $alias := alias)
            }

            set resolved_fields := $[]

            iterate self:entries:fields as index, field {
                set resolved_field := pass(field:item, namespace)
                set field_entries := resolved_field:entries
                set resolved_fields := append(resolved_fields, field_entries)
            }

            return map($type := $structure, $fields := resolved_fields)
        }

        native function(self, namespace: path) {
            print_line($"resolving native type " ~ self:entries:identifier ~ $" in namespace " ~ namespace)
            set alias := pass(self:entries:type, namespace)
            return map($type := $alias, $alias := alias)
        }

        boolean function(self) {
            return self:entries:state
        }

        number function(self) {
            if self:entries:negative {
                return negate(self:entries:value)
            }
            return self:entries:value
        }

        immediate function(self) {
            return pass(self:entries:value)
        }

        instance function(self) {
            return pass(self:entries:data)
        }

        assign function(self, namespace: path) {
            set self:entries:type := pass(self:entries:type, namespace)
            set self:entries:value := pass(self:entries:value)
            return self:entries
        }

        top function(self) {
            error($"done!")

            print_line($"[ pass ] resolve")
            set &build:namespace := pass(&build:namespace, $#build:namespace)
            return self
        }
    }
}
