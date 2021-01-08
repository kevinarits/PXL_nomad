# Documentatie PE 3 - Prometheus, Grafana, Alertmanager... (Team 3)

In deze documentatie gaan wij onze configuratie laten zien van verschillende metrics en exporters in onze cluster.

## Prometheus

Om prometheus op te zetten in onze cluster hebben we ervoor gekozen om 1 file te maken waarin we alle configuratie meegeven. In principe is deze file onze nomad job alleen maar binnen deze file worden er ook 2 andere files aangemaakt en weggeschreven naar .yml bestanden. Eerst over de job, onze job 'prometheus' zal gewoon via docker een image pullen (prom/prometheus:latest) en deze openen op de 9090 poort. Natuurlijk zonder een prometheus.yml file kunnen we niet de scrape targets meegeven aan de prometheus. Dit doen we door een stukje code weg te schrijven naar local/prometheus.yml file met behulp van EOH. We geven hier mee dat de prometheus verschillende targets moet scrapen van de consul pagina of gewoon een IP. Alertmanager, nomad, nomad-client en cadvisor worden ingesteld zodanig dat er wordt gezocht op de consul naar de specifieke service. Deze service bezit alle metrics die nodig zijn voor onze prometheus. Ook node-exporter staat hierbij, alleen worden de metrics met behulp van een static target opgehaald. Buiten de prometheus.yml hebben we ook de cadvisor_alert.yml, deze hebben we ingesteld zodat wanneer onze cadvisor webpagina down gaat er een melding wordt verstuurd op alertmanager.

```
job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "prometheus" {
      template {
        change_mode = "noop"
        destination = "local/cadvisor_alert.yml"
        data = <<EOH
---
groups:
- name: prometheus_alerts
  rules:
  - alert: cadvisor down
    expr: absent(up{job="cadvisor"})
    for: 10s
    labels:
      severity: critical
    annotations:
      description: "Our cadvisor is down."
EOH
      }

      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

alerting:
  alertmanagers:
  - consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['alertmanager']

rule_files:
  - "cadvisor_alert.yml"

scrape_configs:

  - job_name: 'alertmanager'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['alertmanager']

  - job_name: 'nomad_metrics'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']

  - job_name: 'node_exporter'
    static_configs:
    - targets: ['192.168.1.3:9100']
  
  - job_name: 'cadvisor'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['cadvisor']

EOH
      }

      driver = "docker"

      config {
        image = "prom/prometheus:latest"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]

        port_map {
          prometheus_ui = 9090
        }
      }

      resources {
        network {
             port "prometheus_ui" {
             to = 9090
             static = 9090
             }

        }
      }
      service {
        name = "prometheus"
        tags = ["urlprefix-/"]
        port = "prometheus_ui"

        check {
          name     = "prometheus_ui port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
```

## Software roles (Grafana)
### Grafana handlers

In de handler van grafana geven we mee dat we deze als een nomad job gaan runnen. We roepen de grafana.nomad file op die aangemaakt wordt in het task gedeelte van grafana binnen Ansible. Deze handler wordt later gebruikt in tasks na het maken van de nomad job.

```
---
- name: start grafana job
  shell: nomad job run -address=http://192.168.1.2:4646/ /opt/nomad/grafana.nomad || exit 0
```

### Grafana tasks

In de tasks van grafana gaan we simpelweg een nomad job maken en deze stoppen in de /opt/nomad map. We halen de code van de job op in de template file die we hebben aangemaakt voor Grafana. Op het einde geven we nog mee met behulp van notify dat we de handler moeten uitvoeren om de job te starten.

```
---
- name: nomad job grafana 
  template: 
    src: grafana.nomad.sh.j2
    dest: /opt/nomad/grafana.nomad
  notify: start grafana job
```

### Grafana templates

In de template van Grafana geven we de configuratie mee die we in de nomad job stoppen bij de tasks van Grafana. We maken hier een grafana job met behulp van docker die de grafana/grafana image pulled. Deze wordt geopend op de 3000 poort. 

```
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
```

## Software roles (Alertmanager)
### Alertmanager handlers

In de handler van alertmanager geven we mee dat we deze als een nomad job gaan runnen. We roepen de alertmanager.nomad file op die aangemaakt wordt in het task gedeelte van alertmanager binnen Ansible. Deze handler wordt later gebruikt in tasks na het maken van de nomad job.

```
---
- name: start alertmanager job
  shell: nomad job run -address=http://192.168.1.2:4646/ /opt/nomad/alertmanager.nomad || exit 0
```

### Alertmanager tasks

