#!/usr/bin/wish
package require Tk

### Root
wm title . "Coin Counter"
wm geometry . "500x175"
wm minsize . 500 175
wm resizable . 1 0
grid columnconfigure . 0 -weight 1
grid rowconfigure . "0 2" -weight 1

### Coin frame
ttk::frame .coin_frame -padding 10
grid .coin_frame -column 0 -row 0 -sticky nswe

set cur_coin ""
set cur_count 0
proc coin_list {} {
	lsort [array names ::collection]
}
proc update_selector {} {
	.coin_frame.selector configure -values [coin_list]
}
proc update_count {} {
	set ::cur_count $::collection($::cur_coin)
}
proc set_count {} {
	set ::cur_coin [string trim $::cur_coin " "]
	if [expr ![string compare $::cur_coin ""]] return
	set ::collection($::cur_coin) $::cur_count
	update_selector ;# in case the value didn't exist before
}

ttk::combobox .coin_frame.selector -textvariable cur_coin -values ""
bind .coin_frame.selector <<ComboboxSelected>> update_count
bind .coin_frame.selector <Return>  set_count
bind .coin_frame.selector <KP_Enter>  set_count
ttk::spinbox .coin_frame.count -textvariable cur_count -command set_count \
	-from 0 -to 1e6 -increment 1 -wrap 0 -justify left
bind .coin_frame.count <Return> set_count
bind .coin_frame.count <KP_Enter> set_count
grid .coin_frame.selector -column 0 -row 0 -rowspan 2 -sticky we -padx 5
grid .coin_frame.count -column 1 -row 0 -sticky we -padx 5 -pady "0 5"

ttk::button .coin_frame.remover -text "Delete" \
	-command {catch {unset ::collection($::cur_coin)}; update_selector}
grid .coin_frame.remover -column 1 -row 1 -sticky nswe -padx 5

grid columnconfigure .coin_frame 0 -weight 5
grid columnconfigure .coin_frame 1 -weight 1
grid rowconfigure .coin_frame "0 1" -weight 1

### Separator
grid [ttk::separator .sep -orient horizontal] -column 0 -row 1 -sticky we

### File frame
ttk::frame .file_frame -padding 10
grid .file_frame -column 0 -row 2 -sticky nswe

proc save_collection {filename} {
	if [catch {set fh [open $filename w]}] {
		tk_messageBox -type ok -icon warning -message "File not written"
		return
	}
	puts $fh [array get ::collection]
	close $fh
}
proc load_collection {filename} {
	if [catch {set fh [open $filename r]}] {
		tk_messageBox -type ok -icon warning -message "File not read"
		return
	}
	catch {unset ::collection}
	array set ::collection [gets $fh]
	set ::cur_coin ""
	set ::cur_count 0
	close $fh
}

ttk::button .file_frame.saveb -text "Save File" -command {save_collection [tk_getSaveFile]}
ttk::button .file_frame.loadb -text "Load File" -command {load_collection [tk_getOpenFile]; update_selector}
grid .file_frame.saveb -column 0 -row 0 -sticky nswe -padx "0 5"
grid .file_frame.loadb -column 1 -row 0 -sticky nswe -padx "5 0"

grid rowconfigure .file_frame 0 -weight 1
grid columnconfigure .file_frame "0 1" -weight 1

if [expr $argc>0] {load_collection [lindex $argv 0]; update_selector}

### Summary window
set search ""
proc show_summary {} {
	if {![catch {toplevel .s}]} {
		wm title .s "Summary"
		wm resizable .s 1 0
		wm minsize .s 200 -1
	
		frame .s.search
		grid .s.search -column 0 -row 0 -sticky we
		ttk::entry .s.search.bar -textvariable search
		bind .s.search.bar <Return> update_summary_list
		bind .s.search.bar <KP_Enter> update_summary_list
		ttk::button .s.search.go -text "Search" -command update_summary_list
		grid .s.search.bar -column 0 -row 0 -sticky we
		grid .s.search.go -column 1 -row 0 -sticky nswe
		grid columnconfigure .s.search 0 -weight 1
	
		frame .s.ct -background "#FFFFFF"
		grid .s.ct -column 0 -row 1 -sticky nswe
		ttk::label .s.ct.name -text "Name" -background "#FFFFFF"
		ttk::label .s.ct.count -text "Count" -justify right -background "#FFFFFF"
		grid .s.ct.name -column 0 -row 0 -sticky w
		grid .s.ct.count -column 1 -row 0 -sticky e
		grid columnconfigure .s.ct "0 1" -weight 1
		grid columnconfigure .s 0 -weight 1
	}
	update_summary_list
}
proc update_summary_list {} {
	destroy .s.dat
	grid [frame .s.dat] -column 0 -row 2 -sticky nswe
	grid columnconfigure .s.dat "0 1" -weight 1
	set r 0
	set s 0
	foreach coin [coin_list] {
		if {[string match -nocase *$::search* $coin]} {
			add_summary_data $coin [incr r]
			incr s $::collection($coin)
		}
	}
	.s.ct.name configure -text "Name ($r)"
	.s.ct.count configure -text "Count ($s)"
}
proc add_summary_data {coin row} {
	set color [expr ($row%2)?"#F0F0F0":"#FFFFFF"]
	set update_cmd "set ::cur_coin {$coin}; update_count"
	frame .s.dat.r$row -background $color
	bind .s.dat.r$row <1> $update_cmd
	ttk::label .s.dat.r$row.c -text $coin -background $color
	bind .s.dat.r$row.c <1> $update_cmd
	ttk::label .s.dat.r$row.cc -text $::collection($coin) -background $color -justify right
	bind .s.dat.r$row.cc <1> $update_cmd
	grid .s.dat.r$row -column 0 -row $row -columnspan 2 -sticky nswe
	grid .s.dat.r$row.c -column 0 -row 0 -sticky w
	grid .s.dat.r$row.cc -column 1 -row 0 -sticky e
	grid columnconfigure .s.dat.r$row "0 1" -weight 1
}
ttk::button .tmp -text "Summary" -command {set search ""; show_summary}
grid .tmp -column 0 -row 99 -columnspan 2 -pady "0 10"
