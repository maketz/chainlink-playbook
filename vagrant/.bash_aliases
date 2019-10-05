# Boot up ETH client quickly
run_eth () {
    docker start -i eth
}

# Stop ETH client quickly
stop_eth () {
    docker start -i eth
}

# Boot up chainlink node quickly
# Remember to wait for ETH client to boot&sync first, before entering
# credentials and booting up Chainlink
run_chainlink () {
    docker start -i chainlink
}

# Stop main node quickly
stop_chainlink () {
    docker stop chainlink
}

# Boot up secondary chainlink node quickly
# Remember to wait for ETH client to boot&sync first, before entering
# credentials and booting up Chainlink
run_secondary () {
    docker start -i secondary
}

# Stop secondary node quickly
stop_secondary () {
    docker stop secondary
}

# Stop both nodes
stop_nodes() {
    docker stop chainlink && docker stop secondary
}

# For quick screen usage
alias chainlink='screen -S chainlink -c ~/.screenrc-chainlink -d -R'

# Navigation
alias home='cd ~'
alias vagrant='cd /vagrant'
