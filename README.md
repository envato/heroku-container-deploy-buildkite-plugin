# Heroku Container Deploy

## Example

```yml
steps:
  - label: ":heroku: Deployment"
    plugins:
      - envato/heroku-container-deploy:
          app: my-app
          process-types:
            - web:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-web-${BUILDKITE_COMMIT}
            - worker:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-worker-${BUILDKITE_COMMIT}
            - release:XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/my-repo:heroku-release-${BUILDKITE_COMMIT}
```

## Configuration

### `app` (Required, string)

Heroku app name

### `process-types` (Array of string)

List of process types and their image repository to deploy.

```
<proc-type>:<repo>:<tag>
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