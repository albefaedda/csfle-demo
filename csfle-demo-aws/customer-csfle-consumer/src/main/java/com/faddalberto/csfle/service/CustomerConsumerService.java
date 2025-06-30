package com.faddalberto.csfle.service;

import com.faddalberto.csfle.consumer.CustomerConsumer;

import java.util.Properties;

public class CustomerConsumerService {

    private final String CUSTOMERS_TOPIC = "customers";

    private CustomerConsumer consumer;

    public CustomerConsumerService(Properties properties) {
        this.consumer = new CustomerConsumer(CUSTOMERS_TOPIC, properties);
    }

    public void execute() {
        consumer.consume();
        consumer.close();
    }
}
