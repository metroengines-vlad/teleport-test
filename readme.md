## Teleport connections from Docker


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