In de tasks van alertmanager gaan we simpelweg een nomad job maken en deze stoppen in de /opt/nomad map. We halen de code van de job op in de template file die we hebben aangemaakt voor Alertmanager. Op het einde geven we nog mee met behulp van notify dat we de handler moeten uitvoeren om de job te starten.

```
---
- name: nomad job alertmanager 
  template: 
    src: alertmanager.nomad.sh.j2
    dest: /opt/nomad/alertmanager.nomad
  notify: start alertmanager job
```

### Alertmanager templates

In de template van Alertmanager geven we de configuratie mee die we in de nomad job stoppen bij de tasks van Alertmanager. We maken hier een alertmanager job met behulp van docker die de prom/alertmanager image pulled. Deze wordt geopend op de 9093 poort.

```
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
```

## Software roles (Node-exporter)
### Node-exporter handlers

In de handler van node-exporter geven we mee dat we deze als een nomad job gaan runnen. We roepen de node-exporter.nomad file op die aangemaakt wordt in het task gedeelte van node-exporter binnen Ansible. Deze handler wordt later gebruikt in tasks na het maken van de nomad job.

```
---
- name: start node-exporter job
  shell: nomad job run -address=http://192.168.1.2:4646/ /opt/nomad/node-exporter.nomad || exit 0
```

### Node-exporter tasks

In de tasks van node-exporter gaan we simpelweg een nomad job maken en deze stoppen in de /opt/nomad map. We halen de code van de job op in de template file die we hebben aangemaakt voor node-exporter. Op het einde geven we nog mee met behulp van notify dat we de handler moeten uitvoeren om de job te starten.

```
---
- name: nomad job node-exporter 
  template: 
    src: node-exporter.sh.j2
    dest: /opt/nomad/node-exporter.nomad
  notify: start node-exporter job
```

### Node-exporter templates

In de template van node-exporter geven we de configuratie mee die we in de nomad job stoppen bij de tasks van node-exporter. We maken hier een node-exporter job met behulp van docker die de prom/node-exporter image pulled. Deze wordt geopend op de 9100 poort.

```
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
```

## Software roles (Cadvisor)
### Cadvisor handlers

In de handler van Cadvisor geven we mee dat we deze als een nomad job gaan runnen. We roepen de Cadvisor.nomad file op die aangemaakt wordt in het task gedeelte van Cadvisor binnen Ansible. Deze handler wordt later gebruikt in tasks na het maken van de nomad job.

```
---
- name: start cadvisor job
  shell: nomad job run -address=http://192.168.1.2:4646/ /opt/nomad/cadvisor.nomad || exit 0

```

### Cadvisor tasks

In de tasks van cadvisor gaan we simpelweg een nomad job maken en deze stoppen in de /opt/nomad map. We halen de code van de job op in de template file die we hebben aangemaakt voor cadvisor. Op het einde geven we nog mee met behulp van notify dat we de handler moeten uitvoeren om de job te starten.

```
---
- name: nomad job cadvisor 
  template: 
    src: cadvisor.nomad.sh.j2
    dest: /opt/nomad/cadvisor.nomad
  notify: start cadvisor job
```

### Cadvisor templates

In de template van cadvisor geven we de configuratie mee die we in de nomad job stoppen bij de tasks van cadvisor. We maken hier een cadvisor job met behulp van docker die de google/cadvisor image pulled. Deze wordt geopend op de 8080 poort.

```
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

```

## Grafana dashboards

In de grafana_dashboards folder op de github repository hebben we 2 dashboards gekozen die een goed overzicht geeft van de metrics van de nomad jobs alsook onze node_exporter metrics. Aan deze dashboards kunnen verschillende aanpassingen gedaan worden om ze nog meer aan te passen naar de wil van de gebruiker.

![node exporter grafana](https://user-images.githubusercontent.com/43812348/104042716-1e1f7d80-51db-11eb-9db2-f992d44b1251.png)

![nomad jobs grafana](https://user-images.githubusercontent.com/43812348/104042720-1eb81400-51db-11eb-8510-1c42c5fce811.png)

## Prometheus targets

Als we gaan kijken naar de Prometheus targets moeten we normaal alle services zien waar we de metrics van gaan ophalen.

![prometheus targets](https://user-images.githubusercontent.com/43812348/104042721-1f50aa80-51db-11eb-91bd-137fc109ac69.png)

## Taakverdeling

Tijdens het maken van de opdracht hebben wij voor het grootste gedeelte samengewerkt met behulp van screensharen op Teams.

## Bronvermelding

Slides Lessen

https://learn.hashicorp.com/tutorials/nomad/prometheus-metrics

https://prometheus.io/docs/instrumenting/exporters/#exporters-and-integrations

https://prometheus.io/docs/guides/node-exporter/

https://docs.docker.com/config/daemon/prometheus/
