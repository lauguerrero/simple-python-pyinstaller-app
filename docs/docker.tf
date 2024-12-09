#define la configuracion de terraform, especificamos proveedor de docker
#y su version
terraform {
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
            version = "~> 3.0.1"
        }
    }
}

#configuracion del proveedor
provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

#crea la imagen de docker de dind
resource "docker_image" "dind" {
  name         = "docker:dind"
  keep_locally = false
}

#define el volumen 
resource "docker_volume" "my_volume"{
 name = "my_volume"
 }

resource "docker_volume" "my_volume2"{
 name = "my_volume2"
 }

#define la red
 resource "docker_network" "my_network" {
 name = "my_network"
 }

#crea el contenedor de docker, realiza el mapeo de puertos e indica los volumenes que se van a usar, 
#y la red que se va a usar
resource "docker_container" "dind" {
  image = docker_image.dind.image_id
  name  = "docker-dind"

  ports {
    internal = 2375
    external = 2375
  }

  volumes {
    volume_name = docker_volume.my_volume.name
    container_path = "/certs/client"
  }

  volumes {
    volume_name = docker_volume.my_volume2.name
    container_path = "/var/jenkins_home"
  }

  networks_advanced {
    name    = docker_network.my_network.name
    aliases = ["docker"]
  }
}

#lo mismo para el contenedor de jenkins pero ademas este tiene variables de entorno
resource "docker_container" "jenkins" {
  image = "myjenkins-blueocean"
  name  = "jenkins-server"

  ports {
    internal = 8080
    external = 8081
  }
  env = [
    "DOCKER_HOST=tcp://docker:2376",
    "DOCKER_CERT_PATH=/certs/client",
    "DOCKER_TLS_VERIFY=1"
  ]

  volumes {
    volume_name = docker_volume.my_volume.name
    container_path = "/certs/client"
  }

  volumes {
    volume_name = docker_volume.my_volume2.name
    container_path = "/var/jenkins_home"
  }
  
  networks_advanced {
    name    = docker_network.my_network.name
    aliases = ["jenkins"]
  }
}