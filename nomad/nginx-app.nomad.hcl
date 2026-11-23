variable "image_tag" {
  type        = string
  description = "Image tag to deploy (commit SHA published by CI)"
}

job "nginx-app" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel     = 1
    min_healthy_time = "10s"
    healthy_deadline = "2m"
    auto_revert      = true
  }

  group "web" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    reschedule {
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "10m"
      unlimited      = true
    }

    service {
      name = "nginx-app"
      port = "http"

      check {
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "ghcr.io/arowz-tach/devops-intern-final-v2:${var.image_tag}"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
