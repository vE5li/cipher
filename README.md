# description
Cipher is a compiler for a rust like language

# build
For building on linux, you can use the install script provided in [yardstick](https://github.com/ve5li/yardstick) to install the entire toolchain. Simply clone the repository and execute the installer as such:
```
git clone https://github.com/ve5li/yardstick
cd yardstick/untility
./install.sh
```

# usage
You can create an empty project using ```cipher new <project name>``` or ```cipher new <project name> <source directory name>```. Inside the project folder the code can be compiled using ```cipher verify``` and built using ```cipher build```. To remove all build files you can run ```cipher clean``` or you can run ```cipher rebuild``` to remove build files and build the project again. You can also manually assemble and route the generated code using ```cipher assemble``` and ```cipher route``` respectively.

A different source directory can be specified with the ```-s``` flag and another output directory with the ```-o``` flag. To add external libraries you have to use the ```-l``` flag followed by a directory. If you want to strip symbols from the binary to save space you can do so using the ```-S``` flag. For debugging the compiler itself you can compile using the ```-d``` flag.
