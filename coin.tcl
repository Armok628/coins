#!/usr/bin/tclsh
package require Tk

##### Backend
array set collection ""
proc array_out {array filename} {
	upvar $array arr
	set file [open $filename w]
	puts $file [array get arr]
	close $file
}
proc array_in {array filename} {
	upvar $array arr
	set file [open $filename r]
	array set arr [read $file]
	close $file
}
proc list_items {{search ""}} {
	set names [lsort [array names ::collection]]
	if {$search eq ""} {
		return $names
	}
	set results ""
	foreach name $names {
		if [string match -nocase *$search* $name] {
			lappend results $name
		}
	}
	return $results
}
proc remove_item {name} {
	catch {unset ::collection($name)}
}
proc add_item {name {count 0}} {
	if {$name ne ""} {
		set ::collection($name) $count
	}
}
proc edit_item {name new_name count} {
	remove_item $name
	add_item $new_name $count
}

##### Reader
ttk::frame .reader
grid .reader -column 0 -row 0 -sticky nswe
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

proc update_selector {} {
	.reader.selector configure -values [list_items [.reader.selector get]]
}
proc reset_selector {} {
	set ::selected ""
	.reader.count configure -text 0
	update_selector
}
proc update_count {} {
	.reader.count configure -text $::collection([.reader.selector get])
}
ttk::combobox .reader.selector -values "" -textvariable selected -postcommand update_selector
set selected "Search"
bind .reader.selector <<ComboboxSelected>> update_count
ttk::label .reader.count -text "0"
grid .reader.selector -column 0 -row 0 -sticky we
grid .reader.count -column 1 -row 0
grid columnconfigure .reader 0 -weight 5
grid columnconfigure .reader 1 -weight 1
grid rowconfigure .reader 0 -weight 1

##### Controls
ttk::frame .controls
grid .controls -column 0 -row 1
grid rowconfigure . 1 -weight 1

ttk::button .controls.add -text "Add Entry" -command add_menu
ttk::button .controls.summ -text "Summary" -command summary_menu
ttk::button .controls.edit -text "Edit Entry" -command edit_menu
grid .controls.add -column 0 -row 0 -sticky nswe
grid .controls.summ -column 1 -row 0 -sticky nswe
grid .controls.edit -column 2 -row 0 -sticky nswe
grid columnconfigure .controls "0 1 2" -weight 1
grid rowconfigure .controls 0 -weight 1

##### Menus
proc add_menu {} {
	if [catch {toplevel .add}] return
	grab set .add
	wm title .add "Add Item"
#	wm resizable .add 1 0
	ttk::frame .add.menu
	grid .add.menu -column 0 -row 0 -sticky nswe
	grid columnconfigure .add 0 -weight 1
	grid rowconfigure .add 0 -weight 1

	set add_cmd {add_item $::addendum 0; reset_selector; destroy .add}
	ttk::entry .add.menu.name -textvariable ::addendum
	set ::addendum "New item"
	.add.menu.name selection range 0 8
	bind .add.menu.name <Return> $add_cmd
	focus .add.menu.name
	ttk::button .add.menu.go -text "Add" -command $add_cmd
	grid .add.menu.name -column 0 -row 0 -sticky we
	grid .add.menu.go -column 0 -row 1
	grid columnconfigure .add.menu 0 -weight 1
	grid rowconfigure .add.menu 0 -weight 1
}
proc summary_menu {} {
}
proc add_summary_item {item row} {
	set color [expr $row%2?"#FFFFFF":"#F0F0F0"]
	set update_cmd ".reader.selector configure -text $item; update_count"
	ttk::frame .summ.items.r$row -background $color
	bind .summ.items.r$row <1> update_cmd
	ttk::label .summ.items.r$row.name -text $item -background $color
	bind .summ.items.r$row.name <1> update_cmd
	ttk::separator .summ.items.r$row.sep -orient vertical
	bind .summ.items.r$row.sep <1> update_cmd
	ttk::label .summ.items r$row.count -text $::collection($item) -background $color
	bind .summ.items.r$row.count <1> update_cmd
	grid .summ.items.r$row -column 0 -row $row -sticky we
	grid .summ.items.r$row.name -column 0 -row 0 -sticky w
	grid .summ.items.r$row.sep -column 1 -row 0 -sticky ns
	grid .summ.items.r$row.count -column 2 -row 0 -sticky e
	grid columnconfigure .summ.items.r$row "0 2" -weight 1
}
proc update_summary {} {
	set names [list_items $::filter]
	set sum 0
	set row 1
	foreach name $names {
		incr sum $::collection($name)
		add_summary_item $name $row
	}
}
proc edit_menu {} {
	set item [.reader.selector get]
	if {![info exists ::collection($item)]} return
	if [catch {toplevel .edit}] return
	grab set .edit
	wm title .edit "Editing $item"
#	wm resizable .edit 1 0
	ttk::frame .edit.menu
	grid .edit.menu -column 0 -row 0 -sticky nswe
	grid columnconfigure .edit 0 -weight 1
	grid rowconfigure .edit 0 -weight 1

	set edit_cmd "edit_item $item \$editname \$editcount; reset_selector; destroy .edit"
	ttk::entry .edit.menu.name -textvariable ::editname
	bind .edit.menu.name <Return> $edit_cmd
	set ::editname $item
	focus .edit.menu.name
	.edit.menu.name selection range 0 [string length $item]
	ttk::spinbox .edit.menu.count -from 0 -to 1000000 -increment 1 -wrap 0 -textvariable ::editcount
	set ::editcount $::collection($item) 
	bind .edit.menu.count <Return> $edit_cmd
	ttk::button .edit.menu.submit -text "Submit" -command $edit_cmd
	ttk::button .edit.menu.delete -text "Delete" -command "remove_item $item; reset_selector; destroy .edit"
	grid .edit.menu.name -column 0 -row 0 -sticky we
	grid .edit.menu.count -column 1 -row 0 -sticky we
	grid .edit.menu.delete -column 0 -row 1
	grid .edit.menu.submit -column 1 -row 1
	grid columnconfigure .edit.menu 0 -weight 1
}
array_in collection sampledata
