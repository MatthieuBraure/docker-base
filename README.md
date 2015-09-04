# A minimal Ubuntu base image modified for EVEN MORE Docker-friendliness

[![](https://badge.imagelayers.io/sys42/docker-base:latest.svg)](https://imagelayers.io/?images=sys42/docker-base:latest 'Get your own badge on imagelayers.io')

**sys42/docker-base** is a special [Docker](https://www.docker.com) image that is configured for correct use within Docker containers. It is Ubuntu, plus:

 * Modifications for Docker-friendliness.
 * Administration tools that are especially useful in the context of Docker.
 * Mechanisms for easily running multiple processes, [without violating the Docker philosophy](#docker_single_process).

You can use it as a base for your own Docker images.

sys42/docker-base is available for pulling from [the Docker registry](https://hub.docker.com/r/sys42/docker-base/).

-----------------------------------------------------------------------

**If you are wondering:** No, I haven't done all that work, but the talented people from [Phusion](https://www.phusionpassenger.com/) have done it. 

But [Their base image](https://github.com/phusion/baseimage-docker) has - at least for me - exactly two drawbacks:

  1. It doesn't come with an integrated default user.
  2. It doesn't provide a mechanism to remap the uid/gid of an internal user to match the uid/gid of an external user.

### Extension 1: An integrated default user

To be useful by itself out-of-the-box a default user is required. Unless it's really necessary you never ever want to run processes in a container as root. To me it make sense, that a default user is part of the base image:

  * it will be required by almost all images extending the base image
  * it doesn't take much space at all (a few bytes for the home directory)
  * it won't interfere with any possible extensions
  * the base image itself becomes useful itself without breaking the "dont-run-as-root" rule

So here we are:

setting  | value
-------- | -----
username | app
uid      | 1000
group    | app
gid      | 1000
password | -- none set ---
home dir | /home/app

**example usage:**

```shell
## starts a container in interactive mode and with running init system and removes it when done 
docker run -ti --rm sys42/docker-base:1.0.0 \
       my_init -- setuser app bash 
```

### Extension 2: Dynamic UID/GID re-mapping during container startup

When it comes down to file permissions all that matters are the numeric user id (uid) and the numeric group id (gid). It doesn't matter how the user is named or if he "lives" in a container or on the host. If the uid/gid of a container user matches the uid/gid of an external user he can modify the files, otherwise probably not (depending on the exact file permissions).

Suppose you have some project directory and want to use a Docker container like a tool to process some files and generate others. Let's say there is a complete compiler/build environment in the container which doesn't exists outside. 

By mounting the project directory into the container, you are ready to go. Let's try it:

```shell
## starts a container, mounts current directory to /project and executes make as user app
docker run -ti --rm -v "$(pwd):/project" a-cool-builder-image:1.0.0 \
       my_init -- setuser app bash -c "cd /project; make"
```

In almost all cases this will fail completely, because user 'app' has uid/gid of 9999/9999 which will probably have no write access to the current working directory. And what's a compiler/build environment good for, when it cannot produce some output? ;)

**UPDATE:** user app uses now (v1.1.0) uid 1000 and gid 1000, so the above run may execute without problems on many systems. Nevertheless these settings may be not correct for your system.

That's where this second extension comes into play. All it does is to reconfigure the internal user that it matches a given uid/gid combination. So let's try again:

```shell
## starts a container, mounts current directory to /project, changes uid/gid of
## user app to match external user and executes make as user app
docker run -ti --rm -v "$(pwd):/project" a-cool-builder-image:1.0.0 \
       my_init -- remapuser app $(id -u) $(id -g) bash -c "cd /project; make"
```

Voila! Mission accomplished. 

**IMPORTANT NOTES:**

The re-mapping feature is based on command `usermod`. This command automatically remaps files in the home directory and below which belongs to the user to match the new uid. This can lead to very unexpected file modifications when you mount external volumes below the home directory!

**LESSION LEARNED:** Never ever mount external volumes into (below) a home directory! (better to be on the safe side ;)

Additionally: user app is generated with **NO PASSWORD** set.


### Testing

To test the remapping feature (and implicit also the default user) there is a script in the tests folder called `run-tests.sh`. To execute the tests the script needs root priviledges, because it generates files and directories for different users including root itself.

```shell
## must be executed from within tests directory
sudo ./run-tests.sh
```

