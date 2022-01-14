#!/bin/bash

set -e
set -o xtrace

ORC_HOST=127.0.0.1:3000

lookup() {
    local host=$1
    dig +short "${host}"
}

main() {
    while read orc_host; do
        if [ -z "$orc_host" ]; then
            echo '[INFO] Could not find PEERS ...'
            exit 0
        fi

        # orc_host is a SRV record from headless service
        # cluster1-orc-0.cluster1-orc.<namespace>
        host=(${orc_host//./ })
        idx=${HOSTNAME: -1}
        peer_idx=${host[0]: -1}

        if [[ "$peer_idx" -le "$idx" ]]; then
            echo "[INFO] Peer index: ${peer_idx}, our index: ${idx}. Skipping"
            continue
        fi

        ip=$(lookup "${orc_host}")
        if curl -s "${ORC_HOST}/api/raft-peers" | grep "${ip}"; then
            echo "[INFO] ${orc_host} (${ip}) is already in raft peers. Skipping"
            continue
        fi

        # Restarting orchestrator to add new orc nodes to RaftNodes in entrypoint
        pkill -e -15 orchestrator || :
    done
}

main
