require 'unit'
require 'json'
require 'player'

class HeizuBoard
  def initialize(player1, player2, max_turn = nil)
    @width, @height = 20, 20
    @next_player = player1
    @player1 = player1
    @player2 = player2
    @count = 0
    @max_turn = max_turn
    @finished = false
    @board = Array.new(@height).map{Array.new(@width){nil}}
    index = 0
    (0..5).each do |j|
      (0..5).each do |i|
        @board[j][14 + i] = Unit.new(self, index.to_s, player1)
        @board[14 + j][i] = Unit.new(self, index.to_s, player2)
        index += 1
      end
    end

  end

  # hashを入れると
  def set_values(board_hash)
    @width, @height = board_hash[:width], board_hash[:height]
    @player1 = Player.new(board_hash[:players][0][:team_name])
    @player2 = Player.new(board_hash[:players][1][:team_name])
    @next_player = board_hash[:turn_team] == @player1.name ? @player1 : @player2
    @count = board_hash[:count]
    @max_turn = nil
    @finished = board_hash[:finished]
    @board = Array.new(@height){Array.new(@width){nil}}
    board_hash[:units].each {|unit|
      @board[unit[:locate][:y]][unit[:locate][:x]] = Unit.new(self, unit[:unit_id][2..4].to_i, unit[:team] == @player1.name ? @player1 : @player2, unit[:hp])
        
    }
    return self
  end

  attr_reader :count, :finished, :width, :height

  # action jsonを受け取って実行を行います。
  #
  #
  def turn(action)
    @count += 1
    contents = action[:contents]
    unit_ids = [] # 重複チェック
    results = contents.map { |c|

      unit_id = c[:unit_id]
      next {:unit_id => unit_id, :error => "Duplicate unit_id : #{unit_id}"} if(unit_ids.include?(unit_id))
      unit_ids << unit_id
        
      if to = c[:to]
        next {:unit_id => unit_id, :error => "Can't move this unit : #{unit_id}"} if(!move_unit(unit_id, to))
      end

      if atk = c[:atk]
        next {:unit_id => unit_id, :error => "Can't attack other unit: #{get_unit_by_locate(atk)}"} if(!atk(unit_id, atk))
      end
      
      next nil
    }.select{|r| !r.nil?}

    @next_player = @next_player == @player1 ? @player2 : @player1

    @finished = (@count > @max_turn) if @max_turn
    @finished = true if @board.flatten(1).select{|u| !u.nil? }.select{|u| u.alive? }.group_by{|u| u.player.name}.size == 1

    return {:result => results}
  end
  
  def units
    @board.flatten(1).select{|u| !u.nil? }.select{|u| u.alive? }
  end

  # あるユニットを動かす
  # @arg unit_id  unit_id as string
  # @arg to {:x => xxx, :y => yyy} as hash
  # @return 移動可能なら移動を行いtrue. 移動不可ならfalse.
  def move_unit(unit_id, to)
    unit = get_unit(unit_id)
    last_locate = locate(unit)
    if(unit.move_to?(to))
      @board[last_locate[:y]][last_locate[:x]] = nil
      @board[to[:y]][to[:x]] = unit
      return true
    else
      return false
    end
  end

  # targetマスへの攻撃を行う
  # target == {:x => xxx, :y => yyy}
  # @return 攻撃可能なら攻撃を行いtrue. 攻撃不可ならfalse.
  def atk(unit_id, target)
    unit = get_unit(unit_id)
    tunit = get_unit_by_locate(target)
    return false if(unit.nil?)
    return false if(tunit.nil?)
    if(unit.atkable?(tunit))
      unit.atk(tunit)
      return true
    else
      return false
    end
  end

  def get_unit(unit_id)
    @board.flatten(1).select{|u| u != nil && u.unit_id == unit_id}[0]
  end

  def get_unit_by_locate(locate)
    return nil if  !(0 <=locate[:x] && locate[:x] < @width && 0 <= locate[:y] && locate[:y] < @height)
    @board[locate[:y]][locate[:x]]
  end

  # ユニットを強制的に削除する
  def remove_unit(unit)
    l = locate(unit)
    @board[l[:y]][l[:x]] = nil
  end

  # ユニットの場所を返却する
  def locate(unit)
    if(index = @board.flatten(1).index(unit))
      {:x => index % @width, :y => (index - index % @width) / @height}
    end
  end

  def next_player
    @next_player
  end

  def last_player
    @next_player == @player1 ? @player2 : @player1
  end

  def to_hash
    hash = {}
    hash[:width] = @width
    hash[:height] = @height
    hash[:turn_team] = next_player.name
    hash[:count] = @count
    hash[:finished] = @finished
    hash[:players] = [{:team_name => @player1.name}, {:team_name => @player2.name}]
    hash[:units] = @board.flatten(1).select{|u| !u.nil? }.select{|u| u.alive? }.map{|unit| unit.to_hash}
    return hash
  end

  def to_s
    @board.map {|row| row.map {|unit| unit.nil? ? "----" : unit.to_s }.join(" ")}.join("\n")
  end

end