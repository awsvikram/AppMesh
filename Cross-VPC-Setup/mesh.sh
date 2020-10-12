INT_LOAD_BALANCER1=$(jq < cfn-crystal.json -r '.InternalLoadBalancerDNS');
Certificate_Arn=$(aws acm list-certificates | jq -r '.CertificateSummaryList[0].CertificateArn');
SPEC=$(cat <<-EOF
  { 
    "serviceDiscovery": {
      "dns": { 
        "hostname": "$INT_LOAD_BALANCER1"
      }
    },
    "logging": {
      "accessLog": {
        "file": {
          "path": "/dev/stdout"
        }
      }
    },      
    "listeners": [
      {
        "healthCheck": {
          "healthyThreshold": 3,
          "intervalMillis": 10000,
          "path": "/health",
          "port": 3000,
          "protocol": "http",
          "timeoutMillis": 5000,
          "unhealthyThreshold": 3
        },
        "portMapping": { "port": 3000, "protocol": "http" },
        "tls": {
          "mode": "STRICT",
          "certificate": {
            "acm": {
              "certificateArn": "$Certificate_Arn"
            } 
          }
        }  
      }
    ]
  }
EOF
); \# Create app mesh virual node #
aws appmesh create-virtual-node \
  --mesh-name appmesh-workshop \
  --virtual-node-name crystal-lb-vanilla \
  --spec "$SPEC"
##Virtual Service
  
SPEC=$(cat <<-EOF
  { 
    "provider": {
      "virtualNode": { 
        "virtualNodeName": "crystal-lb-vanilla"
      }
    }
  }
EOF
);
aws appmesh create-virtual-service   --mesh-name appmesh-workshop   --virtual-service-name crystal.appmeshworkshop.hosted.local   --spec "$SPEC"
