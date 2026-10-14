[English](02-architecture.en.md) | [日本語](02-architecture.md)

> This is an English translation added on 2026-10-14. The dates, data, and caveats of the original record are preserved. No new experiment was run for this translation.

# Azure Architecture

## Architecture Diagram

![Architecture diagram of the Azure validation environment](images/azure-architecture.png)

```mermaid
flowchart TB
    Client((Internet Client))

    subgraph Azure["Microsoft Azure / Japan East"]
        subgraph RG["Resource Group: rg-workload"]
            subgraph VNet["Virtual Network (10.1.0.0/16)"]
                subgraph Subnet_AG["AppGateway Dedicated Subnet (10.1.1.0/24)"]
                    AppGW["Application Gateway Standard_v2<br/>HTTP :80 (Public IP)<br/>Frontend / Health Probe"]
                    NSG_AG["NSG: Inbound Allow GatewayManager:65200-65535<br/>Inbound Allow Internet:80"]
                end

                subgraph Subnet_VM["Private Backend Subnet (10.1.2.0/24)"]
                    VM1["VM Web #1 (Zone 1)<br/>Ubuntu 24.04 + Nginx<br/>No Public IP"]
                    VM2["VM Web #2 (Zone 2)<br/>Ubuntu 24.04 + Nginx<br/>No Public IP"]
                    NSG_VM["NSG: Inbound Allow AppGW Subnet:80 only<br/>Deny All VNet Direct Inbound<br/>Deny Direct Internet"]
                end

                NATGW["NAT Gateway + Public IP<br/>(Private Subnet Egress TCP 80/443)"]
            end

            subgraph Observability["Monitoring & Diagnostics"]
                Monitor["Azure Monitor Alert Rules (7 rules)<br/>+ Action Group<br/>+ Activity Log Alert"]
                DiagStore["Storage Account (Blob)<br/>AppGW Access Logs (30-day retention)"]
            end
        end
    end

    Client -->|"HTTP :80"| AppGW
    AppGW -->|"HTTP :80 (allowed by NSG)"| VM1
    AppGW -->|"HTTP :80 (allowed by NSG)"| VM2
    VM1 --> NATGW
    VM2 --> NATGW

    AppGW -. diagnostic log delivery .-> DiagStore
    AppGW -. metrics .-> Monitor
    VM1 -. Availability / CPU .-> Monitor
    VM2 -. Availability / CPU .-> Monitor
```

## Communication Rules and Security Boundaries

### Network Security Group (NSG) Rule Matrix

| Target Subnet / NIC | Direction | Priority | Source | Destination / Port | Action | Purpose / Notes |
|---|---|---:|---|---|---|---|
| **AppGateway Subnet** | Inbound | 100 | `Internet` | Any / TCP 80 | **Allow** | Web access from general users |
| **AppGateway Subnet** | Inbound | 110 | `GatewayManager` | Any / TCP 65200-65535 | **Allow** | Azure Application Gateway control ports |
| **AppGateway Subnet** | Inbound | 120 | `AzureLoadBalancer` | Any / Any | **Allow** | Azure infrastructure health probes |
| **Private Backend Subnet** | Inbound | 100 | `10.1.1.0/24` (AppGW Subnet) | Any / TCP 80 | **Allow** | Only traffic forwarded from Application Gateway is allowed |
| **Private Backend Subnet** | Inbound | 200 | `VirtualNetwork` | Any / Any | **Deny** | Explicitly blocks Azure's default allow-all rule within the VNet |
| **Private Backend Subnet** | Inbound | 300 | `Internet` | Any / Any | **Deny** | Blocks direct reachability from the Internet |
| **Private Backend Subnet** | Egress | 100 | Any | `Internet` / TCP 80, 443 | **Allow** (via NATGW) | For apt package updates and Nginx installation |

### Subnet Design and Routing

| Subnet name | CIDR | Associated resources | External outbound method |
|---|---|---|---|
| **`snet-appgw`** | `10.1.1.0/24` | Application Gateway Standard_v2 | Dedicated Public IP (inbound and probes) |
| **`snet-backend`** | `10.1.2.0/24` | Backend Linux VMs (Zone 1, Zone 2) | NAT Gateway + Public IP (explicit egress) |

## Azure-Specific Decisions

- **Dedicated Subnet requirement**: Application Gateway Standard_v2 requires a dedicated Subnet (`/24` recommended) that cannot be shared with VMs or other resources, so `snet-appgw` was reserved independently.
- **Explicit NAT Gateway placement**: Because implicit Default Outbound Access is deprecated and restricted for Azure Private Subnets from 2026 onward, a NAT Gateway was explicitly associated to establish the package retrieval path (apt/HTTP).
- **Overriding the default VNet allow**: The default Azure NSG rule (`AllowVnetInBound`) permits all communication within the VNet, so an explicit Deny rule was added at priority 200 to thoroughly block communication from anything other than the AppGateway Subnet.
- **Fully SSH-less, passwordless operation**: No Public IP is assigned to the VMs and no SSH port is opened; setup is completed only by automatic Nginx provisioning through a cloud-init script.
- **Low-cost diagnostic log storage**: To avoid Log Analytics workspace ingestion charges and the complexity of enabling the provider, a Blob archive in a standard Storage Account (30-day lifecycle) was adopted.
