module main

import os

const c_simai_meta_prefix = '&'

pub struct SimaiMetadata {
pub mut:
	title    string
	artist   string
	category string
	mapper   string
	extras   map[string]string
}

pub struct SimaiBeatmap {
pub mut:
	metadata SimaiMetadata

	timings []SimaiLine
	notes   []SimaiNote
}

pub fn SimaiBeatmap.is_note(text string) bool {
	slide_marks := '1234567890ABCDE'

	for slide_mark in slide_marks {
		if text == slide_mark.ascii_str() {
			return true
		}
	}

	return false
}

pub fn SimaiBeatmap.is_slide_note(text string) bool {
	slide_marks := '-^v<>Vpqszw"'

	for slide_mark in slide_marks {
		if text.contains(slide_mark.ascii_str()) {
			return true
		}
	}

	return false
}

pub fn SimaiBeatmap.is_touch_note(text string) bool {
	slide_marks := '-^v<>Vpqszw"'

	for slide_mark in slide_marks {
		if text.starts_with(slide_mark.ascii_str()) {
			return true
		}
	}

	return false
}

pub fn SimaiBeatmap.parse_stream(path string) &SimaiBeatmap {
	mut beatmap := &SimaiBeatmap{}

	mut text := os.read_file(path) or { panic('Failed to read file: ${err}') }

	mut position := 0
	mut bpm := 0.0
	mut cur_h_speed := 1.0
	mut time := 0.0
	// mut req_time := 0.0
	mut beats := 4
	mut have_note := false
	mut note_temp := ''
	mut y_count, mut x_count := 0, 0

	for i := 0; i < text.len; i++ {
		if text[i] == '|'.str && i + 1 < text.len && text[i + 1] == '|'.str {
			x_count++

			for i < text.len && text[i] != '\n'.str {
				i++
				x_count++
			}

			y_count++
			x_count = 0
			continue
		}

		if text[i] == '\n'.str {
			y_count++
			x_count = 0
		} else {
			x_count++
		}

		if i - i < position {
			// req_time = time
		}

		if text[i] == '('.str {
			have_note = false
			note_temp = ''

			mut bpm_s := ''

			i++
			x_count++

			for text[i] != ')'.str {
				bpm_s += text[i].ascii_str()
				i++
				x_count++
			}

			bpm = bpm_s.f32()
			continue
		}

		if text[i] == '{'.str {
			have_note = false
			note_temp = ''

			mut beat_s := ''
			i++
			x_count++

			for text[i] != '}'.str {
				beat_s += text[i].ascii_str()
				i++
				x_count++
			}

			beats = beat_s.int()
			continue
		}

		if SimaiBeatmap.is_note(text[i].ascii_str()) {
			have_note = true
		}

		if have_note && text[i] != ','.str {
			note_temp += text[i].ascii_str()
		}

		if text[i] == ','.str {
			if have_note {
				if note_temp.contains('`') {
					panic('UNSUPPORTED')
				} else {
					new_note := SimaiLine{
						time: (time * 1000.0).str().f32()
						op: .note
						data: [
							x_count.str().f32(),
							y_count.str().f32(),
							note_temp.f32(),
							bpm.str().f32(),
							cur_h_speed.str().f32(),
						]
						raw_text: note_temp
					}
					beatmap.notes << new_note.to_note()
				}

				note_temp = ''
			}

			beatmap.timings << SimaiLine{
				time: (time * 1000.0).str().f32()
				op: .bpm
				data: [
					x_count.str().f32(),
					y_count.str().f32(),
					bpm.str().f32(),
				]
			}

			time += 1.0 / (bpm / 60.0) * 4.0 / beats
			have_note = false
		}
	}

	return beatmap
}

pub fn SimaiBeatmap.parse(path string) &SimaiBeatmap {
	mut beatmap := &SimaiBeatmap{}

	lines := os.read_lines(path) or { panic('Failed to read file: ${err}') }

	// mut time := 0.0
	// mut bpm := 0.0
	// mut beats := 0.0
	// mut have_note := false

	for line in lines {
		if line == 'E' {
			break // Other difficulty levels are not supported
		}

		// Prefix
		if line.starts_with(c_simai_meta_prefix) {
			items := line.split_nth('=', 2)

			key, value := items[0][1..].str().trim_space(), items[1].trim_space()

			match key {
				'title' {
					beatmap.metadata.title = value
				}
				'artist' {
					beatmap.metadata.artist = value
				}
				'des_4' {
					beatmap.metadata.category = value
				}
				'des_5' {
					beatmap.metadata.mapper = value
				}
				else {
					beatmap.metadata.extras[key] = value
				}
			}
		}
	}

	return beatmap
}

// Note OP
pub enum SimaiOP {
	junk
	bpm
	note
}

pub struct SimaiLine {
pub mut:
	time     f32
	op       SimaiOP = .junk
	data     []f32
	raw_text string
}

pub fn (line &SimaiLine) to_note() SimaiNote {
	mut note := SimaiNote{
		line: unsafe { line }
		time: line.time
	}

	if SimaiBeatmap.is_touch_note(line.raw_text) {
		note.touch_area = line.raw_text[0].ascii_str()

		if note.touch_area != 'C' {
			note.start_position = line.raw_text[1].ascii_str().int()
		} else {
			note.start_position = 8
		}

		note.@type = .touch
	} else {
		note.start_position = line.raw_text[0].ascii_str().int()
		note.@type = .note
	}

	if line.raw_text.contains('f') {
		note.hanabi = true
	}

	if SimaiBeatmap.is_slide_note(line.raw_text) {
		note.@type = .slide
	}

	if line.raw_text.contains('b') {
		note.bbreak = true
	}

	if line.raw_text.contains('x') {
		note.ex = true
	}

	return note
}

pub enum SimaiNoteType {
	nan
	note
	slide
	touch
	touch_hold
}

pub struct SimaiNote {
pub mut:
	line  &SimaiLine
	@type SimaiNoteType = .nan

	touch_area     string
	start_position int

	time      f32
	hold_time f32

	hanabi bool
	bbreak bool
	ex     bool
}
