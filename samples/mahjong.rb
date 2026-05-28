class Tile
  attr_reader :suit, :val

  def initialize(suit, val)
    @suit = suit
    @val = val
  end

  def to_s
    "#{@suit}#{@val}"
  end

  def display_name
    case @suit
    when :z
      ["E", "S", "W", "N", "Wht", "Grn", "Red"][@val - 1]
    else
      "#{@suit.to_s.upcase}#{@val}"
    end
  end

  def sort_key
    suit_order = {m: 1, p: 2, s: 3, z: 4}
    suit_order[@suit] * 10 + @val
  end

  def color
    case @suit
    when :m then Raylib::RED
    when :p then Raylib::BLUE
    when :s then Raylib::GREEN
    when :z then Raylib::PURPLE
    end
  end

  def draw(x, y, selected = false)
    w = 40
    h = 60
    
    bg_color = selected ? Raylib::YELLOW : Raylib::RAYWHITE
    # 選択中は少し上に浮かせる
    y_offset = selected ? -10 : 0

    Raylib.draw_rectangle(x, y + y_offset, w, h, bg_color)
    Raylib.draw_rectangle_lines(x, y + y_offset, w, h, Raylib::BLACK)
    
    text = display_name
    offset_x = (w - (text.length * 10)) / 2
    offset_x = 5 if offset_x < 0
    
    tc = color == Raylib::GREEN ? Raylib::BLACK : color
    Raylib.draw_text(text, x + offset_x, y + y_offset + 20, 20, tc)
  end
end

class Wall
  def initialize
    @tiles = []
    [:m, :p, :s].each do |suit|
      (1..9).each do |val|
        4.times { @tiles << Tile.new(suit, val) }
      end
    end
    (1..7).each do |val|
      4.times { @tiles << Tile.new(:z, val) }
    end
    
    # シャッフル
    n = @tiles.length
    (0...n).each do |i|
      j = rand(n)
      tmp = @tiles[i]
      @tiles[i] = @tiles[j]
      @tiles[j] = tmp
    end
  end

  def pop
    @tiles.pop
  end
  
  def empty?
    @tiles.empty?
  end
  
  def tiles_left
    @tiles.length
  end
end

def sort_hand(hand)
  n = hand.length
  (0...n).each do |i|
    (0...(n - i - 1)).each do |j|
      if hand[j].sort_key > hand[j+1].sort_key
        tmp = hand[j]
        hand[j] = hand[j+1]
        hand[j+1] = tmp
      end
    end
  end
end

def check_mentsu(counts, mentsu_needed)
  return true if mentsu_needed == 0
  
  first_tile = nil
  counts.keys.sort.each do |t|
    if counts[t] > 0
      first_tile = t
      break
    end
  end
  return false unless first_tile
  
  suit = first_tile[0]
  val = first_tile[1].to_i
  
  # 刻子のチェック
  if counts[first_tile] >= 3
    c = {}
    counts.each { |k, v| c[k] = v }
    c[first_tile] -= 3
    return true if check_mentsu(c, mentsu_needed - 1)
  end
  
  # 順子のチェック
  if suit != 'z' && val <= 7
    t2 = "#{suit}#{val+1}"
    t3 = "#{suit}#{val+2}"
    if counts[first_tile] >= 1 && (counts[t2] || 0) >= 1 && (counts[t3] || 0) >= 1
      c = {}
      counts.each { |k, v| c[k] = v }
      c[first_tile] -= 1
      c[t2] -= 1
      c[t3] -= 1
      return true if check_mentsu(c, mentsu_needed - 1)
    end
  end
  
  false
end

def check_agari(tiles_str)
  counts = {}
  tiles_str.each do |t| 
    counts[t] ||= 0
    counts[t] += 1 
  end
  
  # 七対子
  pairs = 0
  counts.values.each { |v| pairs += 1 if v == 2 }
  return true if pairs == 7
  
  # 国士無双
  kokushi = ["m1", "m9", "p1", "p9", "s1", "s9", "z1", "z2", "z3", "z4", "z5", "z6", "z7"]
  has_all = true
  has_pair = false
  kokushi.each do |t|
    val = counts[t] || 0
    has_all = false if val < 1
    has_pair = true if val >= 2
  end
  return true if has_all && has_pair

  # 通常の4面子1雀頭
  unique_tiles = counts.keys.sort
  unique_tiles.each do |pair_tile|
    if counts[pair_tile] >= 2
      c = {}
      counts.each { |k, v| c[k] = v }
      c[pair_tile] -= 2
      if check_mentsu(c, 4)
        return true
      end
    end
  end
  false
end

