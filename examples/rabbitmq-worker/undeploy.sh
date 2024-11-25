#!/bin/bash

print_in_color() {
  color=$1
  text=$2
  echo -e "\033[${color}m${text}\033[0m"
}

export "$(sed -n 's/^COMPOSE_PROJECT_NAME=\(.*\)/COMPOSE_PROJECT_NAME=\1/p' .env)"

print_in_color "33" "You are about to delete all containers, volumes, and networks created by Docker Compose."
print_in_color "31" "⚠️ WARNING : This will permanently delete all data!"
read -rp "$(print_in_color '37' 'Do you want to continue with this operation? (yes/no): ')" answer

if [ "$answer" != "yes" ]; then
  print_in_color "32" "Operation canceled by the user."
fi

containers=$(docker ps --filter "name=${COMPOSE_PROJECT_NAME}" -q)

if [ -z "$containers" ]; then
  print_in_color "32" "No active containers found for the project ${COMPOSE_PROJECT_NAME}."
else


  volumes=()
  for container in $containers; do
    container_volumes=$(docker inspect -f '{{ range .Mounts }}{{ .Name }} {{ end }}' "$container")
    # shellcheck disable=SC2206
    volumes+=($container_volumes)
  done
  docker-compose down #-v


  print_in_color "31" "Deleting volumes will result in the loss of all data saved by the containers."
  read -rp "$(print_in_color '33' 'Do you want to delete the listed volumes? (yes/no): ')" delete_volumes

  if [ "$delete_volumes" == "yes" ]; then
    for volume in "${volumes[@]}"; do
      docker volume rm "$volume"
    done
    print_in_color "32" "Volumes deleted successfully."
  else
    print_in_color "32" "Volumes were not deleted."
  fi


  read -rp "$(print_in_color '33' 'Do you want to image prune? Dangling images will be removed from your host (yes/no): ')" imageprune

  if [ "$imageprune" == "yes" ]; then
    docker image prune
    print_in_color "32" "Volumes directory deleted successfully."
  else
    print_in_color "32" "Volumes directory were not deleted."
  fi


  print_in_color "31" "Erasing the shared directory used by the volumes will definitely exclude any possibility of recovering the data generated by containers"
  read -rp "$(print_in_color '33' 'Do you want to delete the ./volumes directory? (yes/no): ')" delete_volumesdir

  if [ "$delete_volumesdir" == "yes" ]; then
    sudo rm -rf ./volumes
    print_in_color "32" "Volumes directory deleted successfully."
  else
    print_in_color "32" "Volumes directory were not deleted."
  fi

fi

print_in_color "32" "Operation completed."