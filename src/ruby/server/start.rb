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
require 'player_client_stab'
require 'logger'
require 'json-schema'

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
invite = Thread.new {
  2.times do
    player_socks << server_for_players.accept
    threads << Thread.start(player_socks.last) { |sock| players << create_player(sock)}
  end
}

# クライアントスタブの起動
TEST_PLAYER.each {|name|
  puts name
  PlayerClientStab.new(name, 'localhost', PLAYERS_SERVER_PORT).run
}

invite.join

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
puts board = HeizuBoard.new(players[0], players[1], MAX_TURN)

# 対戦開始
loop do
  mutex.synchronize{
    # xxx_socksの保護
    notify(player_socks, JSON.generate(board.to_hash))
    notify(audience_socks, "#{board.count()} turn")
    notify(audience_socks, board.to_s)
  }
  break if board.finished

  action_str = board.next_player().sock.gets
  slog.info "recive " + action_str
  # JSONの整合性チェック
  action_schema = File.open(File.dirname(__FILE__) + "/action-schema.json").read
  action_err = JSON::Validator.fully_validate(action_schema, action_str, :strict => false)
  if(action_err.size > 0)
    # 不正なJSONの場合は何もぜず、ターンを終了する。
    board.turn({:turn_team => board.next_player().name, :contents => []})
    board.last_player().sock.puts(JSON.generate({:result => [{:error => action_err.to_s}]}))
  else
    action = JSON.parse(action_str, {:symbolize_names => true})
    result = JSON.generate(board.turn(action))
    slog.info "send " + result
    board.last_player().sock.puts(result)
  end

end

# 通信を閉じる
notify(audience_socks, "finished")
player_socks.concat(audience_socks).each {|s| s.close}
