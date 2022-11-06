namespace Driver
{
    using System;
    using CSV;
    using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;
    public delegate System.Threading.Tasks.Task<Microsoft.Quantum.Simulation.Core.QVoid> RunQop(QCTraceSimulator sim, long n, bool isControlled);

    public class Driver
    {
        public static void Main(string[] args)
        {
        }

        private static QCTraceSimulator GetTraceSimulator(bool full_depth)
        {
            var config = new QCTraceSimulatorConfiguration();
            return new QCTraceSimulator(config);
        }
        
        private static void SingleResourceTest<TypeQop>(RunQop runner, int n, bool isControlled, bool full_depth)
        {
            QCTraceSimulator estimator = GetTraceSimulator(full_depth);
            var res = runner(estimator, n, isControlled).Result;
            string thisCircuitCosts = estimator.ToString;
            Console.WriteLine(thisCircuitCosts);
        }
    }
}
