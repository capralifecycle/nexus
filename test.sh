#!/bin/sh
set -e

if [ -z "$1" ]; then
  echo "Syntax: $0 <nexus-image-id>"
  exit 1
fi

set -u

expected_version=$(grep 'ARG NEXUS_VERSION=' Dockerfile | sed 's/.*=//')
image_id="$1"

# Use unix time to simulate a random value, /dev/urandom is unstable in Nexus slave
run_id=$(date +%s | base64 | tr -dc 'a-zA-Z0-9' | fold -w 16)
network_name="nexus-test-$run_id"
echo "Docker network name: $network_name"

network_id=$(docker network create $network_name)
container_id=$(docker run -d --rm --network-alias=nexus --network $network_id "$image_id")

cleanup() {
  echo "Cleaning up resources"
  docker stop $container_id || :
  docker network rm $network_name || :
}

trap cleanup EXIT

max_wait=30
wait_interval=2
echo "Polling for Nexus to be up.. Trying for $max_wait iterations of $wait_interval sec"

ok=0
start=$(date +%s)
for x in $(seq 1 $max_wait); do
  if docker run -i --rm --network $network_id byrnedo/alpine-curl -fsS nexus:8081 >/dev/null; then
    ok=1
    break
  fi
  sleep $wait_interval
done

if [ $ok -eq 0 ]; then
  echo "Waiting for Nexus to boot failed"
  exit 1
fi

end=$(date +%s)
echo "Took $((end-start)) seconds for Nexus to boot up"

# Verify we have the expected version running
html=$(docker run -i --rm --network $network_id byrnedo/alpine-curl -fS nexus:8081)

if ! echo "$html" | grep -q "$expected_version"; then
  echo "Could not find expected version string: $expected_version"
  exit 1
else
  echo "Version $expected_version verified"
fi

# We can add more tests here if we want.
# Maybe we want to build assertions for the various endpoints
# we use in kinda hard-coded scripts running on remote hosts?
