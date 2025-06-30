
resource "confluent_environment" "csfle-env" {
  display_name = var.env_display_name

  stream_governance {
    package = var.governance_package
  }
}

data "confluent_schema_registry_cluster" "advanced" {
  environment {
    id = confluent_environment.csfle-env.id
  }

  depends_on = [
    confluent_kafka_cluster.standard
  ]
}

# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
resource "confluent_kafka_cluster" "standard" {
  display_name = var.cluster_display_name
  availability = var.cluster_availability
  cloud        = var.cluster_provider
  region       = var.cluster_region
  standard {}
  environment {
    id = confluent_environment.csfle-env.id
  }
}

// 'app-manager' service account is required in this configuration to create 'customers' topic and assign roles
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager-csfle"
  description  = "Service account to manage 'csfle-cluster' Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.standard.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-csfle-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.csfle-env.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}

## Topic

resource "confluent_kafka_topic" "customers" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = var.topic_name
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}


## Consumer 

resource "confluent_service_account" "app-consumer" {
  display_name = "app-consumer-csfle"
  description  = "Service account to consume from 'customers' topic of 'csfle-cluster' Kafka cluster"
}

// Note that in order to consume from a topic, the principal of the consumer ('app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
resource "confluent_role_binding" "app-consumer-developer-read-from-topic" {
 principal   = "User:${confluent_service_account.app-consumer.id}"
 role_name   = "DeveloperRead"
 crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.customers.topic_name}"
}

resource "confluent_role_binding" "app-consumer-developer-read-from-group" {
  principal = "User:${confluent_service_account.app-consumer.id}"
  role_name = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=customers-management-app"
}

resource "confluent_api_key" "app-consumer-kafka-api-key" {
  display_name = "app-consumer-csfle-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-consumer' service account"
  owner {
    id          = confluent_service_account.app-consumer.id
    api_version = confluent_service_account.app-consumer.api_version
    kind        = confluent_service_account.app-consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.csfle-env.id
    }
  }
}

## Producer

resource "confluent_service_account" "app-producer" {
  display_name = "app-producer-csfle"
  description  = "Service account to produce to 'customers' topic of 'csfle-cluster' Kafka cluster"
}

resource "confluent_role_binding" "app-producer-developer-write" {
  principal   = "User:${confluent_service_account.app-producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.customers.topic_name}"
}

resource "confluent_api_key" "app-producer-kafka-api-key" {
  display_name = "app-producer-csfle-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-producer' service account"
  owner {
    id          = confluent_service_account.app-producer.id
    api_version = confluent_service_account.app-producer.api_version
    kind        = confluent_service_account.app-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.csfle-env.id
    }
  }
}

## Environment Manager

resource "confluent_service_account" "env-manager" {
  display_name = "env-manager-csfle"
  description  = "Service account to manage 'csfle-env' environment"
}

resource "confluent_role_binding" "env-manager-environment-admin" {
  principal   = "User:${confluent_service_account.env-manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.csfle-env.resource_name
}

resource "confluent_api_key" "env-manager-api-key" {
  display_name = "env-manager-csfle-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'env-manager' service account"
  owner {
    id          = confluent_service_account.env-manager.id
    api_version = confluent_service_account.env-manager.api_version
    kind        = confluent_service_account.env-manager.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.advanced.id
    api_version = data.confluent_schema_registry_cluster.advanced.api_version
    kind        = data.confluent_schema_registry_cluster.advanced.kind

    environment {
      id = confluent_environment.csfle-env.id
    }
  }

  # The goal is to ensure that confluent_role_binding.env-manager-environment-admin is created before
  # confluent_api_key.env-manager-schema-registry-api-key is used to create instances of
  # confluent_schema resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.env-manager-schema-registry-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_schema resources instead.
  depends_on = [
    confluent_role_binding.env-manager-environment-admin
  ]
}

## Schema

resource "confluent_schema" "customer" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  # https://developer.confluent.io/learn-kafka/schema-registry/schema-subjects/#topicnamestrategy
  subject_name = "${confluent_kafka_topic.customers.topic_name}-value"
  format       = "AVRO"
  schema       = file("./schemas/avro/customer.avsc")
  credentials {
    key    = confluent_api_key.env-manager-api-key.id
    secret = confluent_api_key.env-manager-api-key.secret
  }
  depends_on = [
    confluent_tag.pci
  ]
}

## Data Manager

resource "confluent_service_account" "data-steward" {
  display_name = "data-steward-csfle"
  description  = "Service account to manage data tags in 'csfle-env' environment"
}

resource "confluent_role_binding" "data-steward-role-binding" {
  principal   = "User:${confluent_service_account.data-steward.id}"
  role_name   = "DataSteward"
  crn_pattern = confluent_environment.csfle-env.resource_name
}

resource "confluent_api_key" "data-steward-api-key" {
  display_name = "data-steward-csfle-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'data-steward' service account"
  owner {
    id          = confluent_service_account.data-steward.id
    api_version = confluent_service_account.data-steward.api_version
    kind        = confluent_service_account.data-steward.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.advanced.id
    api_version = data.confluent_schema_registry_cluster.advanced.api_version
    kind        = data.confluent_schema_registry_cluster.advanced.kind

    environment {
      id = confluent_environment.csfle-env.id
    }
  }

  # The goal is to ensure that confluent_role_binding.env-manager-environment-admin is created before
  # confluent_api_key.env-manager-schema-registry-api-key is used to create instances of
  # confluent_schema resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.env-manager-schema-registry-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_schema resources instead.
  depends_on = [
    confluent_role_binding.env-manager-environment-admin
  ]
}

## Schema Tag

resource "confluent_tag" "pci" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.data-steward-api-key.id
    secret = confluent_api_key.data-steward-api-key.secret
  }

  name        = "PCI"
  description = "Payment Card Industry"
}

# Apply the Tag on a topic
resource "confluent_tag_binding" "pci-topic-tagging" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.advanced.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.advanced.rest_endpoint
  credentials {
    key    = confluent_api_key.data-steward-api-key.id
    secret = confluent_api_key.data-steward-api-key.secret
  }

  tag_name    = confluent_tag.pci.name
  entity_name = "${data.confluent_schema_registry_cluster.advanced.id}:${confluent_kafka_cluster.standard.id}:${confluent_kafka_topic.customers.topic_name}"
  entity_type = local.topic_entity_type
}


locals {
  topic_entity_type  = "kafka_topic"
}