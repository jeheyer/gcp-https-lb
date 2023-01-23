# Management of a Google Cloud Platform External HTTP(S) Load Balancer

## Inputs 

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| project\_id | Project id of the project | `string` | 
| name | Name of the load balancer | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| description | Description for this resource | `string` | n/a |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| address | IP address of the load balancer  | `string` |

### Usage Examples

#### Global Load Balancer with backend bucket, CDN Enabled for static files

```
backends = {
  static-bucket = {
    bucket_name = "my-static-bucket"
    enable_cdn  = true
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