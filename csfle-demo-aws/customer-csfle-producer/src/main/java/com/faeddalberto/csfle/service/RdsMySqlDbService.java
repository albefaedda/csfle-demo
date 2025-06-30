package com.faeddalberto.csfle.service;

import com.faeddalberto.csfle.model.Customer;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RdsMySqlDbService {

    private final String jdbcUrl;

    private final String username;

    private final String password;

    public RdsMySqlDbService() {
        this.jdbcUrl = "jdbc:mysql://<DB_HOST>:3306/ecommerce";
        this.username = "<USERNAME>";
        this.password = "<PASSWORD>";
    }

    public List<Customer> collectCustomers() throws ClassNotFoundException {
        List<Customer> customers = new ArrayList<>();

        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection connection = DriverManager.getConnection(jdbcUrl, username, password)) {
            try (Statement statement = connection.createStatement();
                 ResultSet resultSet = statement.executeQuery("select * from customers;")) {
                while (resultSet.next()) {
                    Customer customer = new Customer();
                    customer.setId(resultSet.getString("id"));
                    customer.setCustomerName(resultSet.getString("customer_name"));
                    customer.setCustomerAddress(resultSet.getString("customer_address"));
                    customer.setCustomerEmail(resultSet.getString("customer_email"));
                    customer.setCardNumber(resultSet.getString("card_number"));
                    customers.add(customer);
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return customers;
    }

}
