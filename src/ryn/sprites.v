module ryn

import os
import gg
import gx

pub struct RynSprite {
pub mut:
	note   gg.Image
	bbreak gg.Image
	each   gg.Image
	slide  gg.Image
	star   gg.Image
	sensor gg.Image
	bg     gg.Image
}

pub fn RynSprite.create(mut ctx gg.Context, beatmap_root string) &RynSprite {
	mut sprites := &RynSprite{}

	sprites.note = ctx.create_image('assets/sprites/tap.png') or { panic(err) }
	sprites.bbreak = ctx.create_image('assets/sprites/tap_break.png') or { panic(err) }
	sprites.each = ctx.create_image('assets/sprites/tap_each.png') or { panic(err) }

	sprites.star = ctx.create_image('assets/sprites/star_each.png') or { panic(err) }

	sprites.sensor = ctx.create_image('assets/sprites/outline.png') or { panic(err) }

	sprites.bg = ctx.create_image(os.join_path(beatmap_root, 'bg.jpg')) or { panic(err) }

	return sprites
}
