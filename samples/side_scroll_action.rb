def aabb_intersect?(x1, y1, w1, h1, x2, y2, w2, h2)
  x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
end

class Player
  attr_accessor :x, :y, :w, :h, :vy, :vx, :tex

  def initialize(tex)
    @w = 30
    @h = 30
    @x = 100
    @y = 300
    @vx = 0.0
    @vy = 0.0
    @speed = 5.0
    @tex = tex
    @coyote_timer = 0
    @jump_buffer = 0
  end

  def update(blocks)
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

    # ジャンプ先行入力 (Jump Buffer)
    if Raylib.is_key_pressed(Raylib::KEY_SPACE) || Raylib.is_key_pressed(Raylib::KEY_UP)
      @jump_buffer = 8
    end

    if @jump_buffer > 0
      @jump_buffer -= 1
    end

    # ジャンプ実行 (コヨーテタイム対応)
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
    on_ground = false
    blocks.each do |block|
      if aabb_intersect?(@x, @y, @w, @h, block.x, block.y, block.w, block.h)
        if @vy > 0 # 下に落ちているとき
          @y = block.y - @h
          @vy = 0.0
          @coyote_timer = 8 # 接地中は常にコヨーテタイムを最大値に保つ
          on_ground = true
        elsif @vy < 0 # 上にジャンプしているとき（天井にぶつかる等）
          @y = block.y + block.h
          @vy = 0.0
        end
      end
    end
  end

  def draw(camera_x)
    tex_w = @tex.width.to_f
    tex_h = @tex.height.to_f
    scale = [@w / tex_w, @h / tex_h].min
    draw_w = tex_w * scale
    draw_h = tex_h * scale
    draw_x = (@x - camera_x) + (@w - draw_w) / 2
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

  def draw(camera_x)
    Raylib.draw_rectangle((@x - camera_x).to_i, @y.to_i, @w.to_i, @h.to_i, Raylib::DARKGRAY)
    Raylib.draw_rectangle_lines((@x - camera_x).to_i, @y.to_i, @w.to_i, @h.to_i, Raylib::BLACK)
  end
end

class GameObject
  attr_accessor :x, :y, :w, :h, :type, :tex, :active, :vy, :on_ground

  def initialize(type, tex, x, y)
    @type = type
    @active = true
    @tex = tex
    @on_ground = false
    @vy = 0.0
    if type == :item
      @w = 20
      @h = 20
      @x = x
      @y = y - @h - 5 # 床から少し浮かせる
    else # :obstacle
      @w = 30
      @h = 30
      @x = x
      @y = -50 - rand(200) # 画面上部からランダムな高さで配置
      @vy = 1.0 + rand * 5.0 # 初期落下速度
    end
  end

  def update(blocks, camera_x)
    return unless @active
    
    if @type == :obstacle && !@on_ground
      # プレイヤーが近づいて画面内（右端）に入るまで落下を開始しない
      if @x < camera_x + 850
        @vy += 0.01 # 重力
        @y += @vy

        # 地面との当たり判定
        blocks.each do |block|
          if aabb_intersect?(@x, @y, @w, @h, block.x, block.y, block.w, block.h)
            if @vy > 0
              @y = block.y - @h
              @vy = 0.0
              @on_ground = true
              break
            end
          end
        end

        # 画面下へ落ちたら無効化
        if @y > 600
          @active = false
        end
      end
    end
  end

  def draw(camera_x)
    return unless @active
    tex_w = @tex.width.to_f
    tex_h = @tex.height.to_f
    scale = [@w / tex_w, @h / tex_h].min
    draw_w = tex_w * scale
    draw_h = tex_h * scale
    draw_x = (@x - camera_x) + (@w - draw_w) / 2
    draw_y = @y + (@h - draw_h) / 2

    @tex.draw_resized(draw_x.to_i, draw_y.to_i, draw_w.to_i, draw_h.to_i, Raylib::WHITE)
  end
end

