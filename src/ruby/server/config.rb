# 競技者向けに開くポート.
PLAYERS_SERVER_PORT     = 20000

# 観戦者向けに開くポート.
AUDIENCES_SERVER_PORT   = 20001

# テスト用クライアントの立ち上げ. プレイヤー名配列.
# サーバを起動後自動的にテスト用クライアントを起動する。
TEST_PLAYER             = []
# TEST_PLAYER           = ['foo', 'goo']

# 最大ターン数
MAX_TURN                = 50
# MAX_TURN              = nil

# 対戦ログを保存するディレクトリを指定
GAME_LOG                = File.dirname('.') + '/log'
# GAME_LOG                = File.dirname(__FILE__) + '/../../log'

# サーバプログラムログを保存するディレクトリを指定
SERVER_LOG              = File.dirname('.') + '/log'
# SERVER_LOG                = File.dirname(__FILE__) + '/../../log'