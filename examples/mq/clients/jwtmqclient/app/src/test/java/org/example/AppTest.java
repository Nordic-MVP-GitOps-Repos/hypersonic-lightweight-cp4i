package org.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AppTest {
    @Test void testMqConnection() {
        MQJWTExample classUnderTest = new MQJWTExample();
      
        try {
            classUnderTest.callMq();            
        } catch (Exception e) {
            e.printStackTrace();
            fail(e);
        }
    }
}