class MapGenerator
  attr_accessor :blocks, :objects, :next_x

  def initialize
    @blocks = []
    @objects = []
    @next_x = 0
    @floor_y = 500
    
    # 最初の足場（絶対に落ちないように長めに）
    generate_block(1000)
  end

  def generate_block(width)
    @blocks << Block.new(@next_x, @floor_y, width, 600 - @floor_y)
    @next_x += width
  end

  def update(camera_x, food_tex, obstacle_tex)
    # カメラの右端より少し先までマップを生成
    while @next_x < camera_x + 1200
      # 穴をあける
      if rand(100) < 30
        hole_width = 80 + rand(120)
        @next_x += hole_width
      end

      # 次の床の高さをランダムに変化させる（上に最大100、下に最大100）
      height_change = rand(200) - 100
      @floor_y += height_change
      
      # 高さが極端になりすぎないように制限
      if @floor_y < 350
        @floor_y = 350
      elsif @floor_y > 550
        @floor_y = 550
      end

      # 新しい足場
      block_width = 200 + rand(400)
      
      # 足場の上にアイテムや障害物を配置
      obj_x = @next_x + 50
      while obj_x < @next_x + block_width - 50
        if rand(100) < 40
          @objects << GameObject.new(:item, food_tex, obj_x, @floor_y)
        elsif rand(100) < 30
          @objects << GameObject.new(:obstacle, obstacle_tex, obj_x, @floor_y)
        end
        obj_x += 100
      end

      generate_block(block_width)
    end

    # 後ろに過ぎ去ったオブジェクトを削除（メモリ解放）
    new_blocks = []
    @blocks.each { |b| new_blocks << b if b.x + b.w >= camera_x - 400 }
    @blocks = new_blocks

    new_objects = []
    @objects.each { |o| new_objects << o if o.x + o.w >= camera_x - 400 && o.active }
    @objects = new_objects
  end
end

def main
  Raylib.init_window(800, 600, "Side-Scrolling Action - MRubySample")
  Raylib.set_target_fps(60)

  player_tex = Raylib::Texture.new("samples/jump_action_tex/player.png")
  food_tex = Raylib::Texture.new("samples/jump_action_tex/food.png")
  obstacle_tex = Raylib::Texture.new("samples/jump_action_tex/obstacle.png")

  player = Player.new(player_tex)
  map_gen = MapGenerator.new
  score = 0
  state = :playing

  camera_x = 0.0

  while !Raylib.window_should_close()
    if state == :playing
      player.update(map_gen.blocks)
      
      # カメラ位置の更新。プレイヤーが画面の左1/3 (約266px) より右に行ったらカメラを動かす
      target_camera_x = player.x - 266
      if target_camera_x > camera_x
        camera_x = target_camera_x
      end

      # 画面左端から出られないように制限（カメラがスクロールした分）
      if player.x < camera_x
        player.x = camera_x
      end

      map_gen.update(camera_x, food_tex, obstacle_tex)

      # オブジェクトの更新（落下処理など）
      map_gen.objects.each do |obj|
        obj.update(map_gen.blocks, camera_x)
      end
      
      # 落下死判定
      if player.y > 600
        state = :gameover
      end

      # 当たり判定
      map_gen.objects.each do |obj|
        next unless obj.active
        if aabb_intersect?(player.x, player.y, player.w, player.h, obj.x, obj.y, obj.w, obj.h)
          if obj.type == :item
            score += 10
            obj.active = false
          elsif obj.type == :obstacle
            state = :gameover
          end
        end
      end

    else
      # ゲームオーバー時のリトライ
      if Raylib.is_key_pressed(Raylib::KEY_ENTER) || Raylib.is_key_pressed(Raylib::KEY_SPACE)
        player = Player.new(player_tex)
        map_gen = MapGenerator.new
        score = 0
        camera_x = 0.0
        state = :playing
      end
    end

    # --- 描画処理 ---
    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::RAYWHITE)

    map_gen.blocks.each { |b| b.draw(camera_x) }
    
    if state == :playing
      player.draw(camera_x)
      map_gen.objects.each { |o| o.draw(camera_x) }
      Raylib.draw_text("SCORE: #{score}  DISTANCE: #{camera_x.to_i / 10}m", 10, 10, 20, Raylib::BLACK)
    elsif state == :gameover
      Raylib.draw_text("GAME OVER", 280, 250, 40, Raylib::RED)
      Raylib.draw_text("SCORE: #{score}  DISTANCE: #{camera_x.to_i / 10}m", 250, 310, 20, Raylib::DARKGRAY)
      Raylib.draw_text("Press ENTER or SPACE to Restart", 210, 350, 20, Raylib::DARKGRAY)
    end

    Raylib.end_drawing()
  end

  Raylib.close_window()
end

main()
