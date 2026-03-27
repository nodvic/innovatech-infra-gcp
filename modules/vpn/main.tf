resource "google_compute_router" "hub_router" {
  name    = "innovatech-router-hub-${var.environment}"
  project = var.project_id
  region  = var.region
  network = var.hub_network_id

  bgp {
    asn = var.hub_router_asn
  }
}

resource "google_compute_ha_vpn_gateway" "hub_gateway" {
  name    = "innovatech-vpn-gw-hub-${var.environment}"
  project = var.project_id
  region  = var.region
  network = var.hub_network_id
}

resource "google_compute_external_vpn_gateway" "peer_gateway" {
  name            = "innovatech-vpn-peer-gw-${var.environment}"
  project         = var.project_id
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = var.peer_gateway_ip_0
  }

  interface {
    id         = 1
    ip_address = var.peer_gateway_ip_1
  }
}

resource "google_compute_vpn_tunnel" "tunnel_0" {
  name                            = "innovatech-vpn-tunnel-0-${var.environment}"
  project                         = var.project_id
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.hub_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.peer_gateway.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.vpn_shared_secret
  router                          = google_compute_router.hub_router.id
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel_1" {
  name                            = "innovatech-vpn-tunnel-1-${var.environment}"
  project                         = var.project_id
  region                          = var.region
  vpn_gateway                     = google_compute_ha_vpn_gateway.hub_gateway.id
  peer_external_gateway           = google_compute_external_vpn_gateway.peer_gateway.id
  peer_external_gateway_interface = 1
  shared_secret                   = var.vpn_shared_secret
  router                          = google_compute_router.hub_router.id
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "interface_0" {
  name       = "innovatech-vpn-iface-0-${var.environment}"
  project    = var.project_id
  region     = var.region
  router     = google_compute_router.hub_router.name
  ip_range   = var.router_interface_0_ip
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_0.name
}

resource "google_compute_router_interface" "interface_1" {
  name       = "innovatech-vpn-iface-1-${var.environment}"
  project    = var.project_id
  region     = var.region
  router     = google_compute_router.hub_router.name
  ip_range   = var.router_interface_1_ip
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_1.name
}

resource "google_compute_router_peer" "peer_0" {
  name                      = "innovatech-vpn-bgp-peer-0-${var.environment}"
  project                   = var.project_id
  region                    = var.region
  router                    = google_compute_router.hub_router.name
  peer_ip_address           = var.bgp_peer_ip_0
  peer_asn                  = var.peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface_0.name
}

resource "google_compute_router_peer" "peer_1" {
  name                      = "innovatech-vpn-bgp-peer-1-${var.environment}"
  project                   = var.project_id
  region                    = var.region
  router                    = google_compute_router.hub_router.name
  peer_ip_address           = var.bgp_peer_ip_1
  peer_asn                  = var.peer_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.interface_1.name
}
