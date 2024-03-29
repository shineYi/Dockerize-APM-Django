FROM docker.io/centos:7.4.1708
MAINTAINER Shinhye Yi <shinhye.yi@navercorp.com>

USER root

RUN yum clean all \
    && yum repolist \
    && yum -y update \
    && yum -y install sudo

RUN mkdir /home1 \
    && useradd -d /home1/irteam -m irteam \
    && useradd -d /home1/irteamsu -m irteamsu \
    && echo "irteamsu ALL=NOPASSWD:ALL" >> /etc/sudoers

RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.232.b09-0.el7_7.x86_64' >> /etc/profile \
    && echo 'export CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar' >> /etc/profile \
    && echo 'export APACHE_HOME=/home1/irteam/apps/apache' >> /etc/profile \
    && echo 'export APP_HOME=/home1/irteam/apps' >> /etc/profile \
    && echo 'export LD_LIBRARY_PATH=$APP_HOME/mysql/lib:$APP_HOME/python/lib' >> /etc/profile \
    && echo 'PATH=/bin:/usr/bin:/usr/local/bin:$JAVA_HOME/bin:/home1/irteam/apps/tomcat1/bin:/home1/irteam/apps/tomcat2/bin:$APACHE_HOME/bin:$APP_HOME/mysql/bin:$APP_HOME/python/bin' >> /etc/profile \
    && source /etc/profile

RUN /usr/bin/localedef --force --inputfile en_US --charmap UTF-8 en_US.UTF-8 && \
    echo "export LANG=en_US.UTF-8" > /etc/profile.d/locale.sh


USER irteamsu

RUN sudo yum clean all \
  && sudo yum -y reinstall glibc-common


RUN sudo yum -y install tar vim telnet net-tools curl openssl openssl-devel \
 && sudo yum -y install apr apr-util apr-devel apr-util-devel \
 && sudo yum -y install elinks locate python-setuptools \
 && sudo yum -y install gcc make gcc-c++ wget \
 && sudo yum -y install java-1.8.0-openjdk-devel.x86_64 \
 && sudo yum -y install cmake ncurses ncurses-devel \
 && sudo yum clean all

RUN sudo yum -y install libxml2 libxml2-devel \
    && sudo yum groupinstall -y "Development Tools" \
    && sudo yum install -y readline-devel sqlite-devel \
    && sudo yum install -y libffi-devel \
    && sudo yum -y install libjpeg-devel freetype-devel php-bcmath php-mbstring php-gd libpng-devel \
    && sudo yum -y install net-snmp net-snmp-devel libevent libevent-devel curl-devel \
    && sudo yum remove -y mariadb-libs-5.5.64-1.el7.x86_64

#RUN sudo ln -s /usr/lib64/libnetsnmp.so.31.0.2 /usr/lib64/libnetsnmp.so

RUN sudo chmod 755 /home1/irteam

USER irteam

RUN mkdir /home1/irteam/apps /home1/irteam/logs

# install and unzip tar files
WORKDIR /home1/irteam/apps/
RUN wget http://apache.mirror.cdnetworks.com//apr/apr-1.7.0.tar.gz \
    && wget http://apache.mirror.cdnetworks.com//apr/apr-util-1.6.1.tar.gz \
    && wget ftp://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz \
    && wget http://mirror.navercorp.com/apache//httpd/httpd-2.4.41.tar.gz \
    && wget http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.4/bin/apache-tomcat-9.0.4.tar.gz \
    && wget http://apache.tt.co.kr/tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.46-src.tar.gz \
    && wget https://downloads.mysql.com/archives/get/file/mysql-5.7.27.tar.gz \
    && wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.18.tar.gz \
    && wget http://museum.php.net/php5/php-5.5.0.tar.gz \
    && wget https://github.com/GrahamDumpleton/mod_wsgi/archive/4.6.5.tar.gz \
    && wget https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/4.4.1/zabbix-4.4.1.tar.gz

RUN find . -name "*.tar.gz" -exec tar xvfz {} \;

RUN wget https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tgz \
    && tar xvfz Python-3.7.4.tgz

