job "alertmanager" {
  datacenters = ["dc1"]
  type = "service"
  
  group "alertmanager" {
  
    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager"
		force_pull = true
		port_map = {
		  alertmanager_web = 9093
		} 
		logging {
		  type = "journald"
		  config {
		    tag = "ALERTMANAGER"
		 }
		}	
      }
	  
	  service {
	    name = "alertmanager"
	    port = "alertmanager_web"
	  } 

      resources {
        network {
          port "alertmanager_web" {
            static = "9093"
          }
        }
      }
    }
  }
}