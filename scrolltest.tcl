#!/usr/bin/tclsh
package require Tk
# Top level frame
frame .f
pack .f -expand yes -fill both -side top
# Canvas and scrollbar
canvas .f.c -yscrollcommand ".f.s set"
scrollbar .f.s -orient vertical -command ".f.c yview"
pack .f.s -side right -fill y
pack .f.c -expand yes -fill both -side top
# Frame to be scrolled
frame .f.c.f
for {set i 1} {$i<=($argc?[lindex $argv 0]:50)} {incr i} {
	grid [button .f.c.f.b$i -text "Button $i"] -column 0 -row $i
}
.f.c create window 0 0 -anchor nw -window .f.c.f
# Resize canvas scroll region and width
proc resize_canvas {path} {
	update
	set size [.f.c bbox all]
	$path configure -scrollregion $size
	$path configure -width [lindex $size 2]
}
resize_canvas .f.c
