output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.csfle-env.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.standard.id}
  Kafka topic name: ${confluent_kafka_topic.customers.topic_name}

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  ${confluent_service_account.app-manager.display_name}:                     ${confluent_service_account.app-manager.id}
  ${confluent_service_account.app-manager.display_name}'s Kafka API Key:     "${confluent_api_key.app-manager-kafka-api-key.id}"
  ${confluent_service_account.app-manager.display_name}'s Kafka API Secret:  "${confluent_api_key.app-manager-kafka-api-key.secret}"

  ${confluent_service_account.env-manager.display_name}:                     ${confluent_service_account.env-manager.id}
  ${confluent_service_account.env-manager.display_name}'s Kafka API Key:     "${confluent_api_key.env-manager-api-key.id}"
  ${confluent_service_account.env-manager.display_name}'s Kafka API Secret:  "${confluent_api_key.env-manager-api-key.secret}"

  ${confluent_service_account.data-steward.display_name}:                     ${confluent_service_account.data-steward.id}
  ${confluent_service_account.data-steward.display_name}'s Kafka API Key:     "${confluent_api_key.data-steward-api-key.id}"
  ${confluent_service_account.data-steward.display_name}'s Kafka API Secret:  "${confluent_api_key.data-steward-api-key.secret}"

  ${confluent_service_account.app-producer.display_name}:                    ${confluent_service_account.app-producer.id}
  ${confluent_service_account.app-producer.display_name}'s Kafka API Key:    "${confluent_api_key.app-producer-kafka-api-key.id}"
  ${confluent_service_account.app-producer.display_name}'s Kafka API Secret: "${confluent_api_key.app-producer-kafka-api-key.secret}"

  ${confluent_service_account.app-consumer.display_name}:                    ${confluent_service_account.app-consumer.id}
  ${confluent_service_account.app-consumer.display_name}'s Kafka API Key:    "${confluent_api_key.app-consumer-kafka-api-key.id}"
  ${confluent_service_account.app-consumer.display_name}'s Kafka API Secret: "${confluent_api_key.app-consumer-kafka-api-key.secret}"
  EOT

  sensitive = true
}