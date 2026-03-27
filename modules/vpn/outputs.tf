output "hub_router_name" {
  value = google_compute_router.hub_router.name
}

output "hub_router_id" {
  value = google_compute_router.hub_router.id
}

output "vpn_gateway_id" {
  value = google_compute_ha_vpn_gateway.hub_gateway.id
}

output "tunnel_0_name" {
  value = google_compute_vpn_tunnel.tunnel_0.name
}

output "tunnel_1_name" {
  value = google_compute_vpn_tunnel.tunnel_1.name
}
