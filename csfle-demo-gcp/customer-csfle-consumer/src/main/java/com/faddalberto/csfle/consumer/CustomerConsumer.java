package com.faddalberto.csfle.consumer;

import com.faeddalberto.csfle.model.Customer;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Duration;
import java.util.Collections;
import java.util.Properties;

public class CustomerConsumer {

    private static final Logger logger = LoggerFactory.getLogger(CustomerConsumer.class);

    private final Consumer<String, Customer> consumer;

    private final String topic;

    public CustomerConsumer(String topic, Properties properties) {
        this.consumer = new KafkaConsumer<>(properties);
        this.topic = topic;
    }

    public void consume() {
        consumer.subscribe(Collections.singletonList(topic));

        while(true) {
            ConsumerRecords<String, Customer> customerRecords = consumer.poll(Duration.ofMillis(100));
            for (ConsumerRecord<String, Customer> customerRecord : customerRecords) {
                Customer customer = customerRecord.value();
                logger.info("Customer Id: {}, Customer name: {}, Customer email: {}, Customer address: {}, Customer credit card: {} ",
                        customerRecord.key(),
                        customer.getCustomerName(),
                        customer.getCustomerEmail(),
                        customer.getCustomerAddress(),
                        customer.getCardNumber());
            }
            consumer.commitAsync();
        }
    }

    public void close() {
        consumer.close();
    }
}
