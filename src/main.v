module main

import math
import time
import gg
import gx
import bass
import ryn
import os

fn C._sapp_glx_swapinterval(int)

@[heap]
pub struct RynGame {
mut:
	ctx &gg.Context = unsafe { nil }
	tc  TimeCounter
pub mut:
	sfx     &ryn.RynSFX
	sprite  &ryn.RynSprite = unsafe { nil }
	audio   &bass.Track
	beatmap &SimaiBeatmap
	queue   []&SimaiNote

	beatmap_root string
}

pub fn (mut game RynGame) initialize(_ voidptr) {
	C._sapp_glx_swapinterval(0)
	game.tc.reset(offset: 6000.0)
	game.sprite = ryn.RynSprite.create(mut game.ctx, game.beatmap_root)
}

pub fn (mut game RynGame) update() {
	game.tc.tick()

	game.ctx.draw_image(640 - 800 / 2, 360 - 800 / 2, 800, 800, game.sprite.bg)
	game.ctx.draw_circle_filled(640, 360, 360, gx.Color{0, 0, 0, 100})
	game.ctx.draw_rect_filled(0, 0, 275, 720, gx.black)
	game.ctx.draw_rect_filled(1007, 0, 600, 720, gx.black)

	game.ctx.draw_text(100, 600, 'TIME: ${game.tc.time:.2f}ms', color: gx.white, size: 32)

	scale := .75
	size := f32(980 * scale)
	game.ctx.draw_image(640 - size / 2, 360 - size / 2, size, size, game.sprite.sensor)

	// Time based events
	if game.tc.time >= -5000.0 {
		if game.sfx.intro.playing && game.sfx.intro.get_position() >= 3980.0 {
			if game.tc.time >= 0.0 && !game.audio.playing {
				println('[Ryn] Starting music!')
				game.audio.set_volume(0.5)
				game.audio.play()

				game.tc.reset()
				game.audio.set_position(0.0)
			}
		}

		if !game.sfx.intro.playing {
			println('[Ryn] Intro!')
			game.sfx.intro.play()
		}
	}

	// source: me
	// this has to be the most cursed code I've ever written
	frames_on_screen := 32.0

	update_window_time := f32(10000.0)
	note_preempt_time := f32(((1000.0 / 60.0) * frames_on_screen) * 1)
	note_move_time := f32((1000.0 / 60.0) * frames_on_screen)

	for i := 0; i < game.beatmap.notes.len; i++ {
		if game.beatmap.notes[i].time <= 0.0 {
			continue
		}

		if game.tc.time + update_window_time >= game.beatmap.notes[i].time
			&& game.beatmap.notes[i].@type != .nan {
			game.queue << &game.beatmap.notes[i]
			game.beatmap.notes.delete(i)
			i--
		}
	}

	for i := 0; i < game.queue.len; i++ {
		if i >= game.queue.len {
			continue
		}

		if game.tc.time + (note_preempt_time + note_move_time) >= game.queue[i].time {
			current_note := &game.queue[i]

			// Ratios of stuff
			mut ratio := f32(1 - 0.75)
			mut ratio_scale := f32(1.0)

			// I hate this math
			ratio_scale = f32(1.0 - (((current_note.time - game.tc.time) - note_move_time) / note_preempt_time))

			if game.tc.time + note_move_time >= current_note.time {
				ratio = math.max(f32(1 - 0.75), f32(1.0 - ((current_note.time - game.tc.time) / note_move_time)))
				ratio_scale = 1.0
			}

			mut start_position := ryn.calculate_note_position(current_note.start_position,
				size / 32)
			mut end_position := ryn.calculate_note_position(current_note.start_position,
				size / 2)
			mut scale_start := f32(0.0)
			mut scale_end := f32(1.0)

			mut sprite := game.sprite.note
			mut angle := 0.0

			match current_note.@type {
				.note {
					//
				}
				.slide {
					//
					angle = 360.0 * (ratio_scale + ratio)
					sprite = game.sprite.star
				}
				.touch {
					//
					start_position[0] = end_position[0]
					start_position[1] = end_position[1]
				}
				else {}
			}

			if game.queue[i].hanabi {
				//
			}

			if game.queue[i].bbreak {
				//
				sprite = game.sprite.bbreak
				angle = 360.0 * (ratio_scale + ratio)
			}

			if game.queue[i].ex {
				//
			}

			width := f32(96 * ryn.linear(scale_start, scale_end, ratio_scale))

			x := ryn.linear(640 + start_position[0], 640 + end_position[0], ratio) - width / 2
			y := ryn.linear(360 + start_position[1], 360 + end_position[1], ratio) - width / 2

			game.ctx.draw_image_with_config(
				img_id: sprite.id
				img_rect: gg.Rect{
					x: x
					y: y
					width: width
					height: width
				}
				color: gx.Color{255, 255, 255, u8(255 * ratio_scale)}
				rotate: int(angle)
			)
		}

		if game.tc.time >= game.queue[i].time {
			println('[Ryn] TIME: ${game.tc.time} | OBJECT: ${game.queue[i].time} | DELTA: ${game.tc.time - game.queue[i].time:.2f}')

			match game.queue[i].@type {
				.note {
					game.sfx.judge_note.play()
					game.sfx.note.play()
				}
				.slide {
					game.sfx.judge_note.play()
					game.sfx.slide.play()
				}
				.touch {
					game.sfx.judge_ex.play()
					game.sfx.touch.play()
				}
				else {}
			}

			if game.queue[i].hanabi {
				game.sfx.hanabi.play()
			}

			if game.queue[i].bbreak {
				game.sfx.bbreak.play()
			}

			if game.queue[i].ex {
				game.sfx.judge_ex.play()
			}

			game.queue.delete(i)
			i--
		}
	}
}

pub fn (mut game RynGame) draw() {
	game.ctx.begin()

	game.update()

	game.ctx.end()
}

pub fn (mut game RynGame) start() {
	game.ctx.run()
}

pub fn RynGame.create() &RynGame {
	bass.start()

	mut game := &RynGame{
		sfx: ryn.RynSFX.create()
		beatmap: unsafe { nil }
		audio: unsafe { nil }
		beatmap_root: 'assets/toho/'
	}

	game.beatmap = SimaiBeatmap.parse_stream(os.join_path(game.beatmap_root, 'maidata.txt'))
	game.audio = bass.new_track(os.join_path(game.beatmap_root, 'track.mp3'))

	game.ctx = gg.new_context(
		width: 1280
		height: 720
		user_data: game
		bg_color: gx.black
		// FNs
		init_fn: game.initialize
		frame_fn: game.draw
	)

	return game
}

fn main() {
	mut game := RynGame.create()
	game.start()
}
