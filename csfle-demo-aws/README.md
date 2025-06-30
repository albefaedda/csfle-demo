# Client-Side Field Level Encryption (CSFLE) with AWS KMS

## Prerequisites

- Confluent Cloud cluster with Advanced Stream Governance package
- For clients, Confluent Platform 7.4.5, 7.5.4, 7.6.1 or higher are required.

## Goal
We will produce data with payment card info to Confluent Cloud in the following form

```json
{
    "id": "linetbrown67",
    "customer_name": "Linet Brown",
    "customer_email": "lpedroni0@whitehouse.gov",
    "customer_address": "56 Di Loreto Terrace",
    "card_number": "3455 5606 6764 114"
}
```
However, we set up the corresponding configurations to encrypt the `card_number` field. We then start a consumer with the corresponding configurations to decrypt the field again.

## AWS KMS

In the KMS section of the AWS Management Console, create a new Symmetric Key with Encrypt/Decrypt configuration for Single Region. 

Resource name: `csfle-kms-key`

⚠️ Important: As you click through this process you will be asked to define Admins and Users for your key. Ensure you grant access to the User that you want use in your Producer/Consumer app.

### AWS IAM

After your Key has been created, navigate to AWS IAM and create an Access Key for the User that you granted permissions to in the previous step.
⚠️ Important: Ensure you copy your Access Key ID and Secret (or download the csv file) ⚠️


## Create Tag

> You can either create the schema and tags using Terraform or you can use the REST APIs to do so.
> I'm providing the Terraform configuration for the creation of the schema and tags, below is an example with REST APIs. 

We first need to create a tag on which we supply the encryption later, such as `PCI`. As of today, we need to create a tag in the Stream Catalog first, see the [documentation](https://docs.confluent.io/platform/current/schema-registry/fundamentals/data-contracts.html#tags) of Data Contracts. 

## Register Schema

We can now register the schema with setting `PCI` tag to the birthday field and defining the encryption rule.

Let's first encode our Schema Registry API Key/Secret to base64: 

```shell
echo -n 'KEYKEYKEY:SECRETSECRETSECRET' | base64
enc0d3denc0d3denc0d3denc0d3denc0d3d
```

We can now register the schema by using the Schema Registry API 
```shell
curl --request POST --url 'https://<schema-registry-url>/subjects/customers-value/versions' \ 
--header 'Authorization: Basic enc0d3denc0d3denc0d3denc0d3denc0d3d' \ 
--header 'content-type: application/octet-stream' \ 
--data '{ 
  "schemaType": "AVRO", 
  "schema": "{ \"name\": \"Customer\", \"namespace\": \"com.faeddalberto.csfle.model\", \"type\": \"record\", \"fields\": [ { \"name\": \"id\", \"type\": \"string\" }, { \"name\":  \"customer_name\", \"type\": \"string\"}, { \"name\": \"customer_email\", \"type\": \"string\" }, { \"name\": \"customer_address\", \"type\": \"string\" }, { \"name\": \"card_number\", \"type\": \"string\", \"confluent:tags\": [\"PCI\", \"PRIVATE\"]}]}", 
  "metadata": { 
    "properties": { 
      "owner": "Alberto Faedda", 
      "email": "afaedda@confluent.io" 
    } 
  }
}'

```

or using Confluent Terraform Provider:

```shell
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
```

## Register Rule using the Schema Registry Rest APIs

We can now register the Data Contract Rule, to encrypt/decrypt the PCI data. 
Use the EnvironmentAdmin API Key and Secret for this operation. 
Go to AWS KMS and copy the ARN of the key you previously created. We need this ARN to register our encryption rule below.

```shell
curl --request POST --url 'https://psrc-zgxr5eq.eu-west-2.aws.confluent.cloud/subjects/customers-value/versions' --header 'Authorization: Basic enc0d3denc0d3denc0d3denc0d3denc0d3d' --header 'Content-Type: application/vnd.schemaregistry.v1+json' \
  --data '{
        "ruleSet": {
        "domainRules": [
      {
        "name": "encryptPCI",
        "kind": "TRANSFORM",
        "type": "ENCRYPT",
        "mode": "WRITEREAD",
        "tags": ["PCI"],
        "params": {
           "encrypt.kek.name": "AWS_ENCRYPTION_KEY_NAME",
           "encrypt.kms.key.id": "AWS_ENCRYPTION_KEY_ARN",
           "encrypt.kms.type": "aws-kms"
          },
        "onFailure": "ERROR,NONE"
      }
    ]
  } 
}'
```

DeveloperRead role on Schema Registry principal gives read access to a KEK.

## Register Rule using Confluent Terraform provider

```sh
resource "confluent_schema_registry_kek" "encrypt_pci_kek" {
  name        = "encryptPCI"
  kms_type    = "aws-kms"
  mode        = "WRITEREAD"
  kms_key_id  = "AWS_ENCRYPTION_KEY_ARN"
  doc         = "AWS KMS Key to encrypt/decrypt the fields tagged as PCI data"
  shared      = false
  hard_delete = true
  params = {
        "KeyUsage" = "ENCRYPT_DECRYPT"
        "KeyState" = "Enabled"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}
```

We can check that everything is registered correctly by either executing

```shell
curl --request GET --url 'https://psrc-8qmnr.eu-west-2.aws.confluent.cloud/subjects/customers-value/versions/latest' --header 'Authorization: Basic enc0d3denc0d3denc0d3denc0d3denc0d3d' | jq
```

Or from the Confluent Cloud UI, by navigating to Environment - Encryption Rules 

## Producer/Consumer Configuration

We need to adjust the configuration by updating the following in the Producer/Consumer props files

```properties
# Encryption + AWS Credentials (this is the access key we created in the IAM section of this tutorial) 

rule.executors._default_.param.access.key.id=<AWS User Access Key ID>
rule.executors._default_.param.secret.access.key=<AWS User Access Key Secret>

# Required since we created schemas beforehand with Terraform

use.latest.version=true
auto.register.schemas=false
```