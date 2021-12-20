# Heroku Container Deploy

Deploy pre-built docker images, typically with [docker-compose-buildkite-plugin](https://github.com/buildkite-plugins/docker-compose-buildkite-plugin), to using the Heroku Container Registry. It follows the official recommended steps [for Docker deploys on Heroku](https://devcenter.heroku.com/articles/container-registry-and-runtime). See [ecr-buildkite-plugin](https://github.com/buildkite-plugins/ecr-buildkite-plugin) for authenticating with AWS ECR.

## Example

Deploy a pre-built images from ECR to heroku container registry.

```yml
steps:
  - label: ":heroku: Deploy my-app app (web)"
    plugins:
      - envato/heroku-container-deploy:
          app: my-app
          process-types:
            - web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web-${BUILDKITE_COMMIT}
```

Deploy multiple pre-built images from ECR to heroku container registry.

```yml
steps:
  - label: ":heroku: Deploy my-app app (web and worker)"
    plugins:
      - envato/heroku-container-deploy:
          app: my-app
          process-types:
            - web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web-${BUILDKITE_COMMIT}
            - worker:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker-${BUILDKITE_COMMIT}
```

Deploy multiple pre-built images including a [Release Phase](https://devcenter.heroku.com/articles/container-registry-and-runtime#release-phase) from ECR to heroku container registry. Plugin will stream the release output to Buildkite logs.

```yml
steps:
  - label: ":heroku: Deploy my-app app (web, worker and release)"
    plugins:
      - envato/heroku-container-deploy:
          app: my-app
          process-types:
            - web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web-${BUILDKITE_COMMIT}
            - worker:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker-${BUILDKITE_COMMIT}
            - release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release-${BUILDKITE_COMMIT}
```

## Configuration

Ensure that you have an `HEROKU_API_KEY` environment variable configured for your agent/repo.

### `app` (Required, string)

Heroku app name

### `process-types` (Required, Array of string)

List of process types and their image repository to deploy.

```
<proc-type>:<ecr>:<tag>
```

## Developing

Testing

```shell
docker-compose run --rm tests
```

Linting

```shell
docker-compose run --rm lint
```
