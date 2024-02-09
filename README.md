# excellent.mk

An excellent way to modularise Makefiles.

For projects with multiple modules, it's least tedious to define a Makefile
locally to each module – that way, modules stay contained in their source
directories, and if one is working on just a single module, your shell can
remain in that directory and you can issue `make` commands local to that module.

From there, people often have a top-level Makefile and just make recursive calls
to `make` to build each module separately as part of a big overall build
process.

But Makefiles work most efficiently when they have full understanding of the
dependency graph between build files. Recursive calls to `make` are slow if you
have lots of modules.

Enter the solution. Just write your Makefiles to work locally, `include
excellent.mk` and your local Makefiles, and hey presto, `make` understands your
whole tree.

# Installation

Just copy and commit `excellent.mk` into your local tree and then in your
Makefiles:

    include excellent.mk

# Usage

To use variables or targets from a module Makefile:

    include module/include.mk

`module/Makefile` will be included and:

1. Its variables will be made available with relative names

       output.o: ${module_OBJECTS}

2. Its targets will be made available with relative names

       all: module_all

3. Its `.PHONY` targets will automatically run when the same top-level target is
   invoked

       $ cat module/Makefile
       .PHONY: test
       test:
           @echo 'module'

       $ cat Makefile
       include excellent.mk
       include module/include.mk
       .PHONY: test
       test:
           @echo 'root'

       $ cd module; make test
       module

       $ cd ..; make test
       module
       root

## Includes and include locks

`excellent.mk` works by generating includable verisons of module Makefiles on
demand. These includes are a rewritten version of the Makefile with namespaces
added to each declaration.

To keep track of which Makefile the includes have been generated for,
`excellent.mk` also generates `.include.lock` files.

Both `include.mk` and `.include.lock` should be regarded as local development
files only and be added as ignore patterns to, e.g. `.gitignore`.

To clean up the includes and locks, invoke the phony `clean_include` target.

# Rules

1. Strictly downwards including only. Don't `include ../sibling/include.mk`.
2. Paths in recipes or targets should include at least one slash. Prepend paths
   with `./` if necessary.
3. Recipes are assumed to run globally available tools that operate on local
   paths. If your recipes are dependent on being in the module directory to run
   correctly, add a `cd ./;` before the recipe.
