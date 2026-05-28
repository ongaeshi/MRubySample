class Player
  attr_reader :x, :y

  def initialize
    @x = 400.0
    @y = 300.0
    @speed = 5.0
  end

  def update
    @y -= @speed if Raylib.is_key_down(Raylib::KEY_UP)
    @y += @speed if Raylib.is_key_down(Raylib::KEY_DOWN)
    @x -= @speed if Raylib.is_key_down(Raylib::KEY_LEFT)
    @x += @speed if Raylib.is_key_down(Raylib::KEY_RIGHT)
  end
end

def main
  Raylib.init_window(800, 600, "MRubyCS + Raylib-cs Engine")
  Raylib.set_target_fps(60)

  player = Player.new

  while !Raylib.window_should_close()
    player.update

    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::RAYWHITE)

    Raylib.draw_rectangle(player.x.to_i, player.y.to_i, 50, 50, Raylib::BLUE)
    Raylib.draw_text("Move with Arrow Keys. Main loop in Ruby!", 10, 10, 20, Raylib::DARKGRAY)

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
