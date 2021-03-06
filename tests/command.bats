#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# Uncomment the following line to debug stub failures
# export DOCKER_STUB_DEBUG=/dev/tty
# export CURL_STUB_DEBUG=/dev/tty

@test "By process type pulls, tags and pushes to heroku" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release registry.heroku.com/my-app/release:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/release:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id" \
    "inspect registry.heroku.com/my-app/release:latest --format={{.Id}} : echo release_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\,\{\"type\"\:\"release\"\,\"docker_image\"\:\"release_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  refute_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  refute_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release as registry.heroku.com/my-app/release:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/release:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Inspected registry.heroku.com/my-app/release:latest identified as release_id"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "By process type finds, tags and pushes to heroku" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_KEY_NAME=MY_HEROKU_KEY
  export HEROKU_API_KEY=irrelevant
  export MY_HEROKU_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : echo web" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : echo release" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release registry.heroku.com/my-app/release:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/release:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id" \
    "inspect registry.heroku.com/my-app/release:latest --format={{.Id}} : echo release_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\,\{\"type\"\:\"release\"\,\"docker_image\"\:\"release_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  refute_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  refute_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release as registry.heroku.com/my-app/release:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/release:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Inspected registry.heroku.com/my-app/release:latest identified as release_id"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Single process type pulls, tags and pushes to heroku" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : echo web" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Supports deprecated process type attributes" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPES="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : echo web" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Supports skipping formation patch per proc type" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="worker:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_2="migrations:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_RELEASING_0=web
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_RELEASING_1=worker
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker registry.heroku.com/my-app/worker:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations registry.heroku.com/my-app/migrations:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/worker:latest : exit 0" \
    "push registry.heroku.com/my-app/migrations:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id" \
    "inspect registry.heroku.com/my-app/worker:latest --format={{.Id}} : echo worker_id" \
    "inspect registry.heroku.com/my-app/migrations:latest --format={{.Id}} : echo migrations_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\},\{\"type\"\:\"worker\"\,\"docker_image\"\:\"worker_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker"
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  refute_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  refute_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker"
  refute_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker as registry.heroku.com/my-app/worker:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations as registry.heroku.com/my-app/migrations:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/worker:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/migrations:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Inspected registry.heroku.com/my-app/worker:latest identified as worker_id"
  assert_output --partial "Skipping inspected registry.heroku.com/my-app/migrations:latest identified as migrations_id"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Exits gracefully if all proc types are skipped" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES="migrations:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_RELEASING=web
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations : echo migrations" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations registry.heroku.com/my-app/migrations:latest : exit 0" \
    "push registry.heroku.com/my-app/migrations:latest : exit 0" \
    "inspect registry.heroku.com/my-app/migrations:latest --format={{.Id}} : echo migrations_id"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations as registry.heroku.com/my-app/migrations:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/migrations:latest"
  assert_output --partial "Skipping inspected registry.heroku.com/my-app/migrations:latest identified as migrations_id"
  assert_output --partial "There aren't images to release"
  refute_output --partial "Version 100 is current"

  unstub docker
}

@test "Skips formation patch for migrations proc type by default" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="migrations:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations registry.heroku.com/my-app/migrations:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/migrations:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id" \
    "inspect registry.heroku.com/my-app/migrations:latest --format={{.Id}} : echo migrations_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  refute_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  refute_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-migrations as registry.heroku.com/my-app/migrations:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/migrations:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Skipping inspected registry.heroku.com/my-app/migrations:latest identified as migrations_id"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Polls heroku releases, until success" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token
  export RETRY_SLEEP=0

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : echo web" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false\}\]' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false\}\]' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Polls heroku releases, until fail" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token
  export RETRY_SLEEP=0

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : echo web" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false\}\]' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false\}\]' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"failed\",\"current\":false\}\]'

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  refute_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Stream heroku release output" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token
  export RETRY_SLEEP=0

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : echo release" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release registry.heroku.com/my-app/release:latest : exit 0" \
    "push registry.heroku.com/my-app/release:latest : exit 0" \
    "inspect registry.heroku.com/my-app/release:latest --format={{.Id}} : echo release_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"release\"\,\"docker_image\"\:\"release_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false,\"output_stream_url\":\"release_output_stream_url\"\}\]' \
    '-sf release_output_stream_url -H "Accept: text/event-stream" : echo "id: 1" && echo "data: Release Output"' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false,\"output_stream_url\":\"release_output_stream_url\"\}\]' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true,\"output_stream_url\":\"release_output_stream_url\"\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release as registry.heroku.com/my-app/release:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/release:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/release:latest identified as release_id"
  assert_output --partial "data: Release Output"
  refute_output --partial "Continuing without streaming release output"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Continue polling when stream heroku release output fails" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token
  export RETRY_SLEEP=0

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : echo release" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release registry.heroku.com/my-app/release:latest : exit 0" \
    "push registry.heroku.com/my-app/release:latest : exit 0" \
    "inspect registry.heroku.com/my-app/release:latest --format={{.Id}} : echo release_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"release\"\,\"docker_image\"\:\"release_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 0' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false,\"output_stream_url\":\"release_output_stream_url\"\}\]' \
    '-sf release_output_stream_url -H "Accept: text/event-stream" : exit 1' \
    '-sf release_output_stream_url -H "Accept: text/event-stream" : exit 1' \
    '-sf release_output_stream_url -H "Accept: text/event-stream" : exit 1' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"pending\",\"current\":false,\"output_stream_url\":\"release_output_stream_url\"\}\]' \
    '-sf https://api.heroku.com/apps/my-app/releases -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3" -H "Range: version ..; max=1, order=desc" -H "Authorization: Bearer api-token" : echo \[\{\"id\"\:\"app_id\",\"version\":100,\"status\"\:\"succeeded\",\"current\":true,\"output_stream_url\":\"release_output_stream_url\"\}\]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Found XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release as registry.heroku.com/my-app/release:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/release:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/release:latest identified as release_id"
  assert_output --partial "Continuing without streaming release output"
  assert_output --partial "Version 100 is current"

  unstub docker
  unstub curl
}

@test "Fails when an image pull fails" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token
  export RETRY_SLEEP=0

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 1" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 1" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 1"

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Failed pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"

  unstub docker
}

@test "Fails when docker login fails" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 1"

  run "$PWD/hooks/command"

  assert_failure

  unstub docker
}

