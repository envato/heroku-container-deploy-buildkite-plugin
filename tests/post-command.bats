#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment the following line to debug stub failures
# export DOCKER_STUB_DEBUG=/dev/tty
# export CURL_STUB_DEBUG=/dev/tty

@test "Docker logout" {
  stub docker \
    "logout registry.heroku.com : exit 0"

  run "$PWD/hooks/post-command"

  assert_success

  unstub docker
}

