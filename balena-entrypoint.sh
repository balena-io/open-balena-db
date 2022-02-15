#!/bin/bash

set -e

# copies all the data from $1 to $2
restore_volume () {
    echo "=== Restoring data volume structure"
    find "$1" -maxdepth 1 \
        ! -path "$1" \
        | xargs mv -t "$2"
}

# install the old version of Postgres, required when doing an upgrade
install_old_version () {
    if [ ! -d "/usr/lib/postgresql/$1/bin" ]; then
        sed -i 's/$/ '"$1"'/' /etc/apt/sources.list.d/pgdg.list

        apt-get -qq update \
        && apt-get install -qq -y --no-install-recommends \
            "postgresql-$1" \
        && rm -rf /var/lib/apt/lists/*
    fi
}

# creates a dir at $1 which is valid for Postgres data to live in
create_postgres_data_dir () {
    echo "=== Creating data dir $1"
    mkdir -p "$1"
    chmod 700 "$1"
    chown -R postgres:postgres "$1"
}

# echo a message and die
die_with_message () {
    echo "[FATAL] $1"
    exit 2
}

# check that this is running from within a valid Postgres container environment
[ ! -z "$PG_MAJOR" ] || die_with_message "Not a compatible Postgres runtime environment"

# set our target version
TARGET_VERSION="$PG_MAJOR"

# ensure we have a versioned data directory
[ -d "${PGDATA}/${TARGET_VERSION}" ] || create_postgres_data_dir "${PGDATA}/${TARGET_VERSION}"

# check for Postgres data in the root of the $PGDATA directory
if [ -f "${PGDATA}/PG_VERSION" ]; then
    SOURCE_VERSION="$(cat ${PGDATA}/PG_VERSION)"

    # does the data need upgrading?
    if [ "$SOURCE_VERSION" -ne "$TARGET_VERSION" ]; then
        echo "=== Upgrading data from v${SOURCE_VERSION} to v${TARGET_VERSION}"

        PGDATAOLD="${PGDATA}/${SOURCE_VERSION}"
        PGDATANEW="${PGDATA}/${TARGET_VERSION}"
        PGBINOLD="/usr/lib/postgresql/$SOURCE_VERSION/bin"
        PGBINNEW="/usr/lib/postgresql/$TARGET_VERSION/bin"

        echo "=== Installing tools for Postgres v${SOURCE_VERSION}"
        install_old_version "$SOURCE_VERSION"

        echo "=== Moving existing data to ${PGDATAOLD}"
        create_postgres_data_dir "${PGDATAOLD}"
        find "$PGDATA" -maxdepth 1 \
            ! -path "$PGDATA" \
            ! -path "$PGDATAOLD*" \
            | xargs mv -t "${PGDATAOLD}"

        trap "restore_volume ${PGDATAOLD} ${PGDATA}" ERR

        echo "=== Initializing new data directory ${PGDATANEW}"
        rm -rf "${PGDATANEW}"
        create_postgres_data_dir "${PGDATANEW}"
        gosu postgres initdb -D "$PGDATANEW" -U "$POSTGRES_USER" $POSTGRES_INITDB_ARGS

        echo "=== Running pg_upgrade"
        cd /tmp
        gosu postgres pg_upgrade \
            -U "$POSTGRES_USER" \
            --old-datadir="$PGDATAOLD" \
            --new-datadir="$PGDATANEW" \
            --old-bindir="$PGBINOLD" \
            --new-bindir="$PGBINNEW" \
            --check

        gosu postgres pg_upgrade \
            -U "$POSTGRES_USER" \
            --old-datadir="$PGDATAOLD" \
            --new-datadir="$PGDATANEW" \
            --old-bindir="$PGBINOLD" \
            --new-bindir="$PGBINNEW"

        echo "=== Restoring configuration files"
        cp "${PGDATAOLD}/pg_hba.conf" "${PGDATANEW}/pg_hba.conf"
        cp "${PGDATAOLD}/pg_ident.conf" "${PGDATANEW}/pg_ident.conf"
    else
        echo "=== Moving existing data to directory "${PGDATA}/${TARGET_VERSION}""
        find "$PGDATA" -maxdepth 1 \
            ! -path "$PGDATA" \
            | xargs mv -t "${PGDATA}/${TARGET_VERSION}"
    fi
fi

# set our runtime data directory to the target version
export PGDATA="${PGDATA}/${TARGET_VERSION}"

# run the existing Postgres entrypoint script
. /usr/local/bin/docker-entrypoint.sh
_main "$@"
