job "grafana" {
  datacenters = ["dc1"]
  type = "service"
  
  group "grafana" {
  
    task "grafana" {
      driver = "docker"

      config {
        image = "grafana/grafana"
		force_pull = true
		port_map = {
		  grafana_web = 3000
		} 
		logging {
		  type = "journald"
		  config {
		    tag = "GRAFANA"
		 }
		}	
      }
	  
	  service {
	    name = "grafana"
	    port = "grafana_web"
	  } 

      resources {
        network {
          port "grafana_web" {
            static = "3000"
          }
        }
      }
    }
  }
}