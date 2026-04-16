package features;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;

class PetLifecycleRunner {

    @Test
    void testSmoke() {
        Results results = Runner.path("classpath:features/pet")
                .tags("@smoke")
                .parallel(1);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }

    @Test
    void testFullLifecycle() {
        Results results = Runner.path("classpath:features/pet")
                .tags("@lifecycle", "~@ignore")
                .parallel(5);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }

    @Test
    void testNegative() {
        Results results = Runner.path("classpath:features/pet/pet-negative.feature")
                .tags("@negative")
                .parallel(2);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
