package com.faeddalberto.csfle;

import com.faeddalberto.csfle.service.CustomerProducerService;
import com.faeddalberto.csfle.service.DbService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.Properties;

@SpringBootApplication
public class CsfleProducerStarterApp implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(CsfleProducerStarterApp.class);

    private final ConfigurableApplicationContext applicationContext;

    public CsfleProducerStarterApp(ConfigurableApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    public static void main(String[] args) throws Exception {
        SpringApplication.run(CsfleProducerStarterApp.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        final Properties props = CsfleProducerStarterApp.loadProperties("configuration.properties");


        CustomerProducerService customerService = new CustomerProducerService(props);
        customerService.execute(DbService.collectCustomers());
    }

    public static Properties loadProperties(String fileName) throws IOException {
        final Properties envProps = new Properties();

        ClassLoader classloader = Thread.currentThread().getContextClassLoader();
        InputStream is = classloader.getResourceAsStream(fileName);
        envProps.load(is);
        if (is != null) is.close();

        System.out.println("Props size: " + envProps.size());
        System.out.println("Properties: " + getPropertyAsString(envProps));

        return envProps;
    }

    public static String getPropertyAsString(Properties prop) throws IOException {
        StringWriter writer = new StringWriter();
        prop.store(new PrintWriter(writer), "");
        return writer.getBuffer().toString();
    }
}
