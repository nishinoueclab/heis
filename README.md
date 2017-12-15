# README #

This project for programming semi at UEC nishino lab.
Heis server in this repository.

# Before You Start
Please make sure Ruby is installed.
You can check with the following.
```
$ ruby -v
```

# Getting Repository
```
$ git clone https://github.com/nishinoueclab/heis.git
```

# Ready for Starting Heis Server
Install the ruby library "json-schema".
```
$ sudo gem install --remote json-schema
```

Prease make the directory "log" for saving some log files. 
```
$ cd heis_server
$ mkdir log
```


# Starting Heis Server
```
$ ruby src/ruby/server/start.rb
```
CAUTION: If you run server using the following, the server can't work well.
```
$ cd src/ruby/server/
$ ruby start.rb
```
## Testing Server
```
$ ruby src/ruby/client/player_client_test.rb
```

# Stating Simple Player CUI
You should run server before stating Player CUI.
You can start Player CUI with the following.
```
$ ruby src/ruby/client/player_client_cui.rb
{"message":"Send your team_name."}
your team name > yaa
Welcome yaa!
```
 

# Starting Sample Heis Player Client
```
$ ruby src/ruby/server/player_client.rb
```

# Starting Sample Heis Audience Client
You can connect server as an audience on localhost port 20000 that is default.
```
$ ruby src/ruby/server/audience_client.rb
```
You can connect with any IP address and port.
```
$ ruby src/ruby/server/audience_client.rb 192.168.xx.xx 20000
```


# Update Repository
```
$ cd heis_server
$ git pull
```

# Customize Server
If you want to customize the server, you can read the following files first.

0. src/ruby/server/config.rb
0. src/ruby/server/start.rb
