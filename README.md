# ssync
`ssync` is a zero dependency,  bi-directional , containerized source code synchronizer. It enables you to work around slow bind when using  Docker for Mac. `ssync` will give you native speed when accessing files on your host from a container.

## Usage
### Basics
`ssync` uses the [Unison File Synchronizer](https://www.cis.upenn.edu/~bcpierce/unison/)  under the hood to synchronize files and folders between your local file-system and a Docker volume. 
Containers that need access to the files can simply mount the volume and read/write files with native speed.

`ssync` expects the following mounts:
* Mount your source code via a bind mount to `/host`. Make sure to use the `cached` option to speed up access to the files.
* Mount a named volume to `/container`. Unison will synchronize `/host` and `/container` - in other words this volume will contain the source code. Make sure to use the `nocopy` option to prevent existing files to be copied from your image to the volume. Otherwise you run into the risk of getting synchronization conflicts or lost files.
* Add another volume that will hold the synchronization state to `/unison_data`

`ssync`  supports two modes - `run` and `watch`.:
* `run` performs a one time synchronizations and should be used for the initial synchronization
* `watch` will watch for filesystem changes and trigger a synchronization for every change

It is recommended to  run an initial synchronization before running `ssync` in /watch/ mode for the first time.

### Example `docker-compose.yaml`
```yaml
version: '3.7'

services:
  ssync:
    image: ssync/ssync:0.3.1
    volumes:
       # The bind mount to give ssync access to the local copy of your source code 
      - ./:/host:cached
      # The volume that will hold 
      - code:/container:nocopythe source code - other services should mount this volume for source code access.
      # The unison synchronization state data
      - unison:/unison_data
    command: ["watch"]          # Set the mode to `watch` 
    environment:
      # Set additional unison flags
      - UNISON_OPTS=-ignore "Path tmp"

  # Define one or more services that will access the source code via the synchrtonized volume.
  app:
    image: myapp:development
    build: .
    volumes:
       # The volume containing the src code
      - code:/usr/src/app:nocopy

# Volume definitions
volumes:
  code:
  unison:
```

You can kick of the initial synchronization with
```
docker-compose run ssync run
```

And then start the service to keep synchtronizing  changes

### Supported environment variables
* `UNISON_OPTS `: Allows you to specify additional [preferences](https://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#prefs ) for Unison.  The default is none.
* `SYNC_UID`: Use this environment variable to change the user id that is used to run Unison. You might want to set this to the same user id that you use to run your application inside the container. The default is user id 0 (root)
* `MONIT_ENABLED`: Enable or disable monitoring the Unison process via Monit [see Known issues](#known-issues). The default is  `true`.
* `MONIT_CHECK_INTERVAL`: Specifies the check interval for Monit in seconds. Default is `1`.
`MONIT_HIGH_CPU_THRESHOLD`: Defines the threshold for the cpu usage of Unison in percentage. The default is `60`
`MONIT_HIGH_CPU_CYCLES`: The number of cycles for which the cpu usage needs to be above the threshold before Monit will restart Unison.

### Keeping the `ssync` service separate
It might make sense to keep the configuration of `ssync` separate to not interfere or change the development experience on Linux and Windows machines.

Just place create a separate Docker Compose config for the `ssync` service., volumes and bind mount for the application:

* `docker-compose.yaml`
  ```yaml
  services:
    app:
      image: myapp:development
      build: .
      volumes:
        - ./:/usr/src/app
  ```

* `docker-compose.ssync.yaml`
  ```yaml
  services:
    app:
      volumes:
        - code:/usr/src/app:nocopy # We override the bind mount here and use the volume instead

    ssync:
      image: ssync/ssync:0.3.1
      volumes:
        - ./:/host:cached
        - code:/container:nocopy
        - unison_data:/unison_data

  volumes:
    code:
    unison_data:
  ```

You can then reference this file when starting Docker Compose either
* via the command line:
  ```
  docker-compose -f docker-compose.yaml -f docker-compose.ssync.yaml up -d
  ```
* by setting the `COMPOSE_FILE` environment variable
  ```
  COMPOSE_FILE=docker-compose.yaml:docker-compose.ssync.yaml
  ```
I usually set `COMPOSE_FILE` in my `.env` file. Docker Compose will automatically pick it up and you can just run
  ```
  docker-compose up -d
  ```

### Synchronizing multiple directories
You can synchronize multiple directories by adding multiple services for `ssync`. Make sure to assign  


## Known issues
Under certain circumstances, the Unison process might stop working and consume almost 100% of a CPU. This seems to happen when a lot of file system changes happen in a very short time - for example when switching between git branches.

To work around this issue, `ssync` uses Monit. Monit will watch the Unison process and restart it if the CPU load is above a certain threshold for long enough. The default is 5 seconds. You can use the `MONIT_ENABLED`, `MONIT_HIGH_CPU_THRESHOLD`, and `MONIT_HIGH_CPU_CYCLES` environment variables to change this behavior.

## Alternatives
Check out [docker-sync by EugenMayer](http://docker-sync.io/) or  [Crane](https://www.crane-orchestration.com) if you are looking for an alternative to `ssync`

## Development
Fork this repo, do your work and create a PR.

#### Upcoming features
* Add an option to set the `prefer` option for unison to decide whether the host or container should win in case of conflicts
* Specify files and directories to exclude via environment variables
* Add an option to automatically exclude version control files
* Validate settings on startup

#### Testing
Testing is currently done via a shell script. Run it via
```
./test.sh
```

The script ensures that files are correctly synchronized between the Docker Host and the Docker Volume.

I decided to go with.a shell script here because
* `ssync` has to be tested from the Docker Host and I didn’t want to introduce a lot of dependencies
* Speed and timing the file synchronization between the Host and Volume is depending on the Docker Host. This means that the test suite might be brittle and hence not worth spending too much effort into it
* I wanted something that is easy to debug and understand.  The script just executes shell commands and dumps all commands and their output onto the terminal.
