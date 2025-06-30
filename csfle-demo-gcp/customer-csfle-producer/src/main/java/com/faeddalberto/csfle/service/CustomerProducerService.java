package com.faeddalberto.csfle.service;

import com.faeddalberto.csfle.model.Customer;
import com.faeddalberto.csfle.producer.CustomerProducer;

import java.util.List;
import java.util.Properties;

public class CustomerProducerService {

    private final String CUSTOMERS_TOPIC = "customers";

    private CustomerProducer customerProducer;

    public CustomerProducerService(Properties properties) {
        this.customerProducer = new CustomerProducer(CUSTOMERS_TOPIC, properties);
    }

    public void execute(List<Customer> customerList) {
        for (Customer customer : customerList) {
            customerProducer.produce(String.valueOf(customer.getId()), customer);
        }
        customerProducer.close();
    }
}
