#!/bin/bash
#Copyright (c) 2021 GoodData Corporation. All rights reserved.

export PGDATA=spec/postgresql

setupdb() {
	echo "[i] Creating a new PostgreSQL database cluster"
	if [ -d "$PGDATA" ]; then
	  chown -Rf $(whoami) "${PGDATA}"
	fi
	initdb $PGDATA
	sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf
	createdb
	adduser
}

adduser() {
	echo "[i] Adding users"
	if [ "$POSTGRES_PASSWORD" ]; then
		pass="PASSWORD '$POSTGRES_PASSWORD'"
		authMethod=md5
	else
		echo "[!] use POSTGRES_PASSWORD to set postgres password"
		pass=
		authMethod=trust
	fi

	# echo not needed, enabled by default
	# { echo; echo "local all all 127.0.0.1/8 trust"; } >> "$PGDATA"/pg_hba.conf

	{ echo; echo "host all all 0.0.0.0/0 $authMethod"; } >> "$PGDATA"/pg_hba.conf

	if [ "$POSTGRES_USER" != 'postgres' ]; then
		op=CREATE
		userSql="$op USER $POSTGRES_USER WITH $pass;"
		echo $userSql | postgres --single -jE $POSTGRES_DB
		grantSql="GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;"
		echo $grantSql | postgres --single -jE $POSTGRES_DB
	else
		op=ALTER
		userSql="$op USER $POSTGRES_USER WITH $pass;"
		echo $userSql | postgres --single -jE $POSTGRES_DB
	fi
}

createdb() {
	if [ "$POSTGRES_DB" != "postgres" ]; then
		echo "[i] Creating initial database: $POSTGRES_DB"
		createSql="CREATE DATABASE $POSTGRES_DB;"
		echo $createSql | postgres --single -jE postgres
	fi
}

createData() {
  sleep 15
  echo "Creating data test"
  export PGPASSWORD=$POSTGRES_PASSWORD
  # Prepare data for testing
  /usr/bin/psql -U $POSTGRES_USER -d $POSTGRES_DB -a -c "
  DROP TABLE IF EXISTS clients;
  CREATE TABLE IF NOT EXISTS clients(id INTEGER , segment_id VARCHAR(255), client_id VARCHAR(255), project_title VARCHAR(255), project_token VARCHAR(255));"

  /usr/bin/psql -U $POSTGRES_USER -d $POSTGRES_DB -a -c "COPY clients FROM '$(pwd)/spec/data/postgresql_data.csv' DELIMITER ',' CSV HEADER"
  sleep 5
}

# execute any pre-init scripts, useful for images
# based on this image
for i in $HOME/pre-init.d/*sh
do
	if [ -e "${i}" ]; then
		echo "[i] pre-init.d - processing $i"
		. "${i}"
	fi
done

setupdb

# execute any pre-exec scripts, useful for images
# based on this image
for i in $HOME/pre-exec.d/*sh
do
	if [ -e "${i}" ]; then
		echo "[i] pre-exec.d - processing $i"
		. ${i}
	fi
done

echo "[i] Starting PostgreSQL..."

exec postgres "$@" & createData

bundle exec rake -f lcm.rake test:integration
