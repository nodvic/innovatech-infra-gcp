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
}

module "vpn" {
  source = "../../modules/vpn"

  project_id        = var.project_id
  region            = var.region
  environment       = var.environment
  hub_network_id    = module.network.hub_network_id
  peer_gateway_ip_0 = var.peer_gateway_ip_0
  peer_gateway_ip_1 = var.peer_gateway_ip_1
  vpn_shared_secret = var.vpn_shared_secret
}

resource "google_compute_instance" "test_vm" {
  name         = "soar-test-vm-prod"
  machine_type = "e2-micro"
  zone         = "${var.region}-b"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    # Gebruik de output van de netwerkmodule voor consistentie
    network    = module.network.spoke_network_name
    subnetwork = module.network.spoke_subnet_name

    access_config {
      # Noodzakelijk voor een extern IP zodat je vanaf je eigen laptop kunt SSH'en
    }
  }

  # Installatie van de Ops Agent is essentieel voor de 'auth.log' doorstroom
  metadata_startup_script = <<-EOT
    #!/bin/bash
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
  EOT

  service_account {
    # De VM heeft minimaal de rol 'roles/logging.logWriter' nodig
    # 'cloud-platform' scope staat dit toe mits het Service Account de rechten heeft
    scopes = ["cloud-platform"]
  }
}