@test "Fails when docker login fails with specified key" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_KEY_NAME=MY_HEROKU_KEY
  export HEROKU_API_KEY=irrelevant
  export MY_HEROKU_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 1"

  run "$PWD/hooks/command"

  assert_failure

  unstub docker
}

@test "Fails when an image push fails" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token
  export RETRY_SLEEP=0

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release registry.heroku.com/my-app/release:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/release:latest : exit 1" \
    "push registry.heroku.com/my-app/release:latest : exit 1" \
    "push registry.heroku.com/my-app/release:latest : exit 1"

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release as registry.heroku.com/my-app/release:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Failed push registry.heroku.com/my-app/release:latest"

  unstub docker
}


@test "Fails release image lookup" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release registry.heroku.com/my-app/release:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/release:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id" \
    "inspect registry.heroku.com/my-app/release:latest --format={{.Id}} : exit 1"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\,\{\"type\"\:\"release\"\,\"docker_image\"\:\"release_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 1'

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release as registry.heroku.com/my-app/release:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/release:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  refute_output --partial "Inspected registry.heroku.com/my-app/release:latest identified as release_id"
  refute_output --partial "Version 100 is current"

  unstub docker
}

@test "Fails releasing" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_0="web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_PROCESS_TYPE_IMAGES_1="release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_APP=my-app
  export HEROKU_API_KEY=api-token

  stub docker \
    "login --username=_ --password-stdin registry.heroku.com : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web : exit 0" \
    "images -q XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "pull XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web registry.heroku.com/my-app/web:latest : exit 0" \
    "tag XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release registry.heroku.com/my-app/release:latest : exit 0" \
    "push registry.heroku.com/my-app/web:latest : exit 0" \
    "push registry.heroku.com/my-app/release:latest : exit 0" \
    "inspect registry.heroku.com/my-app/web:latest --format={{.Id}} : echo web_id" \
    "inspect registry.heroku.com/my-app/release:latest --format={{.Id}} : echo release_id"

  stub curl \
    '-sf -X PATCH https://api.heroku.com/apps/my-app/formation -d \{\"updates\"\:\[\{\"type\"\:\"web\"\,\"docker_image\"\:\"web_id\"\}\,\{\"type\"\:\"release\"\,\"docker_image\"\:\"release_id\"\}\]\} -H "Content-Type: application/json" -H "Accept: application/vnd.heroku+json; version=3.docker-releases" -H "Authorization: Bearer api-token" -o /dev/null : exit 1'

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web"
  assert_output --partial "Pulled XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web as registry.heroku.com/my-app/web:latest"
  assert_output --partial "Tagged XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release as registry.heroku.com/my-app/release:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/web:latest"
  assert_output --partial "Pushed registry.heroku.com/my-app/release:latest"
  assert_output --partial "Inspected registry.heroku.com/my-app/web:latest identified as web_id"
  assert_output --partial "Inspected registry.heroku.com/my-app/release:latest identified as release_id"
  refute_output --partial "Version 100 is current"

  unstub docker
}

@test "Missing Heroku API Key" {
  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Missing heroku api key. Required HEROKU_API_KEY or \"key-name\""
}

@test "Missing Heroku API Key when specified" {
  export BUILDKITE_PLUGIN_HEROKU_CONTAINER_DEPLOY_KEY_NAME=MY_HEROKU_KEY
  export HEROKU_API_KEY=irrelevant

  run "$PWD/hooks/command"

  assert_failure
  assert_output --partial "Missing heroku api key. Required HEROKU_API_KEY or \"key-name\""
}
