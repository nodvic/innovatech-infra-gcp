module "network" {
  source = "../../modules/network"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

module "vpn" {
  source = "../../modules/vpn"

  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  hub_network_id = module.network.hub_network_id
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

  project_id              = var.project_id
  region                  = "europe-west1"
  environment             = var.environment
  spoke_network_name      = module.network.spoke_network_name
  hub_network_name        = module.network.hub_network_name
  db_connection_name      = module.database.instance_connection_name
  db_name                 = module.database.database_name
  db_password             = var.db_password
  invoker_service_account = module.security.soar_service_account_email
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_id  = var.project_id
  environment = var.environment
}