def display_name_for_str(t)
  suit = t[0]
  val = t[1].to_i
  case suit
  when 'm' then "M#{val}"
  when 'p' then "P#{val}"
  when 's' then "S#{val}"
  when 'z' then ["E", "S", "W", "N", "Wht", "Grn", "Red"][val - 1]
  end
end

def check_tenpai(tiles_13)
  all_tiles = []
  [:m, :p, :s].each do |suit|
    (1..9).each { |v| all_tiles << "#{suit}#{v}" }
  end
  (1..7).each { |v| all_tiles << "z#{v}" }
  
  waits = []
  all_tiles.each do |t|
    test_hand = []
    tiles_13.each { |th| test_hand << th.to_s }
    test_hand << t
    waits << display_name_for_str(t) if check_agari(test_hand)
  end
  waits
end

def main
  Raylib.init_window(800, 600, "Mahjong Solo - MRubySample")
  Raylib.set_target_fps(60)

  state = :title
  wall = nil
  hand = []
  drawn_tile = nil
  cursor = 0
  message = ""
  waits = []

  while !Raylib.window_should_close()
    if state == :title
      if Raylib.is_key_pressed(Raylib::KEY_SPACE)
        wall = Wall.new
        hand = []
        13.times { hand << wall.pop }
        sort_hand(hand)
        drawn_tile = wall.pop
        cursor = 13
        waits = []
        
        test_hand = []
        hand.each { |t| test_hand << t.to_s }
        test_hand << drawn_tile.to_s
        if check_agari(test_hand)
          state = :agari
          message = "Tenho! (Heavenly Hand)"
        else
          state = :playing
        end
      end
    elsif state == :playing
      if Raylib.is_key_pressed(Raylib::KEY_LEFT)
        cursor -= 1
        cursor = 0 if cursor < 0
      elsif Raylib.is_key_pressed(Raylib::KEY_RIGHT)
        cursor += 1
        cursor = 13 if cursor > 13
      elsif Raylib.is_key_pressed(Raylib::KEY_SPACE) || Raylib.is_key_pressed(Raylib::KEY_ENTER)
        if cursor != 13
          hand.delete_at(cursor)
          hand << drawn_tile
          sort_hand(hand)
        end
        
        waits = check_tenpai(hand)

        if wall.empty?
          state = :ryukyoku
          message = "Draw (Ryukyoku)"
          drawn_tile = nil
        else
          drawn_tile = wall.pop
          cursor = 13
          test_hand = []
          hand.each { |t| test_hand << t.to_s }
          test_hand << drawn_tile.to_s
          if check_agari(test_hand)
            state = :agari
            message = "Tsumo! Agari!"
          end
        end
      end
    elsif state == :agari || state == :ryukyoku
      if Raylib.is_key_pressed(Raylib::KEY_ENTER) || Raylib.is_key_pressed(Raylib::KEY_SPACE)
        state = :title
      end
    end

    # --- 描画処理 ---
    Raylib.begin_drawing()
    Raylib.clear_background(Raylib::DARKGRAY)

    if state == :title
      Raylib.draw_text("Mahjong Solo", 250, 200, 50, Raylib::RAYWHITE)
      Raylib.draw_text("Press SPACE to Start", 280, 300, 25, Raylib::LIGHTGRAY)
    else
      Raylib.draw_text("Tiles left: #{wall ? wall.tiles_left : 0}", 600, 20, 20, Raylib::RAYWHITE)
      
      if state == :agari
        Raylib.draw_text("AGARI!", 350, 150, 40, Raylib::YELLOW)
        Raylib.draw_text(message, 300, 200, 30, Raylib::RAYWHITE)
      elsif state == :ryukyoku
        Raylib.draw_text("RYUKYOKU (DRAW)", 250, 150, 40, Raylib::LIGHTGRAY)
      elsif waits.any?
        Raylib.draw_text("TENPAI! Waits: #{waits.join(', ')}", 50, 100, 20, Raylib::YELLOW)
      end

      # 手牌の描画
      start_x = 70
      start_y = 400
      
      hand.each_with_index do |tile, i|
        tile.draw(start_x + i * 42, start_y, i == cursor)
      end

      # ツモ牌の描画
      if drawn_tile
        drawn_tile.draw(start_x + 13 * 42 + 20, start_y, 13 == cursor)
      end

      if state == :playing
        Raylib.draw_text("LEFT/RIGHT to select, SPACE to discard", 180, 500, 20, Raylib::RAYWHITE)
      elsif state == :agari || state == :ryukyoku
        Raylib.draw_text("Press ENTER to return to Title", 220, 500, 25, Raylib::RAYWHITE)
      end
    end

    Raylib.end_drawing()
  end
  Raylib.close_window()
end

main()
