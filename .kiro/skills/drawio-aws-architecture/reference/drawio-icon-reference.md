# draw.io AWS Icon Reference

166 service-level icon mappings from MCP server names to draw.io `resIcon`
values. Use the **AWS Display Name** column as the source of truth for service
labels in generated diagrams. Names follow the current
[AWS Architecture Icons](https://aws.amazon.com/architecture/icons/) and AWS
product documentation. A legacy icon name does not override a current product
name.

This list includes one entry per distinct AWS service or generally useful
resource icon. It excludes most sub-resource icons, IoT device types, duplicate
aliases, and engine sub-variants. The MCP server returns approximately 350 icons
total; the 166 here are suitable as architecture-diagram nodes.

Icons marked Yes in the Validated column have been tested by PNG export.
Unmarked icons use the standard naming convention and should work but have not
been individually verified. To add new icons, see the Adding Icons section in
`SKILL.md`.

## How to Read This Table

- AWS Display Name: official label to use in a generated diagram
- MCP Name: Python class name returned by `list_icons` on the AWS Diagram MCP
  Server
- resIcon Value: draw.io `resIcon` parameter value, including the
  `mxgraph.aws4.` prefix
- fillColor: AWS service category color for the icon background
- Validated: whether PNG export confirmed that the icon renders correctly

## Compute

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS Lambda | Lambda | `mxgraph.aws4.lambda` | #ED7100 | Yes |
| AWS Lambda function | LambdaFunction | `mxgraph.aws4.lambda_function` | #ED7100 | |
| Amazon EC2 | EC2 | `mxgraph.aws4.ec2` | #ED7100 | Yes |
| Amazon EC2 instance | EC2Instance | `mxgraph.aws4.ec2_instance` | #ED7100 | |
| Amazon ECS | ECS | `mxgraph.aws4.ecs` | #ED7100 | Yes |
| Amazon EKS | EKS | `mxgraph.aws4.eks` | #ED7100 | Yes |
| AWS Fargate | Fargate | `mxgraph.aws4.fargate` | #ED7100 | |
| AWS Batch | Batch | `mxgraph.aws4.batch` | #ED7100 | |
| AWS Elastic Beanstalk | ElasticBeanstalk | `mxgraph.aws4.elastic_beanstalk` | #ED7100 | |
| Amazon Lightsail | Lightsail | `mxgraph.aws4.lightsail` | #ED7100 | |
| AWS App Runner | AppRunner | `mxgraph.aws4.app_runner` | #ED7100 | |
| Amazon ECR | ECR | `mxgraph.aws4.ecr` | #ED7100 | |
| AWS Serverless Application Repository | SAR | `mxgraph.aws4.serverless_application_repository` | #ED7100 | |
| Amazon EC2 Auto Scaling | AutoScaling | `mxgraph.aws4.auto_scaling2` | #ED7100 | |
| AWS Outposts | Outposts | `mxgraph.aws4.outposts` | #ED7100 | |

## Network

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon CloudFront | CloudFront | `mxgraph.aws4.cloudfront` | #8C4FFF | Yes |
| Amazon API Gateway | APIGateway | `mxgraph.aws4.api_gateway` | #E7157B | Yes |
| Amazon Route 53 | Route53 | `mxgraph.aws4.route_53` | #8C4FFF | Yes |
| Amazon VPC | VPC | `mxgraph.aws4.vpc` | #8C4FFF | |
| Elastic Load Balancing | ELB | `mxgraph.aws4.elastic_load_balancing` | #8C4FFF | |
| Application Load Balancer | ALB | `mxgraph.aws4.application_load_balancer` | #8C4FFF | |
| Network Load Balancer | NLB | `mxgraph.aws4.network_load_balancer` | #8C4FFF | |
| AWS Direct Connect | DirectConnect | `mxgraph.aws4.direct_connect` | #8C4FFF | |
| AWS Global Accelerator | GlobalAccelerator | `mxgraph.aws4.global_accelerator` | #8C4FFF | |
| AWS Transit Gateway | TransitGateway | `mxgraph.aws4.transit_gateway` | #8C4FFF | |
| NAT gateway | NATGateway | `mxgraph.aws4.nat_gateway` | #8C4FFF | |
| AWS PrivateLink | Privatelink | `mxgraph.aws4.privatelink` | #8C4FFF | |
| AWS App Mesh | AppMesh | `mxgraph.aws4.app_mesh` | #8C4FFF | |
| AWS Cloud Map | CloudMap | `mxgraph.aws4.cloud_map` | #8C4FFF | |
| AWS Network Firewall | NetworkFirewall | `mxgraph.aws4.network_firewall` | #8C4FFF | |

## Database

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon DynamoDB | Dynamodb | `mxgraph.aws4.dynamodb` | #C925D1 | Yes |
| Amazon RDS | RDS | `mxgraph.aws4.rds` | #C925D1 | Yes |
| Amazon Aurora | Aurora | `mxgraph.aws4.aurora` | #C925D1 | |
| Amazon ElastiCache | ElastiCache | `mxgraph.aws4.elasticache` | #C925D1 | Yes |
| Amazon Neptune | Neptune | `mxgraph.aws4.neptune` | #C925D1 | |
| Amazon Redshift | Redshift | `mxgraph.aws4.redshift` | #C925D1 | |
| Amazon DocumentDB (with MongoDB compatibility) | DocumentDB | `mxgraph.aws4.documentdb_with_mongodb_compatibility` | #C925D1 | |
| Amazon QLDB | QLDB | `mxgraph.aws4.qldb` | #C925D1 | |
| Amazon Timestream | Timestream | `mxgraph.aws4.timestream` | #C925D1 | |
| Amazon Keyspaces (for Apache Cassandra) | KeyspacesManagedApacheCassandraService | `mxgraph.aws4.keyspaces` | #C925D1 | |
| AWS Database Migration Service (AWS DMS) | DMS | `mxgraph.aws4.database_migration_service` | #C925D1 | |
| Amazon DynamoDB Accelerator (DAX) | DAX | `mxgraph.aws4.dynamodb_dax` | #C925D1 | |

## Security

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon Cognito | Cognito | `mxgraph.aws4.cognito` | #DD344C | Yes |
| AWS Identity and Access Management (IAM) | IAM | `mxgraph.aws4.iam` | #DD344C | |
| AWS Key Management Service (AWS KMS) | KMS | `mxgraph.aws4.key_management_service` | #DD344C | |
| AWS Secrets Manager | SecretsManager | `mxgraph.aws4.secrets_manager` | #DD344C | Yes |
| AWS WAF | WAF | `mxgraph.aws4.waf` | #DD344C | Yes |
| AWS Shield | Shield | `mxgraph.aws4.shield` | #DD344C | |
| Amazon GuardDuty | Guardduty | `mxgraph.aws4.guardduty` | #DD344C | |
| Amazon Inspector | Inspector | `mxgraph.aws4.inspector` | #DD344C | |
| Amazon Macie | Macie | `mxgraph.aws4.macie` | #DD344C | |
| Amazon Detective | Detective | `mxgraph.aws4.detective` | #DD344C | |
| AWS Security Hub | SecurityHub | `mxgraph.aws4.security_hub` | #DD344C | |
| AWS Certificate Manager (ACM) | ACM | `mxgraph.aws4.certificate_manager` | #DD344C | Yes |
| AWS Directory Service | DirectoryService | `mxgraph.aws4.directory_service` | #DD344C | |
| AWS Firewall Manager | FirewallManager | `mxgraph.aws4.firewall_manager` | #DD344C | |
| Amazon Security Lake | SecurityLake | `mxgraph.aws4.security_lake` | #DD344C | |
| AWS IAM Identity Center | SingleSignOn | `mxgraph.aws4.single_sign_on` | #DD344C | |

## Storage

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon S3 | S3 | `mxgraph.aws4.s3` | #3F8624 | Yes |
| Amazon EFS | EFS | `mxgraph.aws4.elastic_file_system` | #3F8624 | |
| Amazon EBS | EBS | `mxgraph.aws4.elastic_block_store` | #3F8624 | |
| Amazon FSx | FSx | `mxgraph.aws4.fsx` | #3F8624 | |
| Amazon S3 Glacier | S3Glacier | `mxgraph.aws4.s3_glacier` | #3F8624 | |
| AWS Storage Gateway | StorageGateway | `mxgraph.aws4.storage_gateway` | #3F8624 | |
| AWS Backup | Backup | `mxgraph.aws4.backup` | #3F8624 | |
| AWS Snowball | Snowball | `mxgraph.aws4.snowball` | #3F8624 | |
| AWS Snowball Edge | SnowballEdge | `mxgraph.aws4.snowball_edge` | #3F8624 | |

## Machine Learning and Artificial Intelligence

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon SageMaker AI | Sagemaker | `mxgraph.aws4.sagemaker` | #01A88D | Yes |
| Amazon Bedrock | Bedrock | `mxgraph.aws4.bedrock` | #01A88D | Yes |
| Amazon Comprehend | Comprehend | `mxgraph.aws4.comprehend` | #01A88D | |
| Amazon Rekognition | Rekognition | `mxgraph.aws4.rekognition` | #01A88D | |
| Amazon Lex | Lex | `mxgraph.aws4.lex` | #01A88D | |
| Amazon Polly | Polly | `mxgraph.aws4.polly` | #01A88D | |
| Amazon Translate | Translate | `mxgraph.aws4.translate` | #01A88D | |
| Amazon Textract | Textract | `mxgraph.aws4.textract` | #01A88D | |
| Amazon Transcribe | Transcribe | `mxgraph.aws4.transcribe` | #01A88D | |
| Amazon Forecast | Forecast | `mxgraph.aws4.forecast` | #01A88D | |
| Amazon Personalize | Personalize | `mxgraph.aws4.personalize` | #01A88D | |
| Amazon Kendra | Kendra | `mxgraph.aws4.kendra` | #01A88D | |
| Amazon Fraud Detector | FraudDetector | `mxgraph.aws4.fraud_detector` | #01A88D | |
| Amazon Q | Q | `mxgraph.aws4.q` | #01A88D | |

## Management and Governance

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon CloudWatch | Cloudwatch | `mxgraph.aws4.cloudwatch` | #E7157B | Yes |
| AWS CloudTrail | Cloudtrail | `mxgraph.aws4.cloudtrail` | #E7157B | Yes |
| AWS CloudFormation | Cloudformation | `mxgraph.aws4.cloudformation` | #E7157B | |
| AWS Config | Config | `mxgraph.aws4.config` | #E7157B | |
| AWS Systems Manager | SystemsManager | `mxgraph.aws4.systems_manager` | #E7157B | |
| AWS Organizations | Organizations | `mxgraph.aws4.organizations` | #E7157B | |
| AWS Control Tower | ControlTower | `mxgraph.aws4.control_tower` | #E7157B | |
| AWS Trusted Advisor | TrustedAdvisor | `mxgraph.aws4.trusted_advisor` | #E7157B | |
| AWS Service Catalog | ServiceCatalog | `mxgraph.aws4.service_catalog` | #E7157B | |
| AWS License Manager | LicenseManager | `mxgraph.aws4.license_manager` | #E7157B | |
| AWS Proton | Proton | `mxgraph.aws4.proton` | #E7157B | |
| AWS Well-Architected Tool | WellArchitectedTool | `mxgraph.aws4.well_architected_tool` | #E7157B | |

## Integration

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon EventBridge | Eventbridge | `mxgraph.aws4.eventbridge` | #E7157B | Yes |
| AWS Step Functions | StepFunctions | `mxgraph.aws4.step_functions` | #E7157B | Yes |
| Amazon SNS | SNS | `mxgraph.aws4.sns` | #E7157B | Yes |
| Amazon SQS | SQS | `mxgraph.aws4.sqs` | #E7157B | Yes |
| AWS AppSync | Appsync | `mxgraph.aws4.appsync` | #E7157B | |
| Amazon MQ | MQ | `mxgraph.aws4.mq` | #E7157B | |
| AWS Step Functions Express Workflows | ExpressWorkflows | `mxgraph.aws4.express_workflows` | #E7157B | |

## Cost Management

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS Budgets | Budgets | `mxgraph.aws4.budgets` | #277116 | Yes |
| AWS Cost Explorer | CostExplorer | `mxgraph.aws4.cost_explorer` | #277116 | |
| AWS Cost and Usage Reports | CostAndUsageReport | `mxgraph.aws4.cost_and_usage_report` | #277116 | |
| AWS Cost Management | CostManagement | `mxgraph.aws4.cost_management` | #277116 | |
| Savings Plans | SavingsPlans | `mxgraph.aws4.savings_plans` | #277116 | |

## Analytics

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon Athena | Athena | `mxgraph.aws4.athena` | #8C4FFF | |
| Amazon Kinesis | Kinesis | `mxgraph.aws4.kinesis` | #8C4FFF | Yes |
| Amazon Data Firehose | KinesisDataFirehose | `mxgraph.aws4.kinesis_data_firehose` | #8C4FFF | |
| Amazon Kinesis Data Streams | KinesisDataStreams | `mxgraph.aws4.kinesis_data_streams` | #8C4FFF | |
| Amazon Managed Service for Apache Flink | KinesisDataAnalytics | `mxgraph.aws4.kinesis_data_analytics` | #8C4FFF | |
| AWS Glue | Glue | `mxgraph.aws4.glue` | #8C4FFF | Yes |
| Amazon EMR | EMR | `mxgraph.aws4.emr` | #8C4FFF | |
| AWS Lake Formation | LakeFormation | `mxgraph.aws4.lake_formation` | #8C4FFF | |
| Amazon QuickSight | Quicksight | `mxgraph.aws4.quicksight` | #8C4FFF | |
| Amazon OpenSearch Service | AmazonOpensearchService | `mxgraph.aws4.elasticsearch_service` | #8C4FFF | Yes |
| Amazon Managed Streaming for Apache Kafka (Amazon MSK) | ManagedStreamingForKafka | `mxgraph.aws4.managed_streaming_for_kafka` | #8C4FFF | |
| AWS Data Pipeline | DataPipeline | `mxgraph.aws4.data_pipeline` | #8C4FFF | |
| Amazon CloudSearch | Cloudsearch | `mxgraph.aws4.cloudsearch` | #8C4FFF | |

## Developer Tools

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS CodeBuild | Codebuild | `mxgraph.aws4.codebuild` | #C7131F | |
| AWS CodeCommit | Codecommit | `mxgraph.aws4.codecommit` | #C7131F | |
| AWS CodeDeploy | Codedeploy | `mxgraph.aws4.codedeploy` | #C7131F | |
| AWS CodePipeline | Codepipeline | `mxgraph.aws4.codepipeline` | #C7131F | |
| AWS CodeArtifact | Codeartifact | `mxgraph.aws4.codeartifact` | #C7131F | |
| AWS Cloud9 | Cloud9 | `mxgraph.aws4.cloud9` | #C7131F | |
| AWS Cloud Development Kit (AWS CDK) | CloudDevelopmentKit | `mxgraph.aws4.cloud_development_kit` | #C7131F | |
| AWS X-Ray | XRay | `mxgraph.aws4.xray` | #C7131F | Yes |
| AWS CloudShell | Cloudshell | `mxgraph.aws4.cloudshell` | #C7131F | |

## Internet of Things

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS IoT Core | IotCore | `mxgraph.aws4.iot_core` | #1B660F | |
| AWS IoT Greengrass | IotGreengrass | `mxgraph.aws4.iot_greengrass` | #1B660F | |
| AWS IoT Analytics | IotAnalytics | `mxgraph.aws4.iot_analytics` | #1B660F | |
| AWS IoT Events | IotEvents | `mxgraph.aws4.iot_events` | #1B660F | |
| AWS IoT SiteWise | IotSitewise | `mxgraph.aws4.iot_sitewise` | #1B660F | |
| AWS IoT Device Defender | IotDeviceDefender | `mxgraph.aws4.iot_device_defender` | #1B660F | |
| AWS IoT Device Management | IotDeviceManagement | `mxgraph.aws4.iot_device_management` | #1B660F | |
| AWS IoT Things Graph | IotThingsGraph | `mxgraph.aws4.iot_things_graph` | #1B660F | |
| FreeRTOS | FreeRTOS | `mxgraph.aws4.freertos` | #1B660F | |

## Migration and Transfer

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS Migration Hub | MigrationHub | `mxgraph.aws4.migration_hub` | #1B660F | |
| AWS Database Migration Service (AWS DMS) | DatabaseMigrationService | `mxgraph.aws4.database_migration_service` | #1B660F | |
| AWS DataSync | Datasync | `mxgraph.aws4.datasync` | #1B660F | |
| AWS Transfer Family | TransferForSftp | `mxgraph.aws4.transfer_for_sftp` | #1B660F | |
| AWS Application Discovery Service | ApplicationDiscoveryService | `mxgraph.aws4.application_discovery_service` | #1B660F | |

## Media

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS Elemental MediaConvert | ElementalMediaconvert | `mxgraph.aws4.elemental_mediaconvert` | #ED7100 | |
| AWS Elemental MediaLive | ElementalMedialive | `mxgraph.aws4.elemental_medialive` | #ED7100 | |
| AWS Elemental MediaPackage | ElementalMediapackage | `mxgraph.aws4.elemental_mediapackage` | #ED7100 | |
| AWS Elemental MediaStore | ElementalMediastore | `mxgraph.aws4.elemental_mediastore` | #ED7100 | |
| AWS Elemental MediaConnect | ElementalMediaconnect | `mxgraph.aws4.elemental_mediaconnect` | #ED7100 | |
| Amazon Elastic Transcoder | ElasticTranscoder | `mxgraph.aws4.elastic_transcoder` | #ED7100 | |

## Customer Engagement

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon Connect | Connect | `mxgraph.aws4.connect` | #DD344C | |
| Amazon Pinpoint | Pinpoint | `mxgraph.aws4.pinpoint` | #DD344C | |
| Amazon SES | SES | `mxgraph.aws4.simple_email_service` | #DD344C | |

## Front-End Web and Mobile

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS Amplify | Amplify | `mxgraph.aws4.amplify` | #ED7100 | |
| AWS Device Farm | DeviceFarm | `mxgraph.aws4.device_farm` | #ED7100 | |

## End User Computing

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon WorkSpaces | Workspaces | `mxgraph.aws4.workspaces` | #1B660F | |
| Amazon AppStream 2.0 | Appstream20 | `mxgraph.aws4.appstream_2_0` | #1B660F | |
| Amazon WorkDocs | Workdocs | `mxgraph.aws4.workdocs` | #1B660F | |

## Blockchain

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon Managed Blockchain | ManagedBlockchain | `mxgraph.aws4.managed_blockchain` | #ED7100 | |

## Satellite

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| AWS Ground Station | GroundStation | `mxgraph.aws4.ground_station` | #232F3E | |

## Quantum Technologies

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon Braket | Braket | `mxgraph.aws4.braket` | #232F3E | |

## Games

| AWS Display Name | MCP Name | resIcon Value | fillColor | Validated |
|---|---|---|---|---|
| Amazon GameLift Servers | Gamelift | `mxgraph.aws4.gamelift` | #ED7100 | |

## General

| Display Name | MCP Name | Shape Value | fillColor | Validated |
|---|---|---|---|---|
| User | User | `mxgraph.aws4.user` | #232F3E | Yes |
| Users | Users | `mxgraph.aws4.users` | #232F3E | |
| Client | Client | `mxgraph.aws4.client` | #232F3E | |
| Internet | InternetAlt1 | `mxgraph.aws4.internet_alt1` | #232F3E | Yes |
| Internet gateway | InternetGateway | `mxgraph.aws4.internet_gateway` | #232F3E | |
| Generic database | GenericDatabase | `mxgraph.aws4.generic_database` | #232F3E | |
| Traditional server | TraditionalServer | `mxgraph.aws4.traditional_server` | #232F3E | |

General icons use `shape=mxgraph.aws4.<name>` directly, not the
`resourceIcon;resIcon=` pattern. They do not have a colored background square.
