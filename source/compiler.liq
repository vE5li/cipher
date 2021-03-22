project {
    name            "cipher"
    author          "ve5li"
    contact         "ve5li@tuta.io"
}

directories {
    core            "/usr/share/cipher/data/core/"
    passes          "/usr/share/cipher/data/passes/"
    library         "/usr/share/cipher/data/library/"
    utility         "/usr/share/shego/data/"
}

extentions {
    cipher          "cip"
    cache           "che"
    intermediate    "ll"
    object          "elf"
    binary          "out"
    data            "data"
}

command_lookup {
    help            { flag "-h" long "--help"       environment "CIPHER_SHOW_HELP"          default !false      once !false }
    debug           { flag "-d" long "--debug"      environment "CIPHER_DEBUG"              default !false      once !true  }
    symbols         { flag "-S" long "--symbols"    environment "CIPHER_EXPORT_SYMBOLS"     default !false      once !true  }
    lucky           { flag "-L" long "--lucky"      environment "CIPHER_LUCKY"              default !false      once !true  }
    source          { flag "-s" long "--source"     environment "CIPHER_SOURCE_DIRECTORY"   default "source/"   once !true  }
    output          { flag "-o" long "--output"     environment "CIPHER_OUTPUT_DIRECTORY"   default "output/"   once !true  }
}

#functions {

    #main function(name: string, function: string, [arguments: string]) {

        set start_time := time()
        set library_path := &root:directories:utility ~ $"library." ~ &root:extentions:data
        set &root := merge(&root, read_map(library_path))
        call($shego:generate_colors)

        if function == $"new" {
            call($new, arguments)
            terminate
        }

        set user_functions := ${ "verify" verify "reverify" reverify "build" build "run" run "rebuild" rebuild "clean" clean }
        set configuration := call($shego:process_arguments, &root:command_lookup, arguments)
        set &root:debug := configuration:debug

        if configuration:help {
            call($show_help)
            terminate
        }

        if ?not_present(user_functions, function) {
            call($shego:print_error, $"compiler has no function called " ~ function)
            call($show_help)
            terminate
        }

        call($shego:print_debug, $"running " ~ function ~ $"...")
        call(user_functions[function], name, configuration)

        if configuration:lucky {
            call($shego:print_lucky)
        }

        set delta_time := (time() - start_time)  / $1000.0
        set formatted := slice(string(delta_time), $1, $3)
        call($shego:print_success, $"completed in " ~ formatted ~ $"s")
    }

    new function(arguments: list) {

        ensure(?not_empty(arguments), $"expected a project name")
        ensure(length(arguments) < $3, $"too many parameters for new provided")

        if ?file_present(arguments:1) {
            print_line($"directory already exists, nothing was changed")
            terminate
        }

        set woring_directory := call($shego:append_separator, arguments:1, $'/')

        if length(arguments) > $1 {
            set source_directory := call($shego:append_separator, arguments:2, $'/')
            set path := woring_directory ~ source_directory ~ $"main." ~ &root:extentions:cipher
        } else {
            set path := woring_directory ~ $"source/main." ~ &root:extentions:cipher
        }

        set new_file := $"label main: Function(arguments: Vector<String>) -> Integer := {\n\n    print_line?(\"hello, world!\")\n    return 0\n}\n"
        call($shego:write_create, path, new_file)
        call($shego:print_success, $"created main file at " ~ path)
    }

    verify function(name: string, configuration: map) {

        call($shego:print_debug, $"loading language...")

        set compiler_core := $[ tokenizer parser ]
        set compiler_pipeline := $[ register infer resolve generate ]
        set compiler := map($#pipeline := compiler_pipeline, $debug := configuration:debug)

        set library_path := &root:directories:utility ~ $"library." ~ &root:extentions:data
        set compiler := merge(compiler, read_map(library_path))

        iterate compiler_core as key, core {
            set path := &root:directories:core ~ core ~ $'.' ~ &root:extentions:data
            set compiler := merge(compiler, read_map(path))
        }

        iterate compiler_pipeline as key, pass {
            set path := &root:directories:passes ~ pass ~ $'.' ~ &root:extentions:data
            set compiler := merge(compiler, read_map(path))
        }

        set source_file := configuration:source ~ $"main." ~ &root:extentions:cipher
        set file_content := read_file(source_file)

        set tokenizer_data := tokenize(compiler, file_content, source_file, $!false, $!true)
        set parser_data := parse(compiler, tokenizer_data:token_stream, tokenizer_data:registry)
        set build_data := build(compiler, parser_data)

        set output_file := configuration:output ~ name ~ $'.' ~ &root:extentions:intermediate
        call($shego:write_create, output_file, build_data:code)
    }

    build function(name: string, configuration: map) {
        call($verify, name, configuration)

        set base_file_name := configuration:output ~ name ~ $'.'
        set intermediate_file := base_file_name ~ &root:extentions:intermediate
        set object_file := base_file_name ~ &root:extentions:object
        set binary_file := base_file_name ~ &root:extentions:binary

        call($shego:print_debug, $"creating object file...")
        set status := silent($"llc", intermediate_file, $"-o", object_file, $"-filetype=obj")
        if not(status:success) {
            print_line($"failed to create object file")
            if configuration:debug {
                print_line(status:output)
            }
            error($"failed to build " ~ name)
        }

        call($shego:print_debug, $"creating binary file...")
        set status := silent($"gcc", object_file, $"-o", binary_file, $"-no-pie")
        if not(status:success) {
            print_line($"failed to create binary file")
            if configuration:debug {
                print_line(status:output)
            }
            error($"failed to build " ~ name)
        }
    }

    run function(name: string, configuration: map) {
        call($build, name, configuration)
        set binary_file := configuration:output ~ name ~ $'.' ~ &root:extentions:binary
        set status := system($"bash", $"-c", binary_file)
    }

    reverify function(name: string, configuration: map) {
        call($clean, name, configuration)
        call($verify, name, configuration)
    }

    rebuild function(name: string, configuration: map) {
        call($clean, name, configuration)
        call($build, name, configuration)
    }

    clean function(name: string, configuration: map) {
        call($shego:print_clean, $"removing build files...")
        set command := $"rm -rf " ~ configuration:output ~ $"*"
        system($"bash", $"-c", command)
    }

    show_help function() {
        print_line()
        print_line($"usage:")
        print_line($"  $            cipher <function> [options]")
        print_line()
        print_line($"functions:")
        print_line($"  verify       compile without building a binary")
        print_line($"  build        compile and invoke next stage compilers")
        print_line($"  clean        remove all build files")
        print_line($"  reverify     clean and verify")
        print_line($"  rebuild      clean and build")
        print_line()
        print_line($"options:")
        print_line($" -h --help     show help menu")
        print_line($" -o --output   set output directory")
        print_line($" -s --source   set source directory")
        print_line($" -S --symbols  export symbols when creating the binary")
        print_line($" -d --debug    enable debug mode")
        print_line()
        print_line($"contact:")
        print_line($"  #            github.com/ve5li/cipher")
        print_line($"  @            ve5li@tuta.io")
        print_line()
    }
}
