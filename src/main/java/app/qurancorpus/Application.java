package app.qurancorpus;

import static io.micronaut.runtime.Micronaut.run;

public class Application {

    public static void main(String[] args) {
        run(Application.class, args)
            .getEnvironment()
            .getActiveNames()
            .forEach(env -> System.out.println("Active environment: " + env));
    }
}