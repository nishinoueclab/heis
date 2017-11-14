require 'Unit'
require 'json'

class HeizuBoard
  def initialize(player1, player2)
    @width, @height = 20, 20
    @next_player = player1
    @player1 = player1
    @player2 = player2
    @count = 0
    @finished = false
    @board = Array.new(@width).map{Array.new(@height){nil}}
    index = 0
    (0..5).each do |i|
      (0..5).each do |j|
        @board[14 + i][j] = Unit.new(index.to_s, player1)
        @board[i][14 + j] = Unit.new(index.to_s, player2)
        index += 1
      end
    end

  end

  attr_reader :count, :finished
  
  def turn(action)
    @count += 1
    
    
    @next_player = @next_player == @player1 ? @player2 : @player1
    if @count > 10
      @finished = true
      
    end
    return {"result" => "ok"}
  end
  
  def get_unit(unit_id)
    
  end

  def next_player
    @next_player
  end
  
  def last_player
    @next_player == @player1 ? @player2 : @player1
  end

  def to_hash
    hash = {}
    hash["width"] = @width
    hash["height"] = @height
    hash["turn_team"] = next_player.name
    hash["count"] = @count
    hash["finished"] = @finished
    hash["units"] = []
    (0...@height).each do |i|
      (0...@width).each do |j|
        if @board[i][j] then
          unit_hash = @board[i][j].to_hash()
          unit_hash["locate"] = {"x" => j, "y" => i}
          hash["units"] << unit_hash
        end
      end
    end

    return hash
  end

  def to_s
    str = ""
    (0...@height).each do |i|
      (0...@width).each do |j|
        str += @board[i][j] == nil ? "----" : @board[i][j].to_s
        str += " "
      end
      str += "\n"
    end
    return str
  end

end