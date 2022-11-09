namespace Driver
{
    open Microsoft.Quantum.Crypto.Tests.Isogenies;
    open Microsoft.Quantum.Crypto.Fp2Arithmetic;
    open Microsoft.Quantum.Crypto.Isogenies;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Crypto.Basics;
    open Microsoft.Quantum.Crypto.Arithmetic;
    open Microsoft.Quantum.Crypto.ModularArithmetic;
    open Microsoft.Quantum.Crypto.EllipticCurves;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;


    operation FixedEllipticCurveSignedWindowedPointAdditionEstimator(nQubits : Int, isControlled : Bool) : Unit {
        mutable modulus = 0L;
        mutable basePoint = ECPointClassical(0L,0L,false,0L);
        mutable curve = ECCurveWeierstrassClassical(0L, 0L, 0L);
        let (tempCurve, tempPoint, _, _) = TenBitCurve(); 
        set curve = tempCurve;
        set basePoint = tempPoint;
    }
}
