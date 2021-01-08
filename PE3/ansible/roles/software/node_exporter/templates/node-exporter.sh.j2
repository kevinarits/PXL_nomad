job "node-exporter" {
  datacenters = ["dc1"]
  type = "service"
  
  group "node-exporter" {
  
    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter"
		force_pull = true
		port_map = {
		  node-exporter_web = 9100
		} 
		logging {
		  type = "journald"
		  config {
		    tag = "NODE-EXPORTER"
		 }
		}	
      }
	  
	  service {
	    name = "node-exporter"
	    port = "node-exporter_web"
	  } 

      resources {
        network {
          port "node-exporter_web" {
            static = "9100"
          }
        }
      }
    }
  }
}