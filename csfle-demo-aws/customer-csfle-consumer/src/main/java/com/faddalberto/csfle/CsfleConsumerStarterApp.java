package com.faddalberto.csfle;

import com.faddalberto.csfle.service.CustomerConsumerService;
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
public class CsfleConsumerStarterApp implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(CsfleConsumerStarterApp.class);

    private final ConfigurableApplicationContext applicationContext;

    public CsfleConsumerStarterApp(ConfigurableApplicationContext applicationContext) {
        this.applicationContext = applicationContext;
    }

    public static void main(String[] args) throws Exception {
        SpringApplication.run(CsfleConsumerStarterApp.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        final Properties props = CsfleConsumerStarterApp.loadProperties("configuration.properties");
        CustomerConsumerService service = new CustomerConsumerService(props);
        service.execute();
    }

    public static Properties loadProperties(String fileName) throws IOException {
        logger.info("Loading properties to connect to Confluent Cloud Cluster...");
        final Properties envProps = new Properties();

        ClassLoader classloader = Thread.currentThread().getContextClassLoader();
        InputStream is = classloader.getResourceAsStream(fileName);
        envProps.load(is);
        if (is != null) is.close();

        logger.info("Props size: {}", envProps.size());
        logger.info("Properties: {}", getPropertyAsString(envProps));

        logger.info("...properties loaded successfully");

        return envProps;
    }

    public static String getPropertyAsString(Properties prop) throws IOException {
        StringWriter writer = new StringWriter();
        prop.store(new PrintWriter(writer), "");
        return writer.getBuffer().toString();
    }
}
