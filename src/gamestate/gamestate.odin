package gamestate

import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import "src:snake"
import rl "vendor:raylib"

when ODIN_OS == .Linux || ODIN_OS == .Darwin {
	SCORE_PATH :: ".cache/snake/highscore.txt"
} else {
	SCORE_PATH :: "/AppData/Local/snake/highscore.txt"
}

FOOD_WIDTH :: 32
FOOD_HEIGHT :: 30

SNAKE_INITIAL_LENGTH :: 4

WIDTH :: 1024
HEIGHT :: 720

MAX_NUMBER_TILES_X :: WIDTH / FOOD_WIDTH
MAX_NUMBER_TILES_Y :: HEIGHT / FOOD_HEIGHT

Game_State :: struct {
	snake:              snake.Snake,
	score:              uint,
	highest_score:      uint,
	highest_score_path: string,
	state:              State,
	food:               rl.Vector2,
}

State :: enum {
	NotStarted,
	Paused,
	Running,
	Lost,
}

create :: proc(allocator := context.allocator) -> Game_State {
	score_path := get_score_path(allocator)
	high_score := get_high_score(score_path)

	state := Game_State {
		state              = .NotStarted,
		snake              = snake.create(
			{(WIDTH / 2) - snake.SNAKE_WIDTH, (HEIGHT / 2) - snake.SNAKE_HEIGHT},
			length = SNAKE_INITIAL_LENGTH,
		),
		highest_score      = high_score,
		highest_score_path = score_path,
		score              = 0,
	}
	generate_food(&state)
	return state
}

@(private)
save_highest_score :: proc(state: ^Game_State) {
	score_path, score := state.highest_score_path, state.highest_score

	if state.score > score {
		log.infof("Reached a highest score in this run, new: %d, old: %d", state.score, score)
		if ok := os.write_entire_file(
			score_path,
			transmute([]u8)fmt.aprintf("%d\n", state.score, allocator = context.temp_allocator),
		); !ok {
			log.errorf("Error writing highest score to %s file", score_path)
		}
		log.infof("Score of %d saved to %s file", state.score, score_path)
	}
}

@(private)
get_high_score :: proc(path: string) -> uint {
	log.info("Storing the highest score")
	score: uint
	if data, ok := os.read_entire_file(path, context.temp_allocator); !ok {
		score = 0
	} else {
		score = strconv.parse_uint(strings.trim_space(string(data)), 10) or_else 0
	}
	return score
}

@(private)
get_score_path :: proc(allocator := context.allocator) -> string {
	context.allocator = allocator
	when ODIN_OS == .Linux || ODIN_OS == .Darwin {
		home_path := os.get_env("HOME")
	} else {
		home_path := os.get_env("USERPROFILE")
	}

	path := fmt.aprintf("%s/%s", home_path, SCORE_PATH)
	dir := filepath.dir(path)
	if !os.exists(dir) {
		os.make_directory(dir)
	}

	if new_path, allocation := filepath.from_slash(path); allocation {
		delete(path)
		path = new_path
	}
	return path
}

game_clear :: proc(state: ^Game_State) {
	save_highest_score(state)
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
	save_highest_score(state)
	delete(state.highest_score_path)
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
	if (rl.IsKeyDown(.A) || rl.IsKeyDown(.LEFT)) {
		change_direction = .LEFT
	} else if (rl.IsKeyDown(.S) || rl.IsKeyDown(.DOWN)) {
		change_direction = .DOWN
	} else if (rl.IsKeyDown(.D) || rl.IsKeyDown(.RIGHT)) {
		change_direction = .RIGHT
	} else if (rl.IsKeyDown(.W) || rl.IsKeyDown(.UP)) {
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
		head := &state.snake.body[0]
		if head.position.x + snake.SNAKE_WIDTH <= 0 || head.position.x >= WIDTH {
			log.debugf(
				"Old position = %v, new position = %v\n",
				head.position.x,
				WIDTH - head.position.x - snake.SNAKE_WIDTH,
			)
			head.position.x = WIDTH - head.position.x - snake.SNAKE_WIDTH
		} else if head.position.y + snake.SNAKE_HEIGHT <= 0 || head.position.y >= HEIGHT {
			log.debugf(
				"Old position = %v, new position = %v\n",
				head.position.y,
				HEIGHT - head.position.y - snake.SNAKE_HEIGHT,
			)
			head.position.y = HEIGHT - head.position.y - snake.SNAKE_HEIGHT
		}
		snake.move(&state.snake)

		for part in state.snake.body[1:] {
			if head.position == part.position {
				state.state = .Lost
				break
			}
		}

		if state.snake.body[0].position == state.food {
			snake.add_body(&state.snake)
			state.score += 1
			if state.score > state.highest_score do state.highest_score = state.score
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

	high_score_msg := fmt.ctprintf("HIGH SCORE: %d", state.highest_score)
	rl.DrawText(high_score_msg, WIDTH - 220, 40, 20, rl.WHITE)

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
