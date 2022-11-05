namespace Driver
{
    using System;
    using CSV;
    using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

    public class Driver
    {
        public static void Main(string[] args)
        {
        }

        private static void SingleResourceTest()
        {
            QCTraceSimulator estimator = GetTraceSimulator(full_depth);
            var res = runner(estimator, n, isControlled).Result;
            string thisCircuitCosts = estimator.ToString;
            Console.WriteLine(thisCircuitCosts);
        }
    }
}
