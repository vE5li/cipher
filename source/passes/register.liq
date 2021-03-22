#functions {

    register {

        namespace function(self, namespace: path) {

            set namespace_lookup := path(namespace, $namespaces)
            call($shego:print_pass, $register, $"register namespace " ~ self:entries:identifier)

            if ?present(*namespace_lookup, self:entries:identifier) {
                error($"namespace " ~ self:entries:identifier ~ " is already defined")
            }

            set path := path(namespace_lookup, self:entries:identifier)
            set *path := ${ types {} type_groups [] instance_type_groups [] namespaces {} labels {} }

            if ?present(self:entries, $blocks) {
                pass(self:entries:blocks, path)
            }

            return self
        }

        structure function(self, namespace: path) {

            set type_lookup := path(namespace, $types)
            set concrete_name := string(self:entries:identifier)
            call($shego:print_pass, $register, $"register structure " ~ concrete_name)

            if ?present(*type_lookup, concrete_name) {
                error($"type " ~ concrete_name ~ $" is already defined")
            }

            set path := path(type_lookup, concrete_name)
            set *path := self
            return self
        }

        native function(self, namespace: path) {

            set type_lookup := path(namespace, $types)
            set concrete_name := string(self:entries:identifier)
            call($shego:print_pass, $register, $"register native type " ~ concrete_name)

            if ?present(*type_lookup, concrete_name) {
                error($"type " ~ concrete_name ~ $" is already defined")
            }

            set path := path(type_lookup, concrete_name)
            set *path := self
            return self
        }

        alias function(self, namespace: path) {

            set type_lookup := path(namespace, $types)
            set concrete_name := string(self:entries:identifier)
            call($shego:print_pass, $register, $"register alias " ~ concrete_name)

            if ?present(*type_lookup, concrete_name) {
                error($"type " ~ concrete_name ~ $" is already defined")
            }

            set path := path(type_lookup, concrete_name)
            set *path := self
            return self
        }

        assign function(self, namespace: path) {

            set label_lookup := path(namespace, $labels)
            call($shego:print_pass, $register, $"register label " ~ self:entries:identifier)

            if ?present(*label_lookup, self:entries:identifier) {
                error($"label " ~ self:entries:identifier ~ $" is already defined")
            }

            set path := path(label_lookup, self:entries:identifier)
            set *path := self
            return self
        }

        top function(self) {
            call($shego:generate_colors)

            if &root:debug {
                set start_time := time()
            }

            set &build:namespace := ${ types {} type_groups [] instance_type_groups [] namespaces {} labels {} }

            @set &build:namespace:types := append(&build:namespace:types, ${ identifier Byte type byte })
            @set &build:namespace:types := append(&build:namespace:types, ${ identifier Integer type integer signed !false width 64 })
            @set &build:namespace:types := append(&build:namespace:types, ${ identifier Float type float signed !false width 64 })

            set &build:namespace:types := insert(&build:namespace:types, $"Byte", ${ type byte intrinsic native })
            set &build:namespace:types := insert(&build:namespace:types, $"Integer", ${ type integer intrinsic native signed !false width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"Integer<8>", ${ type integer intrinsic native signed !false width 8 })
            set &build:namespace:types := insert(&build:namespace:types, $"Integer<16>", ${ type integer intrinsic native signed !false width 16 })
            set &build:namespace:types := insert(&build:namespace:types, $"Integer<32>", ${ type integer intrinsic native signed !false width 32 })
            set &build:namespace:types := insert(&build:namespace:types, $"Integer<64>", ${ type integer intrinsic native signed !false width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"Integer<128>", ${ type integer intrinsic native signed !false width 128 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedInteger", ${ type integer intrinsic native signed !true width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedInteger<8>", ${ type integer intrinsic native signed !true width 8 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedInteger<16>", ${ type integer intrinsic native signed !true width 16 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedInteger<32>", ${ type integer intrinsic native signed !true width 32 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedInteger<64>", ${ type integer intrinsic native signed !true width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedInteger<128>", ${ type integer intrinsic native signed !true width 128 })
            set &build:namespace:types := insert(&build:namespace:types, $"Float", ${ type float intrinsic native signed !false width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"Float<16>", ${ type float intrinsic native signed !false width 16 })
            set &build:namespace:types := insert(&build:namespace:types, $"Float<32>", ${ type float intrinsic native signed !false width 32 })
            set &build:namespace:types := insert(&build:namespace:types, $"Float<64>", ${ type float intrinsic native signed !false width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"Float<128>", ${ type float intrinsic native signed !false width 128 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedFloat", ${ type float intrinsic native signed !true width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedFloat<16>", ${ type float intrinsic native signed !true width 16 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedFloat<32>", ${ type float intrinsic native signed !true width 32 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedFloat<64>", ${ type float intrinsic native signed !true width 64 })
            set &build:namespace:types := insert(&build:namespace:types, $"SignedFloat<128>", ${ type float intrinsic native signed !true width 128 })

            if ?present(self:entries, $blocks) {
                pass(self:entries:blocks, $#build:namespace)
            }

            if &root:debug {
                set elapsed_time := (time() - start_time)  / $1000.0
                set tag := call($shego:tag, &root:colors:green, $"completed")
                call($shego:print_pass, $register, tag ~ $" in " ~ elapsed_time ~ $"s")
            }

            return self
        }
    }
}
