namespace Driver
{
    using System;
    using CSV;
    using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

    public class Driver
    {
        public delegate System.Threading.Tasks.Task<Microsoft.Quantum.Simulation.Core.QVoid> Oper(QCTraceSimulator sim, long n, bool isControlled);
        public static void Main(string[] args)
        {
            EstEllipticCurve(10);
        }
        
        public static void EstEllipticCurve(int modulus)
        {
            //Debug.Print();
            Est(
                FixedEllipticCurveSignedWindowedPointAdditionEstimator.Run,
                modulus,
                false,
                false);
        }
        private static QCTraceSimulator GetSimulatorInfo(bool full_depth)
        {
            var config = new QCTraceSimulatorConfiguration();
            config.UseDepthCounter = true;
            config.UseWidthCounter = true;
            config.UsePrimitiveOperationsCounter = true;
            if (full_depth)
            {
                config.TraceGateTimes[PrimitiveOperationsGroups.CNOT] = 1;
                config.TraceGateTimes[PrimitiveOperationsGroups.Measure] = 1;
                config.TraceGateTimes[PrimitiveOperationsGroups.QubitClifford] = 1;
            }
            return new QCTraceSimulator(config);
        }
    
        private static void PrintHeader(int modulus, bool isControlled, bool full_depth)
        {
            string header = string.Empty;
            header += " operation, CNOT count, 1-qubit Clifford count, T count, R count, M count, ";
            if (full_depth)
                header += "Full depth, ";
            else
                header += "T depth, ";
            header += "initial width, extra width, comment, size";
            Console.WriteLine(header);
        }
        
        private static void Est(Oper runner, int n, bool isControlled, bool full_depth)
        {
            PrintHeader(n, isControlled, full_depth);
            QCTraceSimulator sim = GetSimulatorInfo(full_depth);
            var res = runner(sim, n, isControlled).Result;
            string thisCircuitCosts = Parser.CSV(sim.ToCSV(), string.Empty, false, string.Empty, false, string.Empty);
            thisCircuitCosts += $"{n}";
            Console.WriteLine(thisCircuitCosts);
        }
    }
}
