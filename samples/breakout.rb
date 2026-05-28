class Paddle
  attr_accessor :x, :y, :w, :h, :color, :speed

  def initialize
    @w = 100
    @h = 20
    @x = 400 - @w / 2
    @y = 550
    @speed = 7.0
    @color = Raylib::BLUE
  end

  def update
    if Raylib.is_key_down(Raylib::KEY_LEFT)
      @x -= @speed
    end
    if Raylib.is_key_down(Raylib::KEY_RIGHT)
      @x += @speed
    end

    @x = 0 if @x < 0
    @x = 800 - @w if @x > 800 - @w
  end

  def draw
    Raylib.draw_rectangle(@x.to_i, @y.to_i, @w.to_i, @h.to_i, @color)
  end
end

class Ball
  attr_accessor :x, :y, :r, :vx, :vy, :color

  def initialize
    @r = 10
    @x = 400
    @y = 300
    @vx = 4.0
    @vy = 4.0
    @color = Raylib::RAYWHITE
  end

  def update
    @x += @vx
    @y += @vy

    # 左右の壁
    if @x <= 0 || @x >= 800 - @r * 2
      @vx *= -1
      @x = @x <= 0 ? 0 : 800 - @r * 2
    end
    
    # 上の壁
    if @y <= 0
      @vy *= -1
      @y = 0
    end
  end

  def draw
    # 円の描画関数がないため、四角形で代用
    Raylib.draw_rectangle(@x.to_i, @y.to_i, (@r * 2).to_i, (@r * 2).to_i, @color)
  end
end

class Block
  attr_accessor :x, :y, :w, :h, :active, :color

  def initialize(x, y, w, h, color)
    @x = x
    @y = y
    @w = w
    @h = h
    @color = color
    @active = true
  end

  def draw
    if @active
      Raylib.draw_rectangle(@x.to_i, @y.to_i, @w.to_i, @h.to_i, @color)
      Raylib.draw_rectangle_lines(@x.to_i, @y.to_i, @w.to_i, @h.to_i, Raylib::BLACK)
    end
  end
end

# 矩形同士の当たり判定 (AABB)
def aabb_intersect?(x1, y1, w1, h1, x2, y2, w2, h2)
  x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
end

def main
  Raylib.init_window(800, 600, "Breakout - MRubySample")
  Raylib.set_target_fps(60)

  paddle = Paddle.new
  ball = Ball.new

  blocks = []
  colors = [Raylib::RED, Raylib::ORANGE, Raylib::YELLOW, Raylib::GREEN, Raylib::CYAN]
  rows = 5
  cols = 10
  bw = 70
  bh = 25
  padding = 8
  
  # ブロック群を画面中央に配置するためのオフセット計算
  offset_x = (800 - (cols * bw + (cols - 1) * padding)) / 2
  offset_y = 50

  rows.times do |row|
    cols.times do |col|
      bx = offset_x + col * (bw + padding)
      by = offset_y + row * (bh + padding)
      blocks << Block.new(bx, by, bw, bh, colors[row])
    end
  end

  state = :playing # 状態: :playing, :gameover, :clear

  while !Raylib.window_should_close()
    if state == :playing
      paddle.update
      ball.update

      # 画面下部へ落下（ゲームオーバー）
      if ball.y > 600
        state = :gameover
      end

      # パドルとの衝突判定
      if aabb_intersect?(ball.x, ball.y, ball.r * 2, ball.r * 2, paddle.x, paddle.y, paddle.w, paddle.h)
        ball.vy *= -1
        ball.y = paddle.y - ball.r * 2
        
        # 当たった位置に応じて反射角（vx）を変化させる
        center_p = paddle.x + paddle.w / 2
        center_b = ball.x + ball.r
        ball.vx = (center_b - center_p) * 0.15
      end

      # ブロックとの衝突判定
      blocks.each do |b|
        if b.active && aabb_intersect?(ball.x, ball.y, ball.r * 2, ball.r * 2, b.x, b.y, b.w, b.h)
          b.active = false
          
          # 当たった面を簡易的に判定して反射
          b_cx = b.x + b.w / 2
          b_cy = b.y + b.h / 2
          ball_cx = ball.x + ball.r
          ball_cy = ball.y + ball.r

          # 縦の重なりと横の重なりを比較して、どちらから当たったか判断
          if (ball_cx - b_cx).abs * b.h > (ball_cy - b_cy).abs * b.w
            ball.vx *= -1
          else
            ball.vy *= -1
          end
          
          break # 1フレームで複数のブロックに同時ヒットしないようにする
        end
      end

      # 全てのブロックが消えたかチェック
      if blocks.all? { |b| !b.active }
        state = :clear
      end
    else
      # リザルト画面でEnterキーを押すとリスタート
      if Raylib.is_key_pressed(Raylib::KEY_ENTER)
        paddle = Paddle.new
        ball = Ball.new
        blocks.each { |b| b.active = true }
        state = :playing
      end
    end

    # --- 描画処理 ---
    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::DARKGRAY)

    paddle.draw
    ball.draw
    blocks.each { |b| b.draw }

    if state == :gameover
      Raylib.draw_text("GAME OVER", 280, 250, 40, Raylib::RED)
      Raylib.draw_text("Press ENTER to Restart", 280, 310, 20, Raylib::LIGHTGRAY)
    elsif state == :clear
      Raylib.draw_text("GAME CLEAR!", 270, 250, 40, Raylib::YELLOW)
      Raylib.draw_text("Press ENTER to Restart", 280, 310, 20, Raylib::LIGHTGRAY)
    end

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
