# PRJHOMEはsrcの上位ディレクトリ。 
PRJHOME = File.dirname('.')
# PRJHOME = File.dirname(__FILE__) + '/../../../'

# ロードパスにserverパッケージを追加
$: << PRJHOME + '/src/ruby/server'

require 'socket'
require 'json'
require 'heizu_board'
require 'player'
require 'config'
require 'logger'

slog = Logger.new(SERVER_LOG + "/server.log")
glog = Logger.new(GAME_LOG + "/game.log")

# メンテナンス性のため、メインスレッド以外が倒れた時でもスクリプト全体を停止する
Thread.abort_on_exception = true

mutex = Mutex.new

server_for_players = TCPServer.open(PLAYERS_SERVER_PORT)
slog.info{"Open server on port #{PLAYERS_SERVER_PORT}"}
server_for_audiences = TCPServer.open(AUDIENCES_SERVER_PORT)
slog.info{"Open server on port #{AUDIENCES_SERVER_PORT}"}


addr = server_for_players.addr
addr.shift
printf("server is on %s\n", addr.join(":"))

def create_player(sock)
  print(sock, " is accepted\n")
  sock.puts JSON.generate({"message" => "Send your team_name."})
  name = JSON.parse(sock.gets)["team_name"]
  puts name
  sock.puts JSON.generate({"your_team_name" => name})
  return Player.new(name, sock)
end

# 一斉に同一のメッセージを送信する
def notify(socks, message)
  socks.each {|sock| sock.puts message}
end

board = nil
player_socks = []
players = []
audience_socks = []
# 常時、観戦者を受け入れる
Thread.new {
  loop do
    Thread.new(server_for_audiences.accept){|s|
      mutex.synchronize {
        # audience_socksの保護
        audience_socks << s
      }
      s.puts "connected as audience."
    }
  end
}
# プレイヤー初期化
threads = []
2.times do
  player_socks << server_for_players.accept
  threads << Thread.start(player_socks.last) { |sock| players << create_player(sock)}
end
# 2人目以降のプレイヤーは拒否
Thread.new {
  loop do
    Thread.new(server_for_players.accept) {|s| s.close }
  end
}

# プレイヤー初期化待ち
threads.each {|t| t.join()}

puts "init done."

# 盤面の作成
puts board = HeizuBoard.new(players[0],players[1])

# 対戦開始
loop do
  mutex.synchronize{
    # xxx_socksの保護
    notify(player_socks, JSON.generate(board.to_hash))
    notify(audience_socks, "#{board.count()} turn")
    notify(audience_socks, board.to_s)
  }
  break if board.finished

  puts action = JSON.parse(board.next_player().sock.gets)
  puts result = JSON.generate(board.turn(action))
  board.last_player().sock.puts(result)
end

# 通信を閉じる
notify(audience_socks, "finished")
player_socks.concat(audience_socks).each {|s| s.close}

#audiences_thread = Thread.new {
#  # 観戦用スレッド
#  Thread.start(server_for_audiences.accept) do |sock|   # save to dynamic variable
#    print(sock, " is accepted\n")
#
#    sock.puts JSON.generate({"message" => "You are audience."})
#    sleep(0.1) while board == nil
#    sock.puts JSON.generate(board.to_hash)
#
#    print(sock, " is gone\n")
#    sock.close
#  end
#}

#dealer_thread.join
#players_thread.join
#audiences_thread.join
