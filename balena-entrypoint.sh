#!/bin/bash

set -e

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
create_postgres_dir () {
    echo "=== Creating postgres directory $1"
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
PGDATANEW="${PGDATA}/${TARGET_VERSION}"

WORKDIR=/usr/lib/postgresql/upgrade

# check there's no previously interrupted upgrade, it would be dangerous to continue
[ ! -d "${WORKDIR}" ] || die_with_message "Found possibly interrupted upgrade in ${WORKDIR}; not continuing"

migrate_pgdata_root_if_needed () {
    # perform a one-time migration from storing data under $PGDATA root,
    # to storing it under $PGDATA/$PG_VERSION
    if [ -f "${PGDATA}/PG_VERSION" ]; then
        local version="$(cat "${PGDATA}/PG_VERSION")"
        if [ ! -d "${PGDATA}/${version}" ]; then
            create_postgres_dir "${PGDATA}/${version}"
            echo "=== Moving existing data to directory "${PGDATA}/${version}""
            find "$PGDATA" -maxdepth 1 \
                ! -path "$PGDATA" \
                ! -path "${PGDATA}/${version}*" \
                | xargs mv -t "${PGDATA}/${version}"
        fi
    fi
}

find_source_version () {
    # find our source version by looking for a PG_VERSION file
    # in every directory under $PGDATA
    for src in $(find "$PGDATA" -maxdepth 2 -type f -name 'PG_VERSION' | sort -rn); do
        local version="$(cat "$src")"
        if [ "$version" -ne "$TARGET_VERSION" ]; then
            SOURCE_VERSION="$version"
            PGDATAOLD="$(dirname "$src")" # drop 'PG_VERSION' from path
            break
        fi
    done
}

perform_upgrade_if_needed () {
    # does the data need upgrading?
    if [ -n "${SOURCE_VERSION}" ]; then
        echo "=== Upgrading data from v${SOURCE_VERSION} to v${TARGET_VERSION}"

        create_postgres_dir "${WORKDIR}"

        PGBINOLD="/usr/lib/postgresql/$SOURCE_VERSION/bin"
        PGBINNEW="/usr/lib/postgresql/$TARGET_VERSION/bin"

        echo "=== Installing tools for Postgres v${SOURCE_VERSION}"
        install_old_version "$SOURCE_VERSION"

        echo "=== Initializing new data directory ${PGDATANEW}"
        create_postgres_dir "${PGDATANEW}"
        gosu postgres initdb \
            -D "$PGDATANEW" \
            -U "$POSTGRES_USER" \
            $POSTGRES_INITDB_ARGS

        echo "=== Running pg_upgrade"
        pushd "${WORKDIR}" >/dev/null

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

        popd >/dev/null

        echo "=== Data upgraded successfully"
    fi
}

complete_upgrade_if_needed () {
    if [ -d "${WORKDIR}" ]; then
        echo "=== Performing post-upgrade steps"
        pushd "${WORKDIR}" >/dev/null

        echo "=== Starting temp server"
        gosu postgres bash -c '. /usr/local/bin/docker-entrypoint.sh; docker_temp_server_start'

        if [ -f "${WORKDIR}/update_extensions.sql" ]; then
            echo "=== Updating extensions"
            gosu postgres psql \
                -U "$POSTGRES_USER" \
                -f "${WORKDIR}/update_extensions.sql"
        fi
        if [ -f "${WORKDIR}/analyze_new_cluster.sh" ]; then
            echo "=== Analyzing new cluster"
            gosu postgres "${WORKDIR}/analyze_new_cluster.sh"
        fi
        if [ -f "${WORKDIR}/delete_old_cluster.sh" ]; then
            echo "=== Deleting old cluster"
            gosu postgres "${WORKDIR}/delete_old_cluster.sh"
        else
            rm -rf "${PGDATAOLD}"
        fi

        echo "=== Stopping temp server"
        gosu postgres bash -c '. /usr/local/bin/docker-entrypoint.sh; docker_temp_server_stop'

        popd >/dev/null
        rm -rf "${WORKDIR}"

        echo "=== Data upgrade complete"
    fi
}

migrate_pgdata_root_if_needed
find_source_version
perform_upgrade_if_needed

# ensure we have a versioned data directory
[ -d "${PGDATANEW}" ] || create_postgres_dir "${PGDATANEW}"

# set our runtime data directory to the target version
export PGDATA="${PGDATANEW}"

complete_upgrade_if_needed

# run the existing Postgres entrypoint script
. /usr/local/bin/docker-entrypoint.sh
_main "$@"
