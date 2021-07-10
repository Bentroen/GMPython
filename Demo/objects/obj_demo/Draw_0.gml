// Draw info
draw_text(200, 100, "pygml demo")
draw_text(200, 120, "by Bentroen")

draw_text(100, 200, "Commands:");
draw_text(200, 220, "Press F1 to open the demo module");
draw_text(200, 240, "Press Tab to cycle fields");
draw_text(200, 260, "Press Enter to run Python call");

// Draw input boxes
for (var i = 0; i < 3; i++) {
	if (sel == i) {
		draw_set_color(c_aqua)
	} else {
		draw_set_color(c_white)
	}
	var xx = 100;
	var yy = 350 + 50 * i;
	draw_text(xx, yy, fields[i]);
	draw_rectangle(xx + 100, yy, xx + 400, yy + 25, true);
	draw_text(xx + 105, yy + 5, values[i]);
	if (sel == i && floor(get_timer() / 500000) % 2 == 0) {
		xx += 110 + string_width(values[i]);
		draw_line(xx, yy + 5, xx, yy + 20);
	}
}

// Detect key presses
if (keyboard_check_pressed(vk_backspace)) {
	values[sel] = string_delete(values[sel], string_length(values[sel]), 1)
}
if (keyboard_lastkey != -1) {
	if (string_pos(keyboard_lastchar, chars) != 0) {
		values[sel] += keyboard_lastchar;
	}
	keyboard_lastkey = -1;
}

// Cycle through each input field
if (keyboard_check_pressed(vk_tab)) {
	sel += 1;
}
if (sel > 2) sel = 0;

// Open demo Python module
if (keyboard_check_pressed(vk_f1)) {
	url_open(working_directory + "demo.py")
}

// Run Python file
if (keyboard_check_pressed(vk_enter)) {
	try {
		result = python_run_file(values[0], values[1], values[2]);
	} catch (e) {
		show_message("Python exception raised while running module '" + values[0] + "':\n\n" + e);
	}
}

// Draw call result
draw_set_color(c_white)
if (!is_undefined(result)) {
	draw_text(100, 530, "Call result:");
	draw_text(200, 560, string(result));
}
