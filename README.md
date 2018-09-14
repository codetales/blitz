# SSync
SSync is zero-dependency synchronization tool for your source code.

SSync stands for _Source Synchronizer_. It is a project that helps overcoming the burden of slow bind-mounts when running Docker on MacOS.

## Why you need SSync
Docker is a great tool in many ways. People use it in many different ways, including the development of applications inside containers. While this generally works great, there can be a few caveats. One of them are slow bind-mounts when using Docker for Mac. This is due to the nature of XXX. Docker is working on improvements and things are a lot better these days, they are still far from optimal. SSync helps to overcome this usage by synchronizing the local directory with a Volume. The result is access to your files at native speed inside the container.

## How it works
Ssync uses (Unison)[] to synchronize files and folders between your local file-system and a Docker Volume. Containers that need access to the files can simply mount the Docker Volume. This allows your containers to access the files without being (slowed down by the osxfs driver)[] that is used for bind mounts.

There are no additional dependencies. SSync runs as a container and access your local files via a bind mount.

### Stats
On a typical rails application, this can result in a performance gain

## Usage
SSync runs as a container and can be configured via environment variables.

### Plain Docker example

### Docker Compose example
Add SSync to your `docker-compose.yml`:
```
syncer:
  image: ssync/ssync:0.2.1
  command: watch
  volumes:
    - ./:/src:cached
    - application-src:/dest
    - sync-data:/unison_data
  environment:
    - UNISON_OPTS=-ignore "Path .git" -ignore "Path tags*" -ignore "Name {.*,*}.sw[pon]"
```

Make sure to mount the `application-src` volume inside your containers that need access to the source code.

#### Performing a one time or initial synchronization
```
docker-compose run ssync
```

#### Reset and start over:
```

```

## Running as a different user
Ideally, you don't run as root inside your containers. SSync supports switching users to make sure that the synchronized files are owned by the correct user.

Simply set `USERID` environment variable to reflect the user id that is used inside your containers.

```
syncer:
  image: jfahrer/src-syncer:0.2.1
  command: watch
  volumes:
    - ./:/src:cached
    - ruby-web-src:/dest
    - sync-data:/unison_data
  environment:
    - USERID=1000
    - UNISON_OPTS=-ignore "Path .git" -ignore "Path tags*" -ignore "Name {.*,*}.sw[pon]"
```

## Supported environment variables
* UNISON_DATA
* USERNAME
* USERID

## Why not use docker-sync?
docker-sync works great. The `native_osx` strategy is similar to the technique SSync uses. Unlike docker-sync, SSync does not have any dependencies and does not require additional tools, setup or extra steps in your process. Everything runs inside a container and can be configured via environment variables.

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Cool opts
-force /src
-prefer newer
-silent
-copyonconflict
Complex configuration via preferences

Add the help option
