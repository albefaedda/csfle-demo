package com.faeddalberto.csfle.producer;

import com.faeddalberto.csfle.model.Customer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.Producer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.Properties;

public class CustomerProducer {

    private final Producer<String, Customer> producer;
    private final String topic;

    public CustomerProducer(String topic, Properties properties) {
        this.producer = new KafkaProducer<>(properties);
        this.topic = topic;
    }

    public void produce(String key, Customer customer) {
        final ProducerRecord<String, Customer> producerRecord = new ProducerRecord<>(topic, key, customer);
        producer.send(producerRecord);
    }

    public void close() {
        producer.close();
    }
}
