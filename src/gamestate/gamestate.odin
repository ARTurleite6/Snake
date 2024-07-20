package gamestate

import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:strings"
import "src:snake"
import rl "vendor:raylib"

FOOD_WIDTH :: 32
FOOD_HEIGHT :: 30

WIDTH :: 1024
HEIGHT :: 720

MAX_NUMBER_TILES_X :: WIDTH / FOOD_WIDTH
MAX_NUMBER_TILES_Y :: HEIGHT / FOOD_HEIGHT

Game_State :: struct {
	snake: snake.Snake,
	score: uint,
	state: State,
	food:  rl.Vector2,
}

State :: enum {
	NotStarted,
	Paused,
	Running,
	Lost,
}

create :: proc(snake: snake.Snake) -> Game_State {
	state := Game_State {
		state = .NotStarted,
		snake = snake,
		score = 0,
	}
	generate_food(&state)
	return state
}

game_clear :: proc(state: ^Game_State) {
	state.state = .NotStarted
	state.score = 0
	snake.snake_clear(
		&state.snake,
		{0 = (WIDTH / 2) - snake.SNAKE_WIDTH, 1 = (HEIGHT / 2) - snake.SNAKE_HEIGHT},
		length = 3,
	)
	generate_food(state)
}

destroy :: proc(state: ^Game_State) {
	snake.destroy(&state.snake)
}

@(private = "file")
generate_food :: proc(state: ^Game_State, allocator := context.temp_allocator) {

	free_tiles := make(
		[dynamic]rl.Vector2,
		len = 0,
		cap = MAX_NUMBER_TILES_X * MAX_NUMBER_TILES_Y,
		allocator = allocator,
	)
	defer delete(free_tiles)

	for y in 1 ..< MAX_NUMBER_TILES_Y - 1 {
		for x in 1 ..< MAX_NUMBER_TILES_X - 1 {
			free_tile := true
			tile := rl.Vector2{f32(x * FOOD_WIDTH), f32(y * FOOD_HEIGHT)}
			for part in state.snake.body {
				if part.position == tile {
					free_tile = false
					break
				}
			}

			if free_tile {
				append(&free_tiles, tile)
			}
		}
	}

	tile := free_tiles[rand.int_max(len(free_tiles))]

	state.food = tile

	log.logf(.Debug, "Generated food at position %v", state.food)
}

change_snake_direction :: proc(s: ^snake.Snake) {
	change_direction: Maybe(snake.Directions) = nil
	if (rl.IsKeyDown(.A)) {
		change_direction = .LEFT
	} else if (rl.IsKeyDown(.S)) {
		change_direction = .DOWN
	} else if (rl.IsKeyDown(.D)) {
		change_direction = .RIGHT
	} else if (rl.IsKeyDown(.W)) {
		change_direction = .UP
	}

	if value, changed := change_direction.?; changed && snake.is_new_direction_valid(s^, value) {
		log.logf(.Debug, "changed snake direction to %v", value)
		s.body[0].direction = value
	}
}

handle_input :: proc(state: ^Game_State) {
	if (rl.IsKeyDown(.P)) {
		state.state = .Paused
	} else if rl.IsKeyDown(.SPACE) && (state.state == .NotStarted || state.state == .Paused) {
		state.state = .Running
	} else if (rl.IsKeyDown(.R) && state.state != .NotStarted) {
		game_clear(state)
	} else {
		change_snake_direction(&state.snake)
	}
}

update :: proc(state: ^Game_State) {
	handle_input(state)

	if (state.state == .Running) {
		snake.move(&state.snake)

		head := state.snake.body[0]

		if head.position.x == 0 ||
		   head.position.x == WIDTH - FOOD_WIDTH ||
		   head.position.y == 0 ||
		   head.position.y == HEIGHT - FOOD_HEIGHT {
			state.state = .Lost
		}

		for part in state.snake.body[1:] {
			if head.position == part.position {
				state.state = .Lost
				break
			}
		}

		if state.snake.body[0].position == state.food {
			snake.add_body(&state.snake)
			state.score += 1
			log.logf(
				.Debug,
				"Snake eated food, new length is %d, score %d",
				len(state.snake.body),
				state.score,
			)
			generate_food(state)
		}
	}
}

draw :: proc(state: Game_State) {

	snake.render(state.snake)

	rl.DrawRectangle(i32(state.food.x), i32(state.food.y), FOOD_WIDTH, FOOD_HEIGHT, rl.RED)

	for x in 0 ..< WIDTH {
		rl.DrawRectangle(i32(x), 0, FOOD_WIDTH, FOOD_HEIGHT, rl.GRAY)
		rl.DrawRectangle(i32(x), HEIGHT - FOOD_HEIGHT, FOOD_WIDTH, FOOD_HEIGHT, rl.GRAY)
	}

	for y in 0 ..< HEIGHT {
		rl.DrawRectangle(0, i32(y), FOOD_WIDTH, FOOD_HEIGHT, rl.GRAY)
		rl.DrawRectangle(WIDTH - FOOD_WIDTH, i32(y), FOOD_WIDTH, FOOD_HEIGHT, rl.GRAY)
	}

	switch state.state {
	case .NotStarted:
		rl.DrawText("Press SPACE to start", 40, 40, 20, rl.RED)
	case .Running:
		rl.DrawText("Press P to pause the game", 40, 40, 20, rl.RED)
		rl.DrawText("Press R to restart the game", 40, 60, 20, rl.RED)
	case .Paused:
		rl.DrawText("Press SPACE to continue", 40, 40, 20, rl.RED)
	case .Lost:
		rl.DrawText("Press R to restart the game", 10, 60, 100, rl.RED)

	}

	if state.state != .NotStarted && state.state != .Lost {
		rl.DrawText(
			strings.unsafe_string_to_cstring(fmt.tprintf("Score %d", state.score)),
			40,
			80,
			20,
			rl.WHITE,
		)
	}
}
