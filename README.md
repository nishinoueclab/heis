# README #

This project for programming semi at UEC nishino lab.
Heizu server in this repository.

# Before You Start
Please make sure Ruby is installed.
You can check with the following.
```
$ ruby -v
```

# Getting Repository
```
$ git clone https://tolz@bitbucket.org/tolz/heizu_server.git
```

# Ready for Starting Heizu Server
Install the ruby library "json-schema".
```
$ sudo gem install --remote json-schema
```

Prease make the directory "log" for saving some log files. 
```
$ cd heizu_server
$ mkdir log
```


# Starting Heizu Server
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
 

# Starting Sample Heizu Player Client
```
$ ruby src/ruby/server/player_client.rb
```

# Starting Sample Heizu Audience Client
```
$ ruby src/ruby/server/audience_client.rb
```

# Update Repository
```
$ cd heizu_server
$ git pull
```

# Customize Server
If you want to customize the server, you can read the following files first.

0. src/ruby/server/config.rb
0. src/ruby/server/start.rb
