package snake

import rl "vendor:raylib"

SNAKE_WIDTH :: 32
SNAKE_HEIGHT :: 30
SNAKE_COLOR :: rl.GREEN

Snake :: struct {
	body: [dynamic]Body_Part,
}

Body_Part :: struct {
	position:  rl.Vector2,
	direction: Directions,
}

Directions :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

@(private = "file")
INVERSE_DIRECTION :: [Directions]Directions {
	.UP    = .DOWN,
	.DOWN  = .UP,
	.LEFT  = .RIGHT,
	.RIGHT = .LEFT,
}

@(private = "file")
DIRECTION_VECTORS :: [Directions]rl.Vector2 {
	.UP    = {0.0, -1.0},
	.DOWN  = {0.0, 1.0},
	.LEFT  = {-1.0, 0.0},
	.RIGHT = {1.0, 0.0},
}

create :: proc(
	position: rl.Vector2,
	direction := Directions.UP,
	length := 1,
	allocator := context.allocator,
) -> Snake {
	body := make([dynamic]Body_Part, 0, length, allocator)

	create_body(&body, position, length, direction)

	return Snake{body = body}
}

snake_clear :: proc(snake: ^Snake, position: rl.Vector2, direction := Directions.UP, length := 1) {
	clear(&snake.body)

	create_body(&snake.body, position, length, direction)
}

@(private)
create_body :: proc(
	body: ^[dynamic]Body_Part,
	position: rl.Vector2,
	length: int,
	direction: Directions,
) {
	directions := DIRECTION_VECTORS
	inv_direction := directions[direction] * {-1, -1}

	reserve(body, length)

	for i in 0 ..< length {
		append(
			body,
			Body_Part {
				position = position + f32(i) * inv_direction * {SNAKE_WIDTH, SNAKE_HEIGHT},
				direction = direction,
			},
		)
	}
}

destroy :: proc(s: ^Snake) {
	delete(s.body)
	s.body = nil
}

add_body :: proc(snake: ^Snake) {
	direction_vectors := DIRECTION_VECTORS
	tail := snake.body[len(snake.body) - 1]
	part := Body_Part {
		position  = tail.position - direction_vectors[tail.direction] * {SNAKE_WIDTH, SNAKE_HEIGHT},
		direction = tail.direction,
	}

	append(&snake.body, part)
}

is_new_direction_valid :: proc(s: Snake, direction: Directions) -> bool {
	inverse_directions := INVERSE_DIRECTION
	return !(inverse_directions[s.body[0].direction] == direction)
}

move :: proc(s: ^Snake) {
	directions := DIRECTION_VECTORS
	head := &s.body[0]
	current_body_state := head^
	head.position += directions[head.direction] * {SNAKE_WIDTH, SNAKE_HEIGHT}
	for &part in s.body[1:] {
		part, current_body_state = current_body_state, part
	}
}

render :: proc(s: Snake) {
	for part, i in s.body {
		color := SNAKE_COLOR if i == 0 else rl.DARKGREEN
		rl.DrawRectangle(
			i32(part.position.x),
			i32(part.position.y),
			SNAKE_WIDTH,
			SNAKE_HEIGHT,
			color,
		)
	}
}
