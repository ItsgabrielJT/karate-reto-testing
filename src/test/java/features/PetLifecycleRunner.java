package features;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;

class PetLifecycleRunner {

    @Test
    void testPetLifecycle() {
        Results results = Runner.path("classpath:features/pet")
                // parallel(N) es seguro porque cada escenario crea su propio pet
                // via create-pet.feature (UUID único por llamada, sin estado compartido)
                .parallel(5);
        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