RUN mv apache-tomcat-9.0.4 tomcat1 \
    && tar xvfz apache-tomcat-9.0.4.tar.gz \
    && mv apache-tomcat-9.0.4 tomcat2


# locate libraries

RUN mv apr-1.7.0 ./httpd-2.4.41/srclib/apr \
    && mv apr-util-1.6.1 ./httpd-2.4.41/srclib/apr-util

RUN cp mysql-connector-java-8.0.18/mysql-connector-java-8.0.18.jar tomcat1/lib/ \
    && cp mysql-connector-java-8.0.18/mysql-connector-java-8.0.18.jar tomcat2/lib/

RUN ln -s tomcat-connectors-1.2.46-src mod_jk



# Makefile

WORKDIR /home1/irteam/apps/pcre-8.43
RUN ./configure --prefix=/home1/irteam/apps/pcre \
    && make && make install

WORKDIR /home1/irteam/apps/httpd-2.4.41
RUN ./configure --prefix=/home1/irteam/apps/apache --enable-module=so --enable-mods-shared=ssl --with-ssl=/usr/lib64/openssl --enable-ssl=shared --with-pcre=/home1/irteam/apps/pcre/bin/pcre-config \
    && make && make install

WORKDIR /home1/irteam/apps/mysql-5.7.27/
RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/home1/irteam/apps/mysql \
    -DMYSQL_DATADIR=/home1/irteam/apps/mysql/data \
    -DMYSQL_UNIX_ADDR=/home1/irteam/apps/mysql/tmp/myqld.sock \
    -DSYSCONFDIR=/home1/irteam/apps/mysql/etc \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS=all \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=/home1/irteam/apps/my_boost

RUN make && make install

WORKDIR /home1/irteam/apps/php-5.5.0/
RUN ./configure --prefix=/home1/irteam/apps/php --with-apxs2=/home1/irteam/apps/apache/bin/apxs --with-mysql=mysqlnd  --with-pdo-mysql=mysqlnd --with-mysqli=mysqlnd --with-libdir=/home1/irteam/apps/mysql/lib --enable-sigchild --with-config-file-path=/home1/irteam/apps/apache/conf --enable-bcmath  --enable-mbstring --enable-sockets --with-gd --with-jpeg-dir=/usr/lib64 --with-freetype-dir=/usr/lib64 \
    && make && make install

RUN cp php.ini-development ~/apps/apache/conf/php.ini
WORKDIR /home1/irteam/apps/php/lib/
RUN ln -s /home1/irteam/apps/apache/conf/php.ini php.ini

WORKDIR /home1/irteam/apps/mod_jk/native/
RUN ./configure --with-apxs=/home1/irteam/apps/apache/bin/apxs \
    && make && make install

WORKDIR /home1/irteam/apps/Python-3.7.4/
RUN ./configure --prefix=/home1/irteam/apps/python --enable-shared \
    && make && make install

WORKDIR /home1/irteam/apps/mod_wsgi-4.6.5/
RUN source /etc/profile \
    && ./configure --prefix=/home1/irteam/apps/mod_wsgi --with-apxs=/home1/irteam/apps/apache/bin/apxs --with-python=/home1/irteam/apps/python/bin/python3.7 \
    && make && make install



# Create link for logs
RUN rmdir ~/apps/apache/logs \
    && mkdir ~/logs/apache \
    && ln -s ~/logs/apache/ ~/apps/apache/logs

RUN rmdir ~/apps/tomcat1/logs \
    && mkdir ~/logs/tomcat1 \
    && ln -s ~/logs/tomcat1/ ~/apps/tomcat1/logs

RUN rmdir ~/apps/tomcat2/logs \
    && mkdir ~/logs/tomcat2 \
    && ln -s ~/logs/tomcat2/ ~/apps/tomcat2/logs


# Move gzip files to directory

