# Teleport connections from Docker on Windows
## Difficulties
* Docker does not run natively/reliably on Windows.
* We have to use WSL to be able to develop/use dockerized apps. As of this writing, we are using WSL2
* Teleport creates proxied tunnels from secured Infra to a Developer's `localhost:<PORT>`
* WSL2 runs Linux (Ubuntu by default) in a separate VM under Windows, and routes networking traffic from Host (Win) to Client (WSL). Therefore, "localhost" on Host != "localhost" in WSL.
  1. From WSL, we must use `Windows' Host's IP` address instead of "localhost" when connecting to Teleported resource, for example a database. `Host IP` is dynamic and is assigned randomly, so to make it easier to connect, we will create an Alias for it in `/etc/hosts` in WSL. This alias must be checked/updated every time before we establish a connection to a Teleported resource.
  2. WSL must be able to send packets between itself and the Host freely. Must add a firewall rule to allow (all) traffic.
  3. Teleported `localhost:<PORT>` is not visible under WSL, because it is NOT coming from Host's localhost. Must proxy the port to allow to connect to it from somewhere other than localhost.

## Working Solution
These are the routine steps to be executed EVERY TIME when one wishes to connect to a Teleported resource:
1. On Windows (Host), run Teleport Connect GUI as usual, providing credentials to log in.
2. In Teleport Connect, activate any tunnels as needed; make a note of the `<PORT>` to which they are tunneled to, because we will need it to establish a connection from WSL/Docker.
3. In WSL, run the provided `./teleport.sh` script which will fix the 3 steps from `Difficulties`, above. This script requires `sudo`, so it will ask for your Linux password, and then also Windows Admin authorization to establish Firewall rules and Port Proxies.
4. Done! Connect to the Teleported resource(s) in WSL via the `teleport:<PORT>`. Plz note that instead of "localhost", use the Alias for **Windows Host** that was created in `/etc/hosts`: ie `teleport` by default. (Plz see the .env.sample for a simple example.) However, when connecting from Windows-based apps (ie anywhere NOT from WSL), then we still use the `localhost:<PORT>` as usual.
5. To establish a connection from a dockerized app, there is yet another layer of networking to break through. Because by default, the "localhost" of a docker container != "localhost" of the Host (this time, "Host" is the WSL Linux.) and we need to bridge them. There is an easy way, and a more intricate, difficult way. We will use the easy way because this is only a development set up, after all: in the Docker running args, we will use `--network host` to force Docker to just use the Host's (WSL's) network. A `docker-compose.yml` style of usage is also provided in this sample repo.


**Note 1:** If you establish/change a new connection in Teleport Connect, need to re-run the `./teleport.sh` again, so it will check and route any new ports to be visible from WSL for connection.
**Note 2:** `./teleport.sh` is written conservatively, so it won't create a bunch of dangling port proxies, firewall rules, or records in `/etc/hosts`. It cleans up all of these items each time it runs.


## Sample Dockerized python script
### First, build it
`docker build . -f Dockerfile -t teleport-python:latest`


### Run it with `host network`
We need to make sure to use the host computer's networking in order to be able to see the teleport tunnels via (host's, not docker's) localhost:

`docker run --rm -itd --volume $(pwd):/app --env-file .env --network host --name teleport-python teleport-python:latest`
https://docs.docker.com/network/network-tutorial-host/#procedure

### If the container is already running, one-liner to stop/remove it:

`CONTAINER=teleport-python; docker stop $CONTAINER && docker rm $CONTAINER`

### Alternatively, can use a docker-compose.yml

`docker-compose up` to start the container

`docker-compose down` to stop it

### After the container is up
try running `main.py`:

`docker exec -it teleport-python python _main_.py`
