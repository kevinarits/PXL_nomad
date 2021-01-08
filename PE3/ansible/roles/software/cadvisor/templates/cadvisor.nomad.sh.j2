job "cadvisor" {
  datacenters = ["dc1"]
  type = "service"

  group "cadvisor" {

    task "cadvisor" {
      driver = "docker"

      config {
        image = "google/cadvisor"
                force_pull = true
                port_map = {
                  cadvisor_web = 8080
                }
                logging {
                  type = "journald"
                  config {
                    tag = "CADVISOR"
                 }
                }
      }

          service {
            name = "cadvisor"
            port = "cadvisor_web"
          }

      resources {
        network {
          port "cadvisor_web" {
            static = "8080"
          }
        }
      }
    }
  }
}
