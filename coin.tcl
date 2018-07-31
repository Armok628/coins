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

##### Root
wm resizable . 1 0
wm title . "Collection Counter"
wm protocol . WM_DELETE_WINDOW {
	array_out collection "collection.dat"
	destroy .
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
ttk::combobox .reader.selector -values "" -textvariable selected -postcommand {
	update_selector
	.reader.selector selection range 0 [string length $selected]
}
set selected "Search"
bind .reader.selector <<ComboboxSelected>> update_count
ttk::label .reader.count -text "0"
grid .reader.selector -column 0 -row 0 -sticky we -padx 5 -pady 5
grid .reader.count -column 1 -row 0 -padx 5 -pady 5
grid columnconfigure .reader 0 -weight 5
grid columnconfigure .reader 1 -weight 1
grid rowconfigure .reader 0 -weight 1

##### File frame
proc save_to_file {} {
	if [catch {array_out ::collection [tk_getSaveFile]}] {
		tk_messageBox -icon warning -message "File not saved" -type ok
	}
}
proc load_from_file {} {
	if [catch {array_in ::collection [tk_getOpenFile]}] {
		tk_messageBox -icon warning -message "File not loaded" -type ok
	}
}
#ttk::frame .ff
#grid .ff -column 0 -row 2 -sticky nswe
#grid rowconfigure . 2 -weight 1
#ttk::button .ff.s -text "Save File" -command save_to_file
#ttk::button .ff.l -text "Load File" -command load_from_file
#grid .ff.s -column 0 -row 0 -padx 5 -pady 5
#grid .ff.l -column 1 -row 0 -padx 5 -pady 5
#grid columnconfigure .ff "0 1" -weight 1
#grid rowconfigure .ff 0 -weight 1
catch {array_in collection "collection.dat"}
bind . <Control-l> load_from_file
bind . <Control-s> save_to_file

##### Controls
ttk::frame .controls
grid .controls -column 0 -row 1 -sticky nswe
grid rowconfigure . 1 -weight 1

ttk::button .controls.add -text "Add Entry" -command add_menu
ttk::button .controls.summ -text "Summary" -command summary_menu
ttk::button .controls.edit -text "Edit Entry" -command edit_menu
grid .controls.add -column 0 -row 0 -padx 5 -pady 5 -sticky nswe
grid .controls.summ -column 1 -row 0 -padx 5 -pady 5 -sticky nswe
grid .controls.edit -column 2 -row 0 -padx 5 -pady 5 -sticky nswe
grid columnconfigure .controls "0 1 2" -weight 1
grid rowconfigure .controls 0 -weight 1

##### Add
proc add_menu {} {
	if [catch {toplevel .add}] return
	grab set .add
	wm title .add "Add Item"
	wm resizable .add 1 0
	ttk::frame .add.menu
	grid .add.menu -column 0 -row 0 -sticky nswe
	grid columnconfigure .add 0 -weight 1
	grid rowconfigure .add 0 -weight 1

	set add_cmd {add_item $::addendum $::add_ct; reset_selector; destroy .add}
	ttk::entry .add.menu.name -textvariable ::addendum -width 40
	set ::addendum "New item"
	.add.menu.name selection range 0 8
	bind .add.menu.name <Return> $add_cmd
	focus .add.menu.name
	ttk::entry .add.menu.count -textvariable ::add_ct -width 10
	set ::add_ct 0
	ttk::button .add.menu.go -text "Add" -command $add_cmd
	grid .add.menu.name -column 0 -row 0 -sticky we -padx 5 -pady 5
	grid .add.menu.count -column 1 -row 0 -sticky we -padx 5 -pady 5
	grid .add.menu.go -column 0 -row 1 -columnspan 2 -padx 5 -pady 5
	grid columnconfigure .add.menu 0 -weight 1
	grid rowconfigure .add.menu 0 -weight 1
}
##### Summary
proc summary_menu {} {
	if [catch {toplevel .summ}] return
	wm resizable .summ 0 1
	wm title .summ "Summary"
	grab set .summ
	grid columnconfigure .summ 0 -weight 1
	grid rowconfigure .summ 1 -weight 1
	ttk::frame .summ.head
	grid .summ.head -column 0 -row 0 -sticky nswe
	grid columnconfigure .summ.head 0 -weight 1
	ttk::entry .summ.head.filter -textvariable ::filter
	bind .summ.head.filter <Return> do_summary_filter
	set ::filter ""
	ttk::button .summ.head.dofilt -text "Filter" -command do_summary_filter
	ttk::button .summ.head.export -text "Export" -command export
	ttk::label .summ.head.name -text "Name"
	ttk::label .summ.head.count -text "Count"
	grid .summ.head.filter -column 0 -row 0 -sticky we
	grid .summ.head.dofilt -column 1 -row 0 -sticky nswe
	grid .summ.head.export -column 2 -row 0 -sticky nswe
	grid .summ.head.name -column 0 -row 1 -sticky w
	grid .summ.head.count -column 2 -row 1 -sticky e
	ttk::scrollbar .summ.scroll -orient vertical -command ".summ.items yview"
	grid .summ.scroll -column 1 -row 0 -rowspan 2 -sticky ns
	populate_summary
}
proc export {} {
	set file [tk_getSaveFile]
	if [catch {set fh [open $file w]} err] {
		tk_messageBox -message "Export failed" -detail "$err" -icon warning -type ok
		return
	}
	set vals [list_items $::filter]
	foreach val $vals {
		puts $fh "$val: $::collection($val)"
	}
	close $fh
}
proc do_summary_filter {} {
	catch {destroy .summ.items}
	populate_summary
}
proc populate_summary {} {
	canvas .summ.items -yscrollcommand ".summ.scroll set"
	ttk::frame .summ.items.list
	set names [list_items $::filter]
	set sum 0
	set row 0
	foreach name $names {
		incr sum $::collection($name)
		add_summary_item $name $row
		incr row
	}
	grid .summ.items -column 0 -row 1 -sticky nswe
	.summ.items create window 0 0 -anchor nw -window .summ.items.list
	resize_canvas .summ.items
	.summ.head.name configure -text "Name ($row)"
	.summ.head.count configure -text "Count ($sum)"
}
proc add_summary_item {item row} {
	set color [expr $row%2?"#F0F0F0":"#FFFFFF"]
	set update_cmd "set ::selected {$item}; update_count"

	frame .summ.items.list.r$row -background $color
	bind .summ.items.list.r$row <1> $update_cmd
	grid .summ.items.list.r$row -column 0 -row $row -sticky we

	ttk::label .summ.items.list.r$row.name -text $item -background $color -width 100
	bind .summ.items.list.r$row.name <1> $update_cmd
	ttk::label .summ.items.list.r$row.count -text $::collection($item) -background $color
	bind .summ.items.list.r$row.count <1> $update_cmd

	grid .summ.items.list.r$row.name -column 0 -row 0 -sticky w
	grid .summ.items.list.r$row.count -column 1 -row 0 -sticky e
	grid columnconfigure .summ.items.list.r$row "0 1" -weight 1
}
proc resize_canvas {path} {
	update
	set size [$path bbox all]
	$path configure -scrollregion $size
	$path configure -width [lindex $size 2]
	#$path configure -height [lindex $size 3]
}
##### Edit
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

	set edit_cmd "edit_item {$item} \$editname \$editcount; reset_selector; destroy .edit"
	ttk::entry .edit.menu.name -textvariable ::editname -width 40
	bind .edit.menu.name <Return> $edit_cmd
	set ::editname $item
	focus .edit.menu.name
	.edit.menu.name selection range 0 [string length $item]
	ttk::spinbox .edit.menu.count -from 0 -to 1000000 -increment 1 -wrap 0 -textvariable ::editcount -width 10
	set ::editcount $::collection($item) 
	bind .edit.menu.count <Return> $edit_cmd
	ttk::button .edit.menu.submit -text "Submit" -command $edit_cmd
	ttk::button .edit.menu.delete -text "Delete" -command "remove_item {$item}; reset_selector; destroy .edit"
	grid .edit.menu.name -column 0 -row 0 -sticky we -padx 5 -pady 5
	grid .edit.menu.count -column 1 -row 0 -sticky we -padx 5 -pady 5
	grid .edit.menu.delete -column 0 -row 1 -padx 5 -pady 5
	grid .edit.menu.submit -column 1 -row 1 -padx 5 -pady 5
	grid columnconfigure .edit.menu 0 -weight 1
}
