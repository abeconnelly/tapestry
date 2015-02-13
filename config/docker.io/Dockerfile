FROM ubuntu:14.10

RUN mkdir -p /root/private
COPY secret /root/private/secret

RUN /bin/bash -c " debconf-set-selections <<< 'mysql-server mysql-server/root_password password shakespeare' && \
  debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password shakespeare' "

RUN apt-get update && \
  apt-get install -y ruby ruby-dev ruby-curb ruby-safe-yaml ruby-yaml-db jq git python-setuptools rsync unzip wget zip at \
  build-essential apache2 apache2-threaded-dev mysql-server telnet curl libxslt-dev libxml2-dev lsof daemon \
  libcurl4-openssl-dev libapr1-dev libaprutil1-dev \
  runit fuse-emulator-utils libapache2-mod-passenger ruby-passenger \
  libmysql++-dev libmysql-cil-dev libmysqld-dev libmysqlcppconn-dev libmysqlclient-dev --fix-missing && \
  \curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
  \curl -sSL https://get.rvm.io | bash -s stable

RUN useradd -m tapestry && echo 'tapestry:tapestry' | chpasswd

#RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \
RUN sudo -i bash --login -c " rvm install ree && rvm use ree && ruby -v && \
    gem install passenger && \
    sed -e 's/^Mutex /#Mutex /' /etc/apache2/apache2.conf && \
    passenger-install-apache2-module -a "



RUN sudo --login bash --login -c " rvm use ree && ruby -v && \
      cd /var/www && \
      chmod a+w,+t . " && \
    su --login tapestry bash --login -c " cd /var/www && git clone https://github.com/abeconnelly/tapestry " && \
    sudo --login bash --login -c " rvm use ree && ruby -v && chmod go-w,-t . && \
      cd /var/www/tapestry && bundle install && \
      gem install mysql -v 2.9.1 "
#    su --login tapestry bash --login -c " cd /var/www/tapestry && git submodule init && git submodule update && \
#      rvm use ree && \
#      bundle install --deployment "

COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf

# These config files need to happen before the 'bundle install' ?
#
COPY ./config.yml /var/www/tapestry/config/config.yml
COPY ./development.rb /var/www/tapestry/config/environments/development.rb
#  cp /var/www/tapestry/config/environments/development.rb.example /var/www/tapestry/config/environments/development.rb && \
#  cp /var/www/tapestry/config/config.defaults.yml /var/www/tapestry/config/config.yml && \

COPY ./secret_token.rb /var/www/tapestry/config/initializers/secret_token.rb

RUN p=`jq -r .database_password /root/private/secret` && \
  sed "s/password: .*/password: $p/g" /var/www/tapestry/config/database.yml.example > /var/www/tapestry/config/database.yml


RUN su --login tapestry bash --login -c " cd /var/www/tapestry && git submodule init && git submodule update && \
      rvm use ree && \
      bundle install --deployment "

# NOTE: I've gotten errors of the form:
#  # service mysql start
#  /usr/sbin/mysqld: error while loading shared libraries: libaio.so.1: cannot open shared object file: Permission denied
#   * Starting MySQL database server mysqld
#  /usr/sbin/mysqld: error while loading shared libraries: libaio.so.1: cannot open shared object file: Permission denied
#
# To fix, in the HOST operating system, do the following:
# $ sudo ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/
# $ sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.mysqld
#
# http://stackoverflow.com/questions/22473830/docker-and-mysql-libz-so-1-cannot-open-shared-object-file-permission-denied
#   answered Nov 21 '14 at 19:18 by Abhi
#
# Some type of Docker bug that doesn't play well with apparmor?
# https://github.com/docker/docker/issues/5430
#
RUN service mysql start && \
  echo "create user 'tapestry'@'localhost' identified by 'shakespeare'" | mysql --user=root --password=shakespeare mysql && \
  echo "grant all privileges on *.* to 'tapestry'@'localhost' with grant option" | mysql --user=root --password=shakespeare mysql && \
  echo "flush privileges" | mysql --user=root --password=shakespeare mysql && \
  su --login tapestry bash -c " cd /var/www/tapestry && \
    rvm use ree && \
    rake db:setup && \
    rake db:schema:load && \
    rake db:seed_enrollment_steps "



COPY ./passenger.conf /etc/apache2/mods-available/passenger.conf
