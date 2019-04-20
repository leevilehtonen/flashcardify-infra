[
  {
    "name": "${name}",
    "image": "${image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${port},
        "hostPort": ${port},
        "protocol": "tcp"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group}",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "environment":[
      {
        "name": "NODE_ENV",
        "value": "production"
      },
      {
        "name": "SERVICE_PORT",
        "value": "${port}"
      },
      {
        "name": "DB_PORT",
        "value": "${db_port}"
      },
      {
        "name": "DB_HOST",
        "value": "${db_host}"
      },
      {
        "name": "DB_DATABASE",
        "value": "${db_database}"
      },
      {
        "name": "DB_USER",
        "value": "${db_user}"
      }
    ],
    "secrets": [
      {
        "name": "DB_PASSWORD",
        "valueFrom": "${db_password_from}"
      }
    ],
    "requiresCompatibilities": ["FARGATE"]
  }
]
