<!-- [![MELPA](https://melpa.org/packages/fpga-badge.svg)](https://melpa.org/#/fpga) -->

# fpga.el - FPGA & ASIC Utils for Emacs #

This package provides Emacs utilities for tools of major vendors of FPGA & ASIC:

* Xilinx, Altera, Lattice, Cadence, Siemens and Synopsys tools
* Synthesis/simulation compilation modes for error regexp matching:
   * Colorize error codes and jump to files where errors appeared
* Interactive shells with syntax highlighting and auto-completion
* Major-modes with syntax highlighting and auto-completion:
  * Vivado XDC major-mode
  * Quartus SDC and QSF major-modes
  * Cadence vManager VSIF major-mode
* Global Gtags creation from files in Vivado XPR and Quartus QPF project files
* And some others...

## Installation ##

<!-- ### MELPA ### -->

<!-- `fpga` is available on MELPA. -->

### straight.el ###

To install it via [straight](https://github.com/radian-software/straight.el) with `use-package`:

```emacs-lisp
(straight-use-package 'use-package)

(use-package fpga
  :straight (:host github :repo "gmlarumbe/fpga"))

```

## Basic config ##

First set which vendors you want tools for and then load the package.

For example, if you need tools for Xilinx/Cadence:

```emacs-lisp
(setq fpga-feature-list '(xilinx cadence))
(require 'fpga)
```

If you need tools for Altera/Siemens:
```emacs-lisp
(setq fpga-feature-list '(altera siemens))
(require 'fpga)
```

With `use-package`:

```emacs-lisp
(use-package fpga
  :init
  (setq fpga-feature-list '(xilinx cadence)))
```

## Features ##

### Synthesis/Simulation compilation modes ###

Compilation modes with their corresponding regexps are provided for each vendor tool:

  * `fpga-xilinx-vivado-compilation-mode`
  * `fpga-altera-quartus-compilation-mode`
  * `fpga-lattice-diamond-compilation-mode`
  * `fpga-cadence-xrun-compilation-mode`
  * `fpga-siemens-vsim-compilation-mode`
  * `fpga-synopsys-synplify-compilation-mode`

These are used by the package to define functions that perform synthesis/simulation compilations.
For example, `M-x fpga-xilinx-vivado-syn RET` will prompt the user for an XPR project file.
Once selected, a Vivado compilation with error message colorized will take place:

<!-- TODO: Insert screencast of compilation -->

### Improved interactive shells ###

Shells with syntax highlighting and autocompletion are provided for the following vendors:

  * `fpga-xilinx-vivado-shell`
  * `fpga-altera-quartus-shell`
  * `fpga-lattice-diamond-shell`
  * `fpga-synopsys-synplify-shell`

<!-- TODO: Insert screencast of shell -->

### Major-modes ###

The following major modes are provided to edit constraints and project files:

  * `fpga-xilinx-vivado-xdc-mode`
  * `fpga-altera-quartus-sdc-mode` and `fpga-altera-quartus-qsf-mode`
  * `fpga-cadence-vsif-mode`

<!-- TODO: Insert screencast of some of these modes -->

### Global Gtags creation from project files ###

Running `M-x fpga-xilinx-vivado-tags RET` or `M-x fpga-altera-quartus-tags RET` will prompt for a project file.
It will be parsed and a `gtags.files` will be generated in the selected directory. This file will later be used to gather tags for the project files.
One of the uses of this feature could be filtering out unused files for definitions/references navigation.
It can also be useful to generate the list of files used in a project for further hierarchy extraction.

## Other packages

* [verilog-ext](https://github.com/gmlarumbe/verilog-ext): SystemVerilog Extensions for Emacs
  * Package to edit VHDL sources
* [vhdl-ext](https://github.com/gmlarumbe/vhdl-ext): VHDL Extensions for Emacs
  * Package to edit VHDL sources

