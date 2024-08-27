package main

import "core:log"
import "core:math/rand"
import "src:gamestate"
import rl "vendor:raylib"

main :: proc() {
	when !ODIN_DEBUG {
		rl.SetTraceLogLevel(.ERROR)
		context.logger = log.create_console_logger(.Error)
	} else {
		context.logger = log.create_console_logger()
	}
	defer log.destroy_console_logger(context.logger)

	rg := rand.create(1337)
	context.random_generator = rand.default_random_generator(&rg)


	rl.InitWindow(gamestate.WIDTH, gamestate.HEIGHT, "Snake Game");defer rl.CloseWindow()

	rl.SetTargetFPS(15)

	gs := gamestate.create()
	defer gamestate.destroy(&gs)


	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)
		rl.BeginDrawing();defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		gamestate.update(&gs)
		gamestate.draw(gs)
	}
}
