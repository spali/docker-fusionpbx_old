#!/bin/bash
set -e

if [ "$1" = '/docker-command.sh' ]; then

	# clone inital config if not exist
	if [ -z "$(ls -A "$FREESWITCH_CONF")" ]; then
		git clone "$FREESWITCH_INIT_REPO" "$FREESWITCH_CONF"
	fi

	# create some freeswitch directories assumed to be there by fusionpbx
	[ ! -d $FREESWITCH_DATA/scripts ] && mkdir -p $FREESWITCH_DATA/scripts
	[ ! -d $FREESWITCH_DATA/storage/voicemail ] && mkdir -p $FREESWITCH_DATA/storage/voicemail

	# copy self signed certificates if none provided	
	if [ ! -f $NGINX_CERTS/fusionpbx.pem ] || [ ! -f $NGINX_CERTS/fusionpbx.key ]; then
		cp /etc/ssl/certs/ssl-cert-snakeoil.pem $NGINX_CERTS/fusionpbx.pem
		cp /etc/ssl/private/ssl-cert-snakeoil.key $NGINX_CERTS/fusionpbx.key
	fi

	# set document root
	sed -e "s#^\(\s*root\s*\)[^;]*\(.*\)#\1$FUSIONPBX_WWW_ROOT/fusionpbx\2#" -i /etc/nginx/sites-available/fusionpbx

	# set permissions
	chown -R root:freeswitch $NGINX_CERTS
	chmod 0644 $NGINX_CERTS/*.pem
	chmod 0640 $NGINX_CERTS/*.key
	chown -R freeswitch:freeswitch $FUSIONPBX_WWW_ROOT
	chown -R freeswitch:freeswitch "$FUSIONPBX_DATA"
	chown -R freeswitch:freeswitch "$FREESWITCH_CONF"
	chown -R freeswitch:freeswitch "$FREESWITCH_DATA"
	chown -R freeswitch:freeswitch /var/lib/nginx

	# configure fusionpbx if not already done
	if [ -z "$(ls -A "$FUSIONPBX_DATA")" ]; then

		# fake some directory structures for satisfying fusionpbx
		fake_dir=$FUSIONPBX_DATA/fakedir
		if [ ! -d $fake_dir ]; then
			mkdir -p $fake_dir
			ln -s $FREESWITCH_CONF $fake_dir/conf
			ln -s $FREESWITCH_DATA/scripts $fake_dir/scripts
			ln -s $FREESWITCH_DATA/storage $fake_dir/storage
			ln -s $FREESWITCH_DATA/recordings $fake_dir/recordings
		fi
		chown -R freeswitch:freeswitch $fake_dir

		/usr/sbin/php5-fpm --nodaemonize &
		/usr/sbin/nginx &
		sleep 5
		curl -s -d "install_switch_base_dir=$fake_dir&db_path=$FUSIONPBX_DATA&install_default_country=$FUSIONPBX_DEFAULT_COUNTRY&install_template_name=enhanced&admin_username=admin&admin_password=fusionpbx&db_type=sqlite&install_php_dir=$FUSIONPBX_WWW_ROOT&install_step=3" http://localhost/resources/install.php >/dev/null
		/usr/sbin/nginx -s stop
		killall php5-fpm
	fi

fi      

exec $@

