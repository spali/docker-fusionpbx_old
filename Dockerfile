FROM ubuntu:14.04

#######################################################################################

# define configuration environment variables
ENV FREESWITCH_CONF /etc/freeswitch
ENV FREESWITCH_DATA /var/lib/freeswitch
ENV FREESWITCH_INIT_REPO https://github.com/spali/freeswitch_conf_minimal.git
ENV FUSIONPBX_WWW_ROOT /var/www
ENV FUSIONPBX_DATA /var/lib/fusionpbx
ENV FUSIONPBX_DEFAULT_COUNTRY CH
ENV FUSIONPBX_REPO http://fusionpbx.googlecode.com/svn/trunk/
ENV FUSIONPBX_REVISION HEAD
ENV NGINX_CERTS /etc/nginx/certs

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r freeswitch && useradd -r -g freeswitch freeswitch

# install basics
RUN \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get -y install curl software-properties-common

# install required packages
RUN echo 'deb http://files.freeswitch.org/repo/deb/debian/ wheezy main' >>/etc/apt/sources.list.d/freeswitch.list && \
	curl -s http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add - && \
	add-apt-repository -y ppa:nginx/stable && \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y freeswitch-meta-all nginx php5-fpm php5-gd php-pear php5-memcache php-apc php5-sqlite git subversion ssl-cert


# edit php5-fpm configuration
RUN sed -e 's/^\(\(user\|group\)\s*=\s*\).*/\1freeswitch/' \
	-e 's/^\(listen\.\(owner\|group\)\s*=\s*\).*/\1freeswitch/' \
        -e '/catch_workers_output/s/^;//' \
        -i /etc/php5/fpm/pool.d/www.conf
RUN sed -e 's/\(upload_max_filesize\s*=\s*\).*/\110M/' \
	-e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' \
	-i /etc/php5/fpm/php.ini

# edit nginx configuration
COPY nginx_server /etc/nginx/sites-available/fusionpbx
RUN rm /etc/nginx/sites-enabled/default && \
	ln -s /etc/nginx/sites-available/fusionpbx /etc/nginx/sites-enabled/fusionpbx
RUN sed -e 's/^\(\user\s*\)[^\s;]*\(.*\)/\1freeswitch\2/' \
	-e '1,/^\s*$/ s/^\s*$/daemon off;\n/' \
	-e '1,/^\s*$/ s/^\s*$/error_log \/dev\/stdout info;\n/' \
	-i /etc/nginx/nginx.conf

# install fusionpbx
RUN rm -Rf $FUSIONPBX_WWW_ROOT/* && \
	svn export --force -r $FUSIONPBX_REVISION $FUSIONPBX_REPO $FUSIONPBX_WWW_ROOT/ && \
	find $FUSIONPBX_WWW_ROOT/* -maxdepth 0 -name fusionpbx -prune -o -name apps -prune -o -exec rm -Rf '{}' ';' && \
	/usr/bin/find $FUSIONPBX_WWW_ROOT/ -type f -exec /bin/chmod 644 {} \; && \
	/usr/bin/find $FUSIONPBX_WWW_ROOT/ -type d -exec /bin/chmod 755 {} \; && \
	mkdir $FUSIONPBX_DATA
	
#######################################################################################

# Define mountable directories.
VOLUME ["$FREESWITCH_CONF", "$FREESWITCH_DATA", "$FUSIONPBX_DATA", "$FUSIONPBX_WWW_ROOT", "$NGINX_CERTS", "/var/log"]

# expose ports
EXPOSE 80 443 5060 8021 16384  16385  16386  16387  16388  16389  16390  16391  16392  16393

#######################################################################################
COPY docker-entrypoint.sh /
COPY docker-command.sh /
RUN chmod +x /docker-entrypoint.sh /docker-command.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/docker-command.sh"]
#######################################################################################
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

