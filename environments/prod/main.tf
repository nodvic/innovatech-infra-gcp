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

module "gke" {
  source           = "../../modules/gke"
  project_id       = var.project_id
  environment      = var.environment
  zone             = var.zone
  spoke_network_id = module.network.spoke_network_id
  gke_subnet_id    = module.network.gke_subnet_id
}
