Installing the Tapestry application

    ...or skip down to the section about Updating

The recommended ruby stack for Tapestry is Ruby Enterprise Edition (1.8.7), installed via rvm.

Install rvm and REE:

```bash
sudo -i
# curl -L https://get.rvm.io | sudo bash -s stable
# exit
sudo -i
# rvm install ree
# exit
```

Start a new login shell. Make sure RVM is working and ruby -v identifies itself as REE 1.8.7.

```bash
rvm use ree
ruby -v
```

→ ruby 1.8.7 (2012-02-08 MBARI 8/0x6770 on patchlevel 358) [x86_64-linux], MBARI 0x6770, Ruby Enterprise Edition 2012.02

Install rails.

```bash
sudo -i
# rvm use ree
# gem install passenger
# passenger-install-apache2-module
```

Add three lines (provided by passenger-install-apache2-module) and two more lines (see below) to /etc/apache2/conf.d/passenger.conf.


    LoadModule passenger_module /usr/local/rvm/gems/ree-1.8.7-2012.02/gems/passenger-3.0.17/ext/apache2/mod_passenger.so
    PassengerRoot /usr/local/rvm/gems/ree-1.8.7-2012.02/gems/passenger-3.0.17
    PassengerRuby /usr/local/rvm/wrappers/ree-1.8.7-2012.02/ruby

    PassengerUser YOUR_USERNAME_HERE
    RackEnv "development" 

Install some prerequisites for gems and the DRB server.

    sudo apt-get install libxslt-dev libxml2-dev lsof daemon

Get a copy of the source tree -- e.g., in /var/www/tapestry

```bash
cd /var/www
sudo chmod a+w,+t .
git clone https://github.com/curoverse/tapestry.git
sudo chmod go-w,-t .
cd tapestry && git submodule init && git submodule update
```

Then execute:

```bash
bundle install --deployment
```

Point a virtualhost to the public dir in your git repo

```
<VirtualHost *:80>
   ServerName tapestry.example.org
   DocumentRoot /var/www/tapestry/public
   <Directory /var/www/tapestry/public>
         AllowOverride all
         Options -MultiViews
   </Directory>
   Alias /warehouse /warehouse
   <Directory /warehouse>
         # This is important; downloads from /warehouse take a long time
         # and we do not want to tie up passenger processes with those.
         PassengerEnabled off
         Options None
         AllowOverride None
         Order allow,deny
         allow from all
   </Directory>
</VirtualHost>
```

Copy config/database.example to config/database.yml and edit to suit. Make sure to select mysql as the database server. Generate a password using pwgen 12 1 or head -c12345 /dev/urandom|md5sum|head -c12;echo. For example:

```
development:
  adapter: mysql
  server: localhost
  database: mypg
  username: mypg
  password: c16fbe415d29
  timeout: 5000
```

Copy config/environments/development.rb.example to config/environments/development.rb and edit it. You will probably want to update the ActionMailer::Base.smtp_settings section.

Create a new file @config/config.yml and add a 'development' section to override a few of the defaults configured in @config/config.defaults.yml. You should override these values to get started:

    root_url
    root_url_scheme

For a test/development setup, your @config/config.yml file could look like this:

```
development:
  root_url: 'hostname.of.your.machine'
  root_url_scheme: 'http://'
```

For a production setup, you are going to want to override most other variables defined in @config/config.defaults.yml.

Generate a secret token with something like

    ruby -e 'puts rand(2**256).to_s(36)'
    head -c1234567 /dev/urandom | sha256sum
    pwgen 64 1

Put the secret token in config/initializers/secret_token.rb like this

```rb
Tapestry::Application.configure do
 config.secret_token = "40ih46sqyihsiupgwce5u2oirflnor3atgmvzaqeqng42dwa0o" 
end
```

Set up the database:

```rb
rake db:setup
rake db:schema:load
```

Seed the database with a default set of enrollment steps:

```rb
rake db:seed_enrollment_steps
```

Set up data directory (replace USERNAME with the user who owns the GIT directory this code is in, and ROOT_URL matching the one above):

```rb
sudo mkdir -p /data/ROOT_URL
sudo chown -R USERNAME:USERNAME /data/ROOT_URL
```

Set up cron jobs --

1. populate NextHex table regularly (daily is probably ok):

```bash
SHELL=/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin
38 0 * * *  www-data  (source /usr/local/rvm/environments/ree-1.8.7-2012.02@global; cd /var/www/tapestry/script; ./populate_next_hex.rb production) 2>/dev/null
```

2. Optionally: /etc/cron.d/tapestry-get-blog-feed

```bash
PATH=/usr/local/bin:/usr/bin:/bin
0 * * * * www-data cd /var/www/tapestry/current/script && ./get-blog-feed.rb development http://blog.personalgenomes.org/feed/
```

To enable large uploads with warehouse storage:

    sudo apt-get install runit fuse-utils
    sudo mkdir -p /etc/service/whmount/log/main
    sudo usermod -a -G fuse www-data
    Set up supervised whmount service:

```bash
sudo tee /etc/service/whmount/run <<EOF >/dev/null
#!/bin/sh
modprobe fuse
mkdir -p /warehouse
chown www-data:www-data /warehouse
sudo -u www-data fusermount -u /warehouse
exec sudo -u www-data whmount --no-detach --threaded / /warehouse 2>&1
EOF
sudo chmod +t /etc/service/whmount
sudo chmod +x /etc/service/whmount/run

sudo tee /etc/service/whmount/log/run <<EOF >/dev/null
#!/bin/sh
exec svlogd -tt main
EOF
sudo chmod +x /etc/service/whmount/log/run
```

    Make sure config/config.yml matches your Apache and filesystem mount points:

```
  warehouse_web_root: "/warehouse" # Apache alias pointing to whmount target
  warehouse_fs_root: "/warehouse" # whmount target
```

Updating

Pull the latest source tree.

```bash
git pull
```

Install/update gem package dependencies.

```bash
bundle install --deployment
```

Bring your database up to the latest release.

```bash
rake db:migrate
```

Tell passenger to reload everything.

```bash
mkdir -p tmp
touch tmp/restart.txt
```

Creative Commons License
Unless noted, site content licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