RUN mkdir ~/apps/gz_dir \
    && mv ~/apps/*.tar.gz ~/apps/gz_dir



# Settings

WORKDIR /home1/irteam/apps/apache/conf/

RUN sed -i "199s/#//" httpd.conf \
    && sed -i "199s/www.example.com:80/localhost/" httpd.conf

# Connect tomcat1,2 and apache

RUN echo 'LoadModule jk_module modules/mod_jk.so' >> httpd.conf \
    && echo '<IfModule jk_module>' >> httpd.conf \
    && echo '    JkWorkersFile    conf/workers.properties' >> httpd.conf \
    && echo '    JkLogFile        logs/mod_jk.log' >> httpd.conf \
    && echo '    JkLogLevel       info' >> httpd.conf \
    && echo '    JkMountFile      conf/uriworkermap.properties' >> httpd.conf \
    && echo '</IfModule>' >> httpd.conf

RUN touch uriworkermap.properties \
    && echo '/*.jsp=load_balancer' >> uriworkermap.properties

RUN touch workers.properties \
    && echo 'worker.list=load_balancer' >> workers.properties \
    && echo 'worker.load_balancer.type=lb' >> workers.properties \
    && echo 'worker.load_balancer.balance_workers=tomcat1,tomcat2' >> workers.properties \
    && echo 'worker.tomcat1.port=8109' >> workers.properties \
    && echo 'worker.tomcat1.host=localhost' >> workers.properties \
    && echo 'worker.tomcat1.type=ajp13' >> workers.properties \
    && echo 'worker.tomcat1.lbfactor=1' >> workers.properties \
    && echo 'worker.tomcat2.port=8209' >> workers.properties \
    && echo 'worker.tomcat2.host=localhost' >> workers.properties \
    && echo 'worker.tomcat2.type=ajp13' >> workers.properties \
    && echo 'worker.tomcat2.lbfactor=1' >> workers.properties


# Set SSL on apache

RUN sed -i "89s/#//" httpd.conf \
    && sed -i "137s/#//" httpd.conf \
    && sed -i "499s/#//" httpd.conf
    
RUN openssl genrsa -aes256 -out tmp-server.key -passout pass:1234 2048 \
    && openssl rsa -in tmp-server.key -out server.key -passin pass:1234 \
    && openssl req -new -key server.key -out server.csr -subj "/C=KR/ST=Gyeonggi-do/L=Seongnam-si/O=global Security/OU=IT" \
    && openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

RUN sed -i "122s/.*/JkMountFile conf\/uriworkermap.properties/g" ./extra/httpd-ssl.conf


# Connect php and apache

RUN sed -i "1198s/=/=\/home1\/irteam\/apps\/mysql\/tmp\/mysqld.sock/" php.ini
RUN sed -i "147s/#//" httpd.conf
RUN sed -i "257s/html/html index.php/" httpd.conf

RUN perl -p -i -e '$.==394 and print "AddType application/x-httpd-php .php .html .php5\n"' httpd.conf \
    && perl -p -i -e '$.==395 and print "AddType application/x-httpd-php-source .phps\n"' httpd.conf



# Change port num and clusterting setting on Tomcat1,2

WORKDIR /home1/irteam/apps/tomcat1/conf/
RUN sed -i "22s/8005/8105/" server.xml \
    && sed -i "116s/8009/8109/" server.xml \
    && sed -i "133s/<\!--//" server.xml \
    && sed -i "135s/-->//" server.xml

WORKDIR /home1/irteam/apps/tomcat2/conf/
RUN sed -i "22s/8005/8205/" server.xml \
    && sed -i "69s/8080/8081/" server.xml \
    && sed -i "116s/8009/8209/" server.xml \
    && sed -i "133s/<\!--//" server.xml \
    && sed -i "135s/-->//" server.xml \
    && sed -i "134s/\///" server.xml \
    && perl -p -i -e '$.==135 and print "</Cluster>"' server.xml \
    && perl -p -i -e '$.==135 and print "<Receiver className=\"org.apache.catalina.tribes.transport.nio.NioReceiver\" port=\"4001\"/>"' server.xml



# Setting MySQL

WORKDIR /home1/irteam/apps/mysql/
RUN mkdir tmp etc && touch etc/my.cnf && mkdir /home1/irteam/logs/mysql

RUN echo -e '[client]\nuser=root\npassword=root1234\nport = 13306\nsocket = /home1/irteam/apps/mysql/tmp/mysqld.sock' >> etc/my.cnf

RUN echo -e '[mysqld]\nuser=root\nport = 13306\nbasedir=/home1/irteam/apps/mysql\ndatadir=/home1/irteam/apps/mysql/data\nsocket=/home1/irteam/apps/mysql/tmp/mysqld.sock' >> etc/my.cnf

RUN echo -e 'log-error=/home1/irteam/logs/mysql/mysqld.log\npid-file=/home1/irteam/apps/mysql/tmp/mysqld.pid' >> etc/my.cnf

RUN echo -e 'skip-character-set-client-handshake\ninit_connect = SET collation_connection = utf8_general_ci\ninit_connect = SET NAMES utf8\ncharacter-set-server = utf8\ncollation-server = utf8_general_ci' >> etc/my.cnf

RUN echo -e 'default-storage-engine = InnoDB\ninnodb_buffer_pool_size = 503MB' >> etc/my.cnf

RUN echo -e 'explicit_defaults_for_timestamp\nskip-grant-tables' >> etc/my.cnf


# Change root passwd on MySQL

RUN bin/mysqld --initialize \ 
    && support-files/mysql.server start \
    && bin/mysql <<< "UPDATE mysql.user SET authentication_string=PASSWORD('root1234') WHERE user='root' AND Host='localhost'; FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY 'root1234'; create database myboard_db; grant all on myboard_db.* to 'djangoadmin'@'%' identified by 'django12'; grant all on myboard_db.* to 'djangoadmin'@'localhost' identified by 'django12';create database zabbix; grant all privileges on zabbix.* to 'zabbixadmin'@'localhost' identified by 'zabbix12'; grant all privileges on zabbix.* to 'zabbixadmin'@'%' identified by 'zabbix12'; GRANT USAGE,REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zabbixadmin'@'%'; GRANT USAGE,REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zabbixadmin'@'localhost'; FLUSH PRIVILEGES;\q" \ 
    && sed -i '$d' etc/my.cnf \
    && bin/mysql zabbix < /home1/irteam/apps/zabbix-4.4.1/database/mysql/schema.sql \
    && bin/mysql zabbix < /home1/irteam/apps/zabbix-4.4.1/database/mysql/images.sql \
    && bin/mysql zabbix < /home1/irteam/apps/zabbix-4.4.1/database/mysql/data.sql \
    && support-files/mysql.server stop


# Create Tomcat manager account
WORKDIR /home1/irteam/apps/tomcat1/conf/
RUN sed -i '$d' tomcat-users.xml \
    && echo "<role rolename=\"manager-gui\"/>" >> tomcat-users.xml \
    && echo "<role rolename=\"manager-script\"/>" >> tomcat-users.xml \
    && echo "<role rolename=\"manager-status\"/>" >> tomcat-users.xml \
    && echo "<user username=\"tomcatadmin\" password=\"tomcat12\" roles=\"manager-gui,manager-script,manager-status\"/>" >> tomcat-users.xml \
    && echo "</tomcat-users>" >>tomcat-users.xml

RUN cp tomcat-users.xml /home1/irteam/apps/tomcat2/conf/


# Set shortcut
RUN echo "export APP_HOME=/home1/irteam/apps" >> ~/.bashrc \
&& echo "alias apache-start=\"\$APP_HOME/apache/bin/httpd -k start\"" >> ~/.bashrc \
&& echo "alias apache-stop=\"\$APP_HOME/apache/bin/httpd -k stop\"" >> ~/.bashrc \
&& echo "alias apache-restart=\"\$APP_HOME/apache/bin/httpd -k restart\"" >> ~/.bashrc \
&& echo "alias tomcat1-start=\"\$APP_HOME/tomcat1/bin/startup.sh\"" >> ~/.bashrc \
&& echo "alias tomcat1-stop=\"\$APP_HOME/tomcat1/bin/shutdown.sh\"" >> ~/.bashrc \
&& echo "alias tomcat2-start=\"\$APP_HOME/tomcat2/bin/startup.sh\"" >> ~/.bashrc \
&& echo "alias tomcat2-stop=\"\$APP_HOME/tomcat2/bin/shutdown.sh\"" >> ~/.bashrc \
&& echo "alias mysql-start=\"\$APP_HOME/mysql/support-files/mysql.server start\"" >> ~/.bashrc \
&& echo "alias mysql-stop=\"\$APP_HOME/mysql/support-files/mysql.server stop\"" >> ~/.bashrc \
&& echo "alias mysql-restart=\"\$APP_HOME/mysql/support-files/mysql.server restart\"" >> ~/.bashrc \
&& echo "alias python=\"\$APP_HOME/python/bin/python3.7\"" >> ~/.bashrc \
&& echo "alias pip=\"\$APP_HOME/python/bin/pip3.7\"" >> ~/.bashrc

# Install zabbix
WORKDIR /home1/irteam/apps/zabbix-4.4.1
RUN ./configure --prefix=/home1/irteam/apps/zabbix --enable-server --enable-agent --enable-java --enable-ipv6 --with-mysql=/home1/irteam/apps/mysql/bin/mysql_config --with-libcurl --with-libxml2 \
    && make && make install

RUN cd conf/zabbix_agentd \
    && cp userparameter_mysql.conf ~/apps/zabbix/etc/zabbix_agentd.conf.d/

# Set zabbix frontend pages on apache
WORKDIR /home1/irteam/apps
RUN mkdir apache/htdocs/zabbix \
    && cd zabbix-4.4.1/frontends/php \
    && cp -a . /home1/irteam/apps/apache/htdocs/zabbix

# Change php setting for initial zabbix start condition
WORKDIR /home1/irteam/apps/apache/conf
RUN sed -i "672s/8/16/" php.ini \
&& sed -i "384s/30/300/" php.ini \
&& sed -i "394s/60/300/" php.ini \
&& sed -i "923s/;//" php.ini \
&& sed -i "923s/=/= Asia\/Seoul/" php.ini \
&& sed -i "1134s/=/= 13306/" php.ini


# zabbix setting
WORKDIR /home1/irteam/apps/zabbix/etc
RUN mkdir /home1/irteam/logs/zabbix
RUN sed -i "30s/tmp/home1\/irteam\/logs\/zabbix/" zabbix_agentd.conf \
    && sed -i "287s/#//" zabbix_agentd.conf \
    && sed -i "287s/usr\/local/home1\/irteam\/apps\/zabbix/" zabbix_agentd.conf

RUN sed -i "38s/tmp/home1\/irteam\/logs\/zabbix/" zabbix_server.conf \
    && sed -i "110s/x/xadmin/" zabbix_server.conf \
    && sed -i "118s/=/= zabbix12/" zabbix_server.conf \
    && sed -i "118s/#//" zabbix_server.conf \
    && sed -i "125s/=/= \/home1\/irteam\/apps\/mysql\/tmp\/mysqld.sock/" zabbix_server.conf \
    && sed -i "125s/#//" zabbix_server.conf \
    && sed -i "133s/=/= 13306/" zabbix_server.conf \
    && sed -i "133s/#//" zabbix_server.conf \
    && sed -i "282s/#//" zabbix_server.conf \
    && sed -i "282s/=/=127.0.0.1/" zabbix_server.conf \
    && sed -i "290s/#//"  zabbix_server.conf \
    && sed -i "298s/#//"  zabbix_server.conf \
    && sed -i "298s/0/5/"  zabbix_server.conf


# Setting for Apache Connection
WORKDIR /home1/irteam/apps/apache/conf
RUN echo "<Location \"/server-status\">" >> httpd.conf \
    && echo "SetHandler server-status" >> httpd.conf \
    && echo "</Location>" >> httpd.conf


# Setting for MySQL Connection
WORKDIR /home1/irteam/apps/apache/htdocs/zabbix/conf
RUN touch zabbix.conf.php \
    && echo -e "<?php\nglobal \$DB;\n\n" >> zabbix.conf.php \
    && echo "\$DB['TYPE']     = 'MYSQL';" >> zabbix.conf.php \
    && echo "\$DB['SERVER']   = '10.106.223.175';" >> zabbix.conf.php \
    && echo "\$DB['PORT']     = '13306';" >> zabbix.conf.php \
    && echo "\$DB['DATABASE'] = 'zabbix';" >> zabbix.conf.php \
    && echo "\$DB['USER']     = 'zabbixadmin';" >> zabbix.conf.php \
    && echo "\$DB['PASSWORD'] = 'zabbix12';" >> zabbix.conf.php \
    && echo "\$DB['SCHEMA'] = '';" >> zabbix.conf.php \
    && echo "\$ZBX_SERVER      = 'localhost';"  >> zabbix.conf.php \
    && echo "\$ZBX_SERVER_PORT = '10051';" >> zabbix.conf.php \
    && echo "\$ZBX_SERVER_NAME = '';" >> zabbix.conf.php \
    && echo "\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;" >> zabbix.conf.php 


WORKDIR /home1/irteam/apps/zabbix/lib
RUN touch .my.cnf \
    && echo "[client]" >> .my.cnf \
    && echo "user=zabbixadmin" >> .my.cnf \
    && echo "password=zabbix12" >> .my.cnf


WORKDIR /home1/irteam/apps/zabbix-4.4.1/conf/zabbix_agentd
RUN cp userparameter_mysql.conf ~/apps/zabbix/etc/zabbix_agentd.conf.d


# Setting for Tomcat Connection
WORKDIR /home1/irteam/apps/zabbix/sbin/zabbix_java
RUN sed -i "46s/#//" settings.sh && sed -i "47s/#//" settings.sh


# Create Django Project
WORKDIR /home1/irteam/apps/python/bin
RUN source /etc/profile \
    && ./pip3.7 install --upgrade pip \
    && ./pip3.7 install django==2.1.* \
    && ./pip3.7 install mysqlclient \
    && ./django-admin startproject django_board . \
    && ./python3.7 manage.py startapp myboard \
    && ln -s /home1/irteam/apps/python/bin/django_board ~/django_board \
    && rm -rf django_board && rm -rf myboard

RUN git clone https://github.com/shineYi/Django-Myboard.git \
    && mv Django-Myboard/django_board ./django_board \
    && mv Django-Myboard/myboard ./myboard \
    && rm -rf Django-Myboard

# Setting Apache for Connect Django
WORKDIR /home1/irteam/apps/apache/conf
RUN perl -p -i -e '$.==65 and print "LoadFile /home1/irteam/apps/mysql/lib/libmysqlclient.so.20\n"' httpd.conf \
    && perl -p -i -e '$.==66 and print "LoadFile /home1/irteam/apps/python/lib/libpython3.7m.so.1.0\n"' httpd.conf \
    && perl -p -i -e '$.==67 and print "LoadModule wsgi_module modules/mod_wsgi.so\n"' httpd.conf \
    && echo "WSGIScriptAlias /myboard /home1/irteam/django_board/wsgi.py" >> httpd.conf \
    && echo "WSGIPythonPath /home1/irteam/apps/python/bin" >> httpd.conf \
    && echo "<Directory /home1/irteam/django_board>" >> httpd.conf \
    && echo "<Files wsgi.py>" >> httpd.conf \
    && echo "Require all granted" >> httpd.conf \
    && echo "</Files>" >> httpd.conf \
    && echo "</Directory>" >> httpd.conf



USER irteamsu

WORKDIR /home1/irteam/apps/
RUN sudo chown root:irteam apache/bin/httpd \
    && sudo chmod 4755 apache/bin/httpd

RUN sudo chown root:irteam tomcat1/bin/startup.sh \
    && sudo chmod 4755 tomcat1/bin/startup.sh \
    && sudo chown root:irteam tomcat2/bin/startup.sh \
    && sudo chmod 4755 tomcat2/bin/startup.sh


# USER irteam
# WORKDIR /home1/irteam/


ENV LANG=ko_KR.utf8 TZ=Asia/Seoul


EXPOSE 13306
EXPOSE 80 443
EXPOSE 8080 8081


CMD ["/bin/bash"]

