module ryn

import bass

pub struct RynSFX {
pub mut:
	intro &bass.Track = unsafe { nil }

	note   &bass.Sample = unsafe { nil }
	slide  &bass.Sample = unsafe { nil }
	touch  &bass.Sample = unsafe { nil }
	bbreak &bass.Sample = unsafe { nil }
	hanabi &bass.Sample = unsafe { nil }

	judge_note  &bass.Sample = unsafe { nil }
	judge_break &bass.Sample = unsafe { nil }
	judge_ex    &bass.Sample = unsafe { nil }
}

pub fn RynSFX.create() &RynSFX {
	mut sfx := &RynSFX{}

	sfx.intro = bass.new_track('assets/sfx/track_start.wav')

	sfx.note = bass.new_sample('assets/sfx/answer.wav')
	sfx.slide = bass.new_sample('assets/sfx/slide.wav')
	sfx.touch = bass.new_sample('assets/sfx/touch.wav')
	sfx.bbreak = bass.new_sample('assets/sfx/break.wav')
	sfx.hanabi = bass.new_sample('assets/sfx/hanabi.wav')

	sfx.judge_note = bass.new_sample('assets/sfx/judge.wav')
	sfx.judge_break = bass.new_sample('assets/sfx/judge_break.wav')
	sfx.judge_ex = bass.new_sample('assets/sfx/judge_ex.wav')

	return sfx
}
