# PRJHOMEはsrcの上位ディレクトリ。
PRJHOME = File.dirname('.')
# PRJHOME = File.dirname(__FILE__) + '/../../../'

# ロードパスにserverパッケージを追加
$: << PRJHOME + '/src/ruby/server'

require 'socket'
require 'json'
require 'heis_board'
require 'player'
require 'config'
require 'player_client_stab'
require 'logger'
require 'json-schema'

def getxy(message = "")
  loop do
    print "#{message}x, y > "
    xys = gets.chomp.gsub(" ", "")
    return nil if xys.upcase == "EXIT"
    if xys.match /(\d+),(\d+)/
      return {:x => $1.to_i, :y => $2.to_i}
    end
  end
end

def gets_name
  loop do
    print "your team name > "
    name = gets.chomp
    return nil if name == "EXIT"
    return name if name.size >= 2
  end
end

def gets_unit_id
  loop do
    print "select your unit > "
    name = gets.chomp
    return nil if name == "EXIT"
    return name if name.size == 4
  end
end

def getyn(message = "")
  loop do
    print "#{message}y/n > "
    yn = gets.chomp.upcase
    return nil if yn == "EXIT"
    return yn == "Y" if yn.match /Y|N/
  end
end

# サーバ接続 OPEN
sock = TCPSocket.open("localhost", 20000)

#チーム名要求
puts sock.gets

team_name = gets_name

sock.puts JSON.generate({:team_name => team_name})
sock.gets

puts "Welcome #{team_name}!"

loop do
  board_hash = JSON.parse(sock.gets, {:symbolize_names => true})
  board = HeisBoard.new(nil,nil,nil).set_values(board_hash);
  puts "Turn Count = #{board.count}\n", board.to_s, ""
  break if(board.finished)

  # 自分のターンのとき
  if(board.next_player.name == team_name)
    send_hash = {:turn_team => team_name, :contents => []}
    puts "Your turn!"

    while(getyn("Do you play some actions? ")) do

      content = {}
      # 行動するユニットを選ばせる
      unit = nil
      loop do
        unit_id = gets_unit_id
        break if unit_id.nil?
        break if unit = board.get_unit(unit_id)
      end
      if(unit.nil?)
        puts "This action is canceled."
        next
      end
      puts "Your select unit at #{unit.locate}, and the hp is #{unit.hp}."
      content[:unit_id] = unit.unit_id

      # 移動先を指定する
      move_to = nil
      loop do
        move_to = getxy(message = "move to ")
        break if move_to.nil?
        break if unit.move_to?(move_to)
      end
      if(move_to.nil?)
        puts "This action is canceled."
        next
      end
      board.move_unit(unit.unit_id, move_to)
      puts board.to_s, ""
      puts "The unit move to #{unit.locate}, and the hp is #{unit.hp}."
      content[:to] = move_to
      send_hash[:contents] << content

      # 攻撃先を指定する
      if getyn("Dose the unit attack? ")
        atk_to = nil
        loop do
          atk_to = getxy(message = "attack to ")
          break if atk_to.nil?
          next if board.get_unit_by_locate(atk_to).nil?
          break if unit.atkable?(get_unit_by_locate(atk_to))
        end
        if(atk_to.nil?)
          puts "Only attack action is canceled."
          next
        end
        board.atk_unit(unit.unit_id, atk_to)
        puts board.to_s, ""
        puts "Successful attack!"
        content[:atk] = atk_to
      end

    end

    # 実際には行動JSONを送る
    sock.puts JSON.generate(send_hash)
    sock.flush

    # 結果を取得
    result = JSON.parse(sock.gets, {:symbolize_names => true})
    puts "You have some errors.", result if result[:result].size > 0
  end
end

# ソケット CLOSE
sock.close

puts "See you ~~~"