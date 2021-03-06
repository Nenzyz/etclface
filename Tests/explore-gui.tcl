#!/usr/bin/env wish

# explore-gui.tcl
#	a GUI for exploratory testing.
#
# This was created in order execute arbitrary commands without having
# to type much.

package require etclface

# Data Handles
#	- All the data are kept in a single nest dictionary
#	- level 1 is the set of handle types, key=type, e.g. ec, pid, etc.
#	- level 2 is the set of handle names, key=name, e.g. ec1, ec2, pid1, pid2, etc.
#	  - also contains an index, initially zero, incremented before
#	    adding a handle.
#	- level 3 is the per handle data (a dictionary)
set Handles [dict create]

# for forms data entry
set ::conn_echandle {}
set ::conn_nodename {erlnode@localhost}

set ::init_nodename {etfnode}
set ::init_cookie {secretcookie}

set ::regsend_echandle {}
set ::regsend_fdhandle {}
set ::regsend_xbhandle {}
set ::regsend_server   {server1}

set ::encode_type  {atom}
set ::encode_value {}

set ::xbuff_withversion 1

proc diag {msg} {
	puts stderr "$::argv0: $msg"
}

proc show_error {msg} {
	tk_messageBox -type ok -message $msg -detail $::errorInfo -icon error
}

# new_form
# create and display a form in a separate window
# - the form will be on its own top level wiondow
# - it will be identified by the "name" parameter
# - if one is already active, it will be destroyed/replaced
proc new_form {name descr formproc actionproc} {
	set root .${name}
	# let's be brutal!
	catch [destroy $root]

	toplevel ${root}
	wm title ${root} $descr

	if [catch "$formproc $root"] {
		destroy $root
		return
	}

	ttk::button	${root}.ok	-text OK	-command $actionproc
	ttk::button	${root}.cancel	-text Cancel	-command "destroy ${root}"
	grid ${root}.ok ${root}.cancel
}

# check_handle
# check and provide a menu of handles for the user to choose
proc check_handle {type root handle_var} {
	if {![dict exists $::Handles ${type} index]} {
		tk_messageBox -type ok -message "No ${type} handles found."
		return -code error
	}
	ttk::label	${root}.${type}_lab_handle -text "$type Handle"
	set handlelist [dict keys [dict get $::Handles $type] ${type}*]
	set $handle_var [lindex $handlelist 0]
	tk_optionMenu ${root}.${type}_mb_handle $handle_var {*}$handlelist
	return
}

# form_conn
# collect parameters for etclface::connect
# - this is expected to be called from within new_form
proc form_conn {root} {
	if [catch {check_handle ec $root ::conn_echandle}] { return -code error}

	ttk::label	${root}.lab_nodename -text "Remote Node"
	ttk::entry	${root}.ent_nodename -textvariable ::conn_nodename

	grid ${root}.ec_lab_handle ${root}.ec_mb_handle
	grid ${root}.lab_nodename ${root}.ent_nodename
}

# form_encode
# collect parameters for etclface::encode
# - this is expected to be called from within new_form
proc form_encode {root} {
	set typelist {atom boolean char empty_list list_header long string tuple_header}
	if [catch {check_handle xb $root ::encode_xbhandle}] { return -code error}

	ttk::label	${root}.lab_type -text "Term type"
	tk_optionMenu	${root}.mb_type ::encode_type {*}$typelist

	ttk::label	${root}.lab_value -text "Term value/arity"
	ttk::entry	${root}.ent_value -textvariable ::encode_value

	grid ${root}.xb_lab_handle ${root}.xb_mb_handle
	grid ${root}.lab_type ${root}.mb_type
	grid ${root}.lab_value ${root}.ent_value
}

# form_init
# collect parameters for etclface::init
# - this is expected to be called from within new_form
proc form_init {root} {
	ttk::label	${root}.lab_node -text "nodename"
	ttk::entry	${root}.ent_node -textvariable ::init_nodename -validate all
	grid ${root}.lab_node ${root}.ent_node

	ttk::label	${root}.lab_cookie -text "cookie"
	ttk::entry	${root}.ent_cookie -textvariable ::init_cookie -validate all
	grid ${root}.lab_cookie ${root}.ent_cookie
}

# form_regsend
# collect parameters for etclface::reg_send
# - this is expected to be called from within new_form
proc form_regsend {root} {
	if [catch {check_handle ec $root ::regsend_echandle}] { return -code error}
	if [catch {check_handle fd $root ::regsend_fdhandle}] { return -code error}

	ttk::label ${root}.lab_server -text "Remote process name"
	ttk::entry ${root}.ent_server -textvariable ::regsend_server
	if [catch {check_handle xb $root ::regsend_xbhandle}] { return -code error}

	grid ${root}.ec_lab_handle ${root}.ec_mb_handle
	grid ${root}.fd_lab_handle ${root}.fd_mb_handle
	grid ${root}.xb_lab_handle ${root}.xb_mb_handle
	grid ${root}.lab_server    ${root}.ent_server
}

# form_xbuff
# collect parameters for etclface::xb_new
# - this is expected to be called from within new_form
proc form_xbuff {root} {
	ttk::checkbutton ${root}.ckb_version -text "with version" -variable ::xbuff_withversion
	grid ${root}.ckb_version -columnspan 2
}

# do_conn
# verify paremeters and execute etclface::connect
# - this is expected to be called via the form_conn's OK button
proc do_conn {} {
	if {![dict exists $::Handles ec $::conn_echandle]} {
		tk_messageBox -type ok -message "Please select an ec Handle" -icon error
		return
	}
	if [catch {	set ec [dict get $::Handles ec $::conn_echandle handle]
			set fd [etclface::connect $ec $::conn_nodename]
			set ch [etclface::make_chan $fd R]
			} result] {
		show_error $result
	} else {

		add_handle fd "fd $fd chan $ch echandle $::conn_echandle nodename $::conn_nodename"
	}
	destroy .form_conn
}

# do_encode
# verify paremeters and execute etclface::encode_*
# - this is expected to be called via the form_encode's OK button
proc do_encode {} {
	set xb [dict get $::Handles xb $::encode_xbhandle handle]
	if [catch {	if {$::encode_type == "empty_list"} {
				etclface::encode_${::encode_type} $xb
			} else {
				etclface::encode_${::encode_type} $xb "$::encode_value"
			}
			} result ] {
		show_error $result
	}
	destroy .form_encode
}

# do_init
# verify paremeters and execute etclface::init
# - this is expected to be called via the form_init's OK button
proc do_init {} {
	if [catch {	if [string length $::init_cookie] {
				etclface::init $::init_nodename $::init_cookie
			} else {
				etclface::init $::init_nodename
			} } result ] {
		show_error $result
	} else {
		add_handle ec "handle $result nodename $::init_nodename cookie $::init_cookie"
	}
	destroy .form_init
}

# do_regsend
# verify paremeters and execute etclface::reg_send
# - this is expected to be called via the form_regsend's OK button
proc do_regsend {} {
	if [catch {	set ec [dict get $::Handles ec $::regsend_echandle handle]
			set fd [dict get $::Handles fd $::regsend_fdhandle fd]
			set xb [dict get $::Handles xb $::regsend_xbhandle handle]
			etclface::reg_send $ec $fd $::regsend_server $xb
			} result ] {
		show_error $result
	}
	destroy .form_regsend
}

# do_xbuff
# verify paremeters and execute etclface::reg_send
# - this is expected to be called via the form_regsend's OK button
proc do_xbuff {} {
	if [catch {	if {$::xbuff_withversion} {
				etclface::xb_new -withversion
			} else {
				etclface::xb_new
			} } result ] {
		show_error $result
	} else {
		add_handle xb "handle $result"
	}
	destroy .form_xbuff
}

# add_handle
# generic function to save a handle
proc add_handle {type data} {
	# create the type specific dictionary, if this is the first ever handle of this type
	if {![dict exists $::Handles $type]} {
		dict set ::Handles $type [dict create index 0]
	}
	# get the next index
	dict with ::Handles {
		dict incr $type index
	}
	set index [dict get $::Handles $type index]
	# name is ec1, ec2, pid4, etc
	set name ${type}${index}
	# save the data
	dict set ::Handles $type $name [dict create {*}$data]
	diag "add_handle: $::Handles"
}

proc hantree_init {root row col} {
	set tree ${root}.tree
	set hbar ${root}.hbar
	set vbar ${root}.vbar

	ttk::treeview $tree -columns {data} \
		-yscrollcommand "$vbar set" -xscrollcommand "$hbar set"
	ttk::scrollbar $vbar -orient vertical	-command "$tree yview"
	ttk::scrollbar $hbar -orient horizontal	-command "$tree xview"

	grid $tree -row [expr $row+0] -column [expr $col+0] -sticky nsew
	grid $vbar -row [expr $row+0] -column [expr $col+1] -sticky ns
	grid $hbar -row [expr $row+1] -column [expr $col+0] -sticky ew

	grid columnconfigure	$root $col -weight 1
	grid rowconfigure	$root $row -weight 1
}

proc hantree_refresh {root} {
	set tree ${root}.tree
	foreach hantype [lsort [dict keys $::Handles]] {
		if {![$tree exists $hantype]} {
			$tree insert {} end -id $hantype -open true -text $hantype
		}
		if [$tree exists ${hantype}_index] {
			$tree item ${hantype}_index -values [dict get $::Handles $hantype index]
		} else {
			$tree insert $hantype end -id ${hantype}_index -open true -text index \
				-values [dict get $::Handles $hantype index]
		}
		set handlelist [dict keys [dict get $::Handles $hantype] ${hantype}*]
		foreach handle [lsort $handlelist] {
			if {![$tree exists $handle]} {
				$tree insert $hantype end -id $handle -open true -text $handle
			}
			set handata [dict get $::Handles $hantype $handle]
			foreach hanpar [lsort [dict keys $handata]] {
				if [$tree exists ${handle}_${hanpar}] {
					$tree item ${handle}_${hanpar} -values [dict get $handata $hanpar]
				} else {
					$tree insert $handle end -id ${handle}_${hanpar} -text $hanpar -value [dict get $handata $hanpar]
				}
			}
		}
	}
}

#  MAIN  ##########################

# main window has a quit button at top right and a tabbed window underneth

grid [ttk::button .quit -text QUIT -command exit] -sticky e
grid [ttk::separator .hsep -orient horizontal] -sticky ew

# single tabbed notebook will contain everything
grid [ttk::notebook .nb] -sticky nsew
ttk::notebook::enableTraversal .nb

# let the notebook stretch with the window
grid columnconfigure	. 0 -weight 1
grid rowconfigure	. 2 -weight 1

# all command buttons are in one frame
set cf [ttk::frame .commandframe]
array set commands {
	conn	"Connection Form"
	encode	"Encode a term"
	init	"Initialization Form"
	regsend	"Registered Send Form"
	xbuff	"x_buff Form"
}
foreach name [lsort [array names commands]] {
	set cfnb $cf.${name}_b
	set cfnl $cf.${name}_l
	ttk::button $cfnb -text $name -command "new_form form_${name} {$commands($name)} form_$name do_$name"
	ttk::label $cfnl -text $commands($name)
	grid $cfnb $cfnl
	grid $cfnb -sticky ew
	grid $cfnl -sticky w
}
.nb add $cf -text Commands

#
# The Handles data structure is shown in its own notebook tab
set hf [ttk::frame .handleframe]
grid [ttk::button $hf.refresh -text Refresh -command "hantree_refresh $hf"] -sticky w
grid [ttk::separator $hf.sep -orient horizontal] -sticky ew
hantree_init $hf 2 0

.nb add $hf -text Handles -sticky nsew

