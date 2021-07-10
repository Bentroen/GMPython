draw_text(200, 200, "Press 'E' to run Python file");

if (keyboard_check_pressed(ord("E"))) {
	try {
		result = python_run_file("demo", "sum", "2, 3");
	} catch (e) {
		show_message("Python exception raised while running module 'demo':\n\n" + e);
	}
}

if (!is_undefined(result)) {
	draw_text(200, 250, "Call result:");
	draw_text(200, 280, string(result));
}
