module "network" {
  source = "../../modules/network"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

module "security" {
  source = "../../modules/security"

  project_id         = var.project_id
  environment        = var.environment
  hub_network_name   = module.network.hub_network_name
  spoke_network_name = module.network.spoke_network_name
}

module "database" {
  source = "../../modules/database"

  project_id                         = var.project_id
  region                             = var.region
  environment                        = var.environment
  spoke_network_id                   = module.network.spoke_network_id
  private_service_connect_connection = module.network.private_service_connect_connection
  db_password                        = var.db_password
}

module "dns" {
  source = "../../modules/dns"

  project_id          = var.project_id
  environment         = var.environment
  hub_network_id      = module.network.hub_network_id
  spoke_network_id    = module.network.spoke_network_id
  database_private_ip = module.database.private_ip_address
}

module "soar" {
  source = "../../modules/soar"

  project_id         = var.project_id
  region             = "europe-west1"
  zone               = var.zone
  environment        = var.environment
  spoke_network_name = module.network.spoke_network_name
  hub_network_name   = module.network.hub_network_name
  db_connection_name = module.database.instance_connection_name
  db_name            = module.database.database_name
  db_password        = var.db_password
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_id                = var.project_id
  environment               = var.environment
  soar_webhook_function_url = module.soar.soar_handler_function_url
  alert_email               = var.alert_email
}

module "vdi" {
  source           = "../../modules/vdi"
  project_id       = var.project_id
  environment      = var.environment
  zone             = var.zone
  spoke_network_id = module.network.spoke_network_id
  vdi_subnet_id    = module.network.vdi_subnet_id
}

module "gke" {
  source           = "../../modules/gke"
  project_id       = var.project_id
  environment      = var.environment
  zone             = var.zone
  spoke_network_id = module.network.spoke_network_id
  gke_subnet_id    = module.network.gke_subnet_id
}

resource "kubernetes_deployment" "hr_portal" {
  depends_on = [module.gke]
  metadata {
    name = "hr-portal"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "hr-portal"
      }
    }
    template {
      metadata {
        labels = {
          app = "hr-portal"
        }
      }
      spec {
        container {
          image = "nginxdemos/hello"
          name  = "hr-portal-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hr_portal_svc" {
  depends_on = [kubernetes_deployment.hr_portal]
  metadata {
    name = "hr-portal-svc"
  }
  spec {
    selector = {
      app = "hr-portal"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}
