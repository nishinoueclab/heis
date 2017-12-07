require 'socket'

address = ARGV[0].nil? ? 'localhost' : ARGS[0]
port = ARGV[1].nil? ? 20001 : ARGS[1].to_s

# サーバ接続 OPEN
sock = TCPSocket.open(address, port)

loop do
  print board = sock.gets
  break if board == "finished\n"
end

# ソケット CLOSE
sock.close

