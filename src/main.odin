package main

import "core:math/rand"
import "src:gamestate"
import "src:snake"
import rl "vendor:raylib"

main :: proc() {
	rg := rand.create(1337)
	context.random_generator = rand.default_random_generator(&rg)


	rl.InitWindow(gamestate.WIDTH, gamestate.HEIGHT, "Snake Game");defer rl.CloseWindow()

	rl.SetTargetFPS(10)


	gs := gamestate.create(
		snake.create(
			{
				0 = (gamestate.WIDTH / 2) - snake.SNAKE_WIDTH,
				1 = (gamestate.HEIGHT / 2) - snake.SNAKE_HEIGHT,
			},
			length = 4,
		),
	)
	defer gamestate.destroy(&gs)


	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)
		rl.BeginDrawing();defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		gamestate.update(&gs)
		gamestate.draw(gs)
	}
}
