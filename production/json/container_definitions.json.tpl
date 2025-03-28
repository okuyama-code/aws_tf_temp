[
  {
    "name": "my-app-prod",
    "image": "127214163688.dkr.ecr.ap-northeast-1.amazonaws.com/my-app-prod-nestjs:latest",
    "essential": true,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${aws_region}",
        "awslogs-stream-prefix": "nestjs",
        "awslogs-group": "/my-app_prod/ecs"
      }
    },
    "environment": [
      {
        "name": "PORT",
        "value": "${port}"
      },
      {
        "name": "DATABASE_URL",
        "value": "postgresql://${db_username}:${db_password}@${db_host}/${db_name}"
      },
      {
        "name": "AWS_REGION",
        "value": "${aws_region}"
      }
    ],
    "secrets": [
      {
        "name": "FIREBASE_PROJECT_ID",
        "valueFrom": "${ssm_firebase_project_id}"
      },
      {
        "name": "FIREBASE_PRIVATE_KEY",
        "valueFrom": "${ssm_firebase_private_key}"
      },
      {
        "name": "FIREBASE_CLIENT_EMAIL",
        "valueFrom": "${ssm_firebase_client_email}"
      },
      {
        "name": "APP_IOS_LATEST_VERSION",
        "valueFrom": "${ssm_app_ios_latest_version}"
      },
      {
        "name": "AWS_ACCESS_KEY_ID",
        "valueFrom": "${ssm_aws_access_key_id}"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "valueFrom": "${ssm_aws_secret_access_key}"
      },
      {
        "name": "AWS_S3_BUCKET_NAME",
        "valueFrom": "${ssm_aws_s3_bucket_name}"
      }
    ],
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": 4000
      }
    ]
  }
]
