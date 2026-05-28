class Box
  attr_reader :x, :y, :w, :h, :color

  def initialize
    @x = 100.0
    @y = 100.0
    @w = 60.0
    @h = 60.0
    @vx = 5.0
    @vy = 4.0
    @colors = [
      Raylib::RED, Raylib::GREEN, Raylib::BLUE, 
      Raylib::ORANGE, Raylib::PURPLE, Raylib::CYAN
    ]
    @color = @colors[0]
  end

  def update
    @x += @vx
    @y += @vy

    hit = false

    if @x <= 0 || @x + @w >= 800
      @vx *= -1
      @x = @x <= 0 ? 0 : 800 - @w
      hit = true
    end

    if @y <= 0 || @y + @h >= 600
      @vy *= -1
      @y = @y <= 0 ? 0 : 600 - @h
      hit = true
    end

    if hit
      # ランダムに色を変更
      @color = @colors[rand(@colors.size)]
    end
  end
end

def main
  Raylib.init_window(800, 600, "Bouncing Box - MRubySample")
  Raylib.set_target_fps(60)

  box = Box.new

  while !Raylib.window_should_close()
    box.update

    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::BLACK)

    # 枠線も描画して少しオシャレに
    Raylib.draw_rectangle(box.x.to_i, box.y.to_i, box.w.to_i, box.h.to_i, box.color)
    Raylib.draw_rectangle_lines(box.x.to_i, box.y.to_i, box.w.to_i, box.h.to_i, Raylib::RAYWHITE)

    Raylib.draw_text("Bouncing Box in MRuby!", 10, 10, 20, Raylib::LIGHTGRAY)

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
