# Client-Side Field Level Encryption (CSFLE) with GCP KMS

## Prerequisites

- Confluent Cloud cluster with Advanced Stream Governance package
- For clients, Confluent Platform 7.4.5, 7.5.4, 7.6.1 or higher are required.

## Goal
We will produce personal data to Confluent Cloud in the following form

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

## GCP KMS

In the GCP console, navigate to Security - Key Management.
Create a Key Ring and add a key to it. Copy the key's resource name as shown.

Resource name: `af-csfle-en-de-key`

### Grant Service Account Access
⚠️ Important: Ensure you grant your Service Account the Cloud KMS CryptoKey Encrypter/Decrypter role on the Google KMS key you just created, otherwise you will not be able to use the key to Encrypt/Decrypt your data!
Select the key, and from the side panel assign the role to your service-account

### Generate Service Account Credentials

Navigate to IAM - Service Accounts and find your Service Account. 

Download the JSON credentials file for the service account you'd like to use (If you don't already have one, just create a new Key in JSON format, and it will automatically be downloaded to your computer).

You will use the content found here in the Producer/Consumer properties files for client.id, client.email, private.key.id, and private.key

## Create Tag
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
curl --request POST --url 'https://psrc-ze8rp68.europe-west2.gcp.confluent.cloud/subjects/customers-value/versions' \ 
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

## Register Rule

We can now register the Data Contract Rule, to encrypt/decrypt the PCI data

```shell
curl --request POST --url 'https://psrc-ze8rp68.europe-west2.gcp.confluent.cloud/subjects/customers-value/versions' --header 'Authorization: Basic enc0d3denc0d3denc0d3denc0d3denc0d3d' --header 'Content-Type: application/vnd.schemaregistry.v1+json' \
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
           "encrypt.kek.name": "af-csfle-en-de-key",
           "encrypt.kms.key.id": "projects/<project-name>/locations/<region-name>/keyRings/<key-ring-name>/cryptoKeys/<key-name>",
           "encrypt.kms.type": "gcp-kms"
          },
        "onFailure": "ERROR,NONE"
      }
    ]
  } 
}'
```

We can check that everything is registered correctly by either executing

```shell
curl --request GET --url 'https://psrc-ze8rp68.europe-west2.gcp.confluent.cloud/subjects/customers-value/versions/latest' --header 'Authorization: Basic enc0d3denc0d3denc0d3denc0d3denc0d3d' | jq
```

Or from the Confluent Cloud UI, by navigating to Environment - Encryption Rules 

