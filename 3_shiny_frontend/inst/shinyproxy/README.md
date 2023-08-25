# For deployment with Shinyproxy

build docker image from this directory with 
docker build -t shinyproxy .

create network with 
docker network create sp-net

run container with 
sudo docker run --restart always -v /var/run/docker.sock:/var/run/docker.sock:ro --group-add $(getent group docker | cut -d: -f3) --net sp-net -p 8080:8080
shinyproxy
