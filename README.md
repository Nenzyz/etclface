
# etclface - An Erlang/Tcl Interface

This is a [Tcl](http://tcl.tk) extension that will allow software written
in Tcl and [Erlang](http://www.erlang.org/) to communicate using the
Erlang/OTP interface, `erl_interface`.

## Introduction

Erlang provides two native interfaces that enable communication between
Erlang processes and external programs using Erlang's message passing
mechanism.

One of these interfaces is `erl_interface`, which allows the external
program to register as a node in a Distributed Erlang network and exchange
messages with Erlang processes.

Some of the aims of the Tcl extension are:

* Let a Tcl application use Erlang for processing.
* Let an Erlang application use a Tcl/Tk based GUI, or other Tcl
extensions such as Expect.

The initial version will only expose enough `erl_interface` functions to
allow a Tcl application to communicate with Erlang nodes.  Currently,
there are many functions in `erl_interface`, however, only the following
subset will be provided:

* register with epmd as a node
* send/receive messages
* decode/encode between internal and Tcl types

## Build and Installation

### Prerequisites

You will need the following software/packages:

* Tcl/Tk 8.5 or higher
* Erlang/OTP, R15B03 or higher
* TeX, if producing the documentation
* Cweb can be obtained from [here](http://www.literateprogramming.com/cweb_download.html)
* cmake
* ccmake, not mandatory, but a useful tool for editing cmake parameters
* make
* C compiler, GCC was used during development

### Build

Once you have the source files on a local disk, change to the `etclface`
directory, then

	mkdir -pv build		# for out-of-source builds
	cd build
	cmake ..
	make

The documentation is a single PDF file, it can be generated with

	make doc		

### Installation

if `make` is successful, then you should have a `libetclface.so` file in
the `build` directory. You can then install the library:

	make install		# ensure you have permissions

## Testing

The software has been tested on Debian GNU/Linux only.

The test scripts are can be found in the `Tests` directory.

## Feedback and Contributions

Comments and feedback are welcome, please use the issue tracker for this.

Please use pull requests for patch contributions.


Enjoy!

Fred Youhanaie

