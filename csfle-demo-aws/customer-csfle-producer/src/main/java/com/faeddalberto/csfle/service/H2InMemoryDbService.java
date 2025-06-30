package com.faeddalberto.csfle.service;

import com.faeddalberto.csfle.model.Customer;

import org.hsqldb.server.Server;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class H2InMemoryDbService {

    private final String url;

    private final String username;

    private final String password;

    public H2InMemoryDbService() {

        this.url = "jdbc:hsqldb:hsql://localhost:9001/tmpDb;mem:tmpDb;sql.syntax_mys=true";
        this.username = "SA";
        this.password = "";

        init();
    }

    private void init() {
        Server server = new Server();
        server.setDatabaseName(0,"tmpDb");
        server.setDatabasePath(0,"mem:tmpDb");
        server.setPort(9001);
        server.start();


        try {
            Connection con = DriverManager.getConnection(url, username, password);
            Statement st = con.createStatement();

            String query = "CREATE TABLE customers (\n" +
                "    id varchar(20) NOT NULL,\n" +
                "    customer_name varchar(60),\n" +
                "    customer_email varchar(60),\n" +
                "    customer_address varchar(80),\n" +
                "    card_number varchar(220),\n" +
                "    level varchar(10),\n" +
                "    PRIMARY KEY (id) \n" +
                ");";

            st.executeUpdate(query);

            query = "INSERT INTO customers (id, customer_name, card_number, customer_email, customer_address, level) values \n" +
                    "('linetbrown67', 'Linet Brown', '3455 5606 6764 114', 'lpedroni0@whitehouse.gov', '56 Di Loreto Terrace', 'platinum'),\n" +
                    "('poliver85', 'Peter Oliver', '4066 6385 0323 6028', 'poliver@google.com', '593 Thompson Drive', 'gold'),\n" +
                    "('gregv', 'Greg Vane', '5366 2000 0085 6156', 'gvane@skyrock.com', '1 Gale Court', 'silver'),\n" +
                    "('jejiri', 'Jeremy Jiri', '3455 5697 7661 474', 'jjiri@discovery.com', '2 Declaration Pass', 'bronze'),\n" +
                    "('jubrad', 'Julie Bradnum', '5361 2000 0061 9930', 'jbradnum@so-net.net', '32 Bluestem Avenue', 'gold'),\n" +
                    "('gaunight', 'Gaurav Night', '4567 8570 084 31', 'gnight@google.com', '105 Duncan Piece', 'silver'),\n" +
                    "('amalee', 'Amanda Leeworth', '3455 5624 6208 172', 'amleeworth@microsoft.com', '10 Stonewell Grove', 'gold'),\n" +
                    "('the_l_champion', 'Lisa Champion', '4567 8574 6705 5042', 'lchampion@jetblue.net', '71 Felmersham Court', 'silver'),\n" +
                    "('bobby_w', 'Bob West', '3455 5639 9209 084', 'bob.west@gmail.com', '68 Skylark Ridge', 'bronze');";

            st.executeUpdate(query);
            st.close();
            con.close();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public List<Customer> collectCustomers()  {
        List<Customer> customers = new ArrayList<>();
        try{
            Connection con = DriverManager.getConnection(url, username, password);
            Statement st = con.createStatement();

            ResultSet resultSet = st.executeQuery("SELECT * from customers");
            while (resultSet.next()) {
                Customer customer = new Customer();
                customer.setId(resultSet.getString("id"));
                customer.setCustomerName(resultSet.getString("customer_name"));
                customer.setCustomerAddress(resultSet.getString("customer_address"));
                customer.setCustomerEmail(resultSet.getString("customer_email"));
                customer.setCardNumber(resultSet.getString("card_number"));
                customers.add(customer);
            }

            resultSet.close();

            st.close();
            con.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        return customers;
    }
}
