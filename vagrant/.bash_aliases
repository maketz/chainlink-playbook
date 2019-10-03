# Boot up ETH client quickly
run_eth () {
    docker start -i eth
}

# Boot up chainlink node quickly
# Remember to wait for ETH client to boot&sync first, before entering
# credentials and booting up Chainlink
run_chainlink () {
    docker start -i chainlink
}

run_chainlink_secondary () {
    docker start -i secondary
}

stop_nodes() {
    docker stop chainlink && docker stop secondary
}

# Switch to main Chainlink node
# WARNING: USE WITH CAUTION
# BOTH NODES NEED TO BE UP AND RUNNING
switch_main () {
    docker restart secondary && docker attach chainlink
}

# Switch to secondary Chainlink node
# WARNING: USE WITH CAUTION
# BOTH NODES NEED TO BE UP AND RUNNING
switch_secondary () {
    docker restart chainlink && docker attach secondary
}

# Update main node
# WARNING: USE WITH CAUTION,
# BOTH NODES NEED TO BE UP AND RUNNING
update_nodes () {
    docker pull smartcontract/chainlink:latest
    docker kill chainlink
    docker start -i chainlink && docker restart secondary -t 0
    docker kill secondary
    docker start secondary -t 0
}

# For quick screen usage
alias chainlink='screen -S chainlink -c ~/.screenrc-chainlink -d -R'

# Navigation
alias home='cd ~'
alias vagrant='cd /vagrant'
