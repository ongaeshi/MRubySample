def aabb_intersect?(x1, y1, w1, h1, x2, y2, w2, h2)
  x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
end

class Player
  attr_accessor :x, :y, :w, :h, :vy, :vx, :tex, :state

  def initialize(tex, start_x, start_y)
    @w = 30
    @h = 30
    @x = start_x
    @y = start_y
    @vx = 0.0
    @vy = 0.0
    @speed = 5.0
    @tex = tex
    @coyote_timer = 0
    @jump_buffer = 0
    @state = :playing
  end

  def update(blocks, objects)
    # 左右移動
    @vx = 0.0
    if Raylib.is_key_down(Raylib::KEY_LEFT)
      @vx -= @speed
    end
    if Raylib.is_key_down(Raylib::KEY_RIGHT)
      @vx += @speed
    end

    @x += @vx

    # ブロックとの横方向の衝突判定
    blocks.each do |block|
      if aabb_intersect?(@x, @y, @w, @h, block.x, block.y, block.w, block.h)
        if @vx > 0
          @x = block.x - @w
        elsif @vx < 0
          @x = block.x + block.w
        end
      end
    end

    # ジャンプ先行入力
    if Raylib.is_key_pressed(Raylib::KEY_SPACE) || Raylib.is_key_pressed(Raylib::KEY_UP)
      @jump_buffer = 8
    end

    if @jump_buffer > 0
      @jump_buffer -= 1
    end

    # ジャンプ実行
    if @jump_buffer > 0 && @coyote_timer > 0
      @vy = -12.0
      @coyote_timer = 0
      @jump_buffer = 0
    end

    # 重力
    @vy += 0.5
    @y += @vy

    if @coyote_timer > 0
      @coyote_timer -= 1
    end

    # ブロックとの縦方向の衝突判定
    blocks.each do |block|
      if aabb_intersect?(@x, @y, @w, @h, block.x, block.y, block.w, block.h)
        if @vy > 0 # 下に落ちているとき
          @y = block.y - @h
          @vy = 0.0
          @coyote_timer = 8
        elsif @vy < 0 # 上にジャンプしているとき（天井）
          @y = block.y + block.h
          @vy = 0.0
        end
      end
    end

    # 画面制限
    @x = 0 if @x < 0
    @x = 800 - @w if @x > 800 - @w
    
    if @y > 600
      @state = :gameover
    end

    # アイテム・敵との判定
    objects.each do |obj|
      next unless obj.active
      if aabb_intersect?(@x, @y, @w, @h, obj.x, obj.y, obj.w, obj.h)
        if obj.type == :item
          obj.active = false
          return 10 # score +10
        elsif obj.type == :obstacle
          @state = :gameover
        end
      end
    end
    
    return 0
  end

  def draw
    tex_w = @tex.width.to_f
    tex_h = @tex.height.to_f
    scale = [@w / tex_w, @h / tex_h].min
    draw_w = tex_w * scale
    draw_h = tex_h * scale
    draw_x = @x + (@w - draw_w) / 2
    draw_y = @y + (@h - draw_h) / 2
    @tex.draw_resized(draw_x.to_i, draw_y.to_i, draw_w.to_i, draw_h.to_i, Raylib::WHITE)
  end
end

class Block
  attr_accessor :x, :y, :w, :h
  def initialize(x, y, w, h)
    @x = x
    @y = y
    @w = w
    @h = h
  end

  def draw
    Raylib.draw_rectangle(@x.to_i, @y.to_i, @w.to_i, @h.to_i, Raylib::DARKGRAY)
    Raylib.draw_rectangle_lines(@x.to_i, @y.to_i, @w.to_i, @h.to_i, Raylib::BLACK)
  end
end

class GameObject
  attr_accessor :x, :y, :w, :h, :type, :tex, :active

  def initialize(type, tex, x, y, w, h)
    @type = type
    @active = true
    @tex = tex
    @w = w
    @h = h
    @x = x
    @y = y
  end

  def draw
    return unless @active
    tex_w = @tex.width.to_f
    tex_h = @tex.height.to_f
    scale = [@w / tex_w, @h / tex_h].min
    draw_w = tex_w * scale
    draw_h = tex_h * scale
    draw_x = @x + (@w - draw_w) / 2
    draw_y = @y + (@h - draw_h) / 2
    @tex.draw_resized(draw_x.to_i, draw_y.to_i, draw_w.to_i, draw_h.to_i, Raylib::WHITE)
  end
end

class LevelMap
  attr_reader :blocks, :objects, :start_x, :start_y

  def initialize(csv_path, food_tex, obstacle_tex)
    @blocks = []
    @objects = []
    @start_x = 100
    @start_y = 100
    tile_size = 50

    csv_data = Raylib.load_file_text(csv_path)
    
    if csv_data.nil? || csv_data == ""
      # デフォルトの床を生成
      @blocks << Block.new(0, 550, 800, 50)
      return
    end

    # CSVのパースと配置
    lines = csv_data.split("\n")
    lines.each_with_index do |line, y_idx|
      cols = line.split(",")
      cols.each_with_index do |col, x_idx|
        tile_id = col.to_i
        px = x_idx * tile_size
        py = y_idx * tile_size

        case tile_id
        when 1 # 地面ブロック
          @blocks << Block.new(px, py, tile_size, tile_size)
        when 2 # プレイヤースタート位置
          @start_x = px + (tile_size - 30) / 2
          @start_y = py + (tile_size - 30)
        when 3 # アイテム
          @objects << GameObject.new(:item, food_tex, px + 15, py + 15, 20, 20)
        when 4 # 障害物（敵）
          @objects << GameObject.new(:obstacle, obstacle_tex, px + 10, py + 20, 30, 30)
        end
      end
    end
  end
end

def main
  Raylib.init_window(800, 600, "Tiled Editor Map - MRubySample")
  Raylib.set_target_fps(60)

  player_tex = Raylib::Texture.new("samples/jump_action_tex/player.png")
  food_tex = Raylib::Texture.new("samples/jump_action_tex/food.png")
  obstacle_tex = Raylib::Texture.new("samples/jump_action_tex/obstacle.png")

  level = LevelMap.new("samples/jump_action_tex/map.csv", food_tex, obstacle_tex)
  player = Player.new(player_tex, level.start_x, level.start_y)
  score = 0
  
  while !Raylib.window_should_close()
    if player.state == :playing
      added_score = player.update(level.blocks, level.objects)
      score += added_score
    else
      if Raylib.is_key_pressed(Raylib::KEY_ENTER) || Raylib.is_key_pressed(Raylib::KEY_SPACE)
        # リトライ処理
        level = LevelMap.new("samples/jump_action_tex/map.csv", food_tex, obstacle_tex)
        player = Player.new(player_tex, level.start_x, level.start_y)
        score = 0
      end
    end

    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::RAYWHITE)

    level.blocks.each { |b| b.draw }
    
    if player.state == :playing
      player.draw
      level.objects.each { |o| o.draw }
      Raylib.draw_text("SCORE: #{score}", 10, 10, 20, Raylib::BLACK)
      Raylib.draw_text("Edit samples/jump_action_tex/map.csv to change the level!", 10, 35, 15, Raylib::DARKGRAY)
    elsif player.state == :gameover
      level.objects.each { |o| o.draw }
      Raylib.draw_text("GAME OVER", 280, 250, 40, Raylib::RED)
      Raylib.draw_text("SCORE: #{score}", 330, 310, 20, Raylib::DARKGRAY)
      Raylib.draw_text("Press ENTER or SPACE to Restart", 210, 350, 20, Raylib::DARKGRAY)
    end

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
