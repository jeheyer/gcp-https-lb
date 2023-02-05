# Management of a Google Cloud Platform External HTTP(S) Load Balancer

## Inputs 

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| project\_id | Project id of the project | `string` | 
| name | Name of the load balancer | `string` |

#### backends variable

| Name | Description                                | Type | Default |
|--|--------------------------------------------|------|---------|
| description | Description for the Backend (Buckets Only) | `string` | n/a |
| fqdn | FQDN Hostname (Internet NEGs only) | `string` | n/a |
| ip_address | IP Address (Internet NEGs Only) | `string` | n/a |
| port | TCP Port of the Backend | `number` | 443 |
| protocol | Protocol of the Backend (HTTP or HTTPS) | `string` | "HTTPS" |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| address | IP address of the load balancer  | `string` |

### Usage Examples

#### Global Load Balancer Mix of Cloud Run

```
backends = {
  cloud-run = {
    docker_image   = "johnnylingo/flask2-sqlalchemy"
    container_port = 8000
  }
  static-bucket = {
    bucket_name = "my-static-bucket"
    enable_cdn  = true
  }
}
routing_rules = {
  api = {
    hosts = ["api.mydomain.com"]
    backend = "cloud-run"
  }
  static-bucket = {
    hosts   = ["static.mydomain.com", "*-static.mydomain.com"]
  }
}

```

#### Global Load Balancer with a regional Cloud Run backend

```
backends = {
  cloud_run = {
    container_name  = "nginx1"
    region          = "us-central1"
  }
}
default_backend = "cloud_run"
```
#### 
```

backends = {
  nginx-docker = {
    container_name  = "nginx"
    container_image = "docker.io/library/nginx"
    region          = "us-east5"
  }
}
```