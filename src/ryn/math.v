module ryn

import math

const c_angles = {
	3: 0
	4: 45
	5: 90
	6: 135
	7: 180
	8: 225
	1: 270
	2: 315
}

const c_angle_offset = 23

pub fn calculate_note_position(position int, distance f32) [2]f32 {
	angle := ryn.c_angles[position] + ryn.c_angle_offset

	angle_rad := math.radians(angle)

	x := distance * math.cos(angle_rad)
	y := distance * math.sin(angle_rad)

	return [f32(x), f32(y)]!
}

pub fn linear(start f32, end f32, ratio f32) f32 {
	return start + (end - start) * ratio
}
