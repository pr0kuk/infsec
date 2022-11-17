namespace Driver
{
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;

    function 10Curve () : (ECCurveWeierstrassClassical, ECPointClassical, BigInt, String){
        let modulus = 661L;
        let a = 3L;
        let b = 7L;
        let Gx = 474L;
        let Gy = 312L;
        let order = 665L;
        return (ECCurveWeierstrassClassical(a, b, modulus), ECPointClassical(Gx, Gy, true, modulus), order, "10 bit test curve");
    }

    operation ClearRegister(register:Qubit[]):Unit {
        ResetAll(register);
    }

    operation ControlledOp<'T>(isControlled : Bool, op : ('T => Unit is Ctl), parameters : 'T) : Unit {
        op(parameters);
    }

    operation FixedEllipticCurveSignedWindowedPointAdditionEstimator(nQubits : Int, isControlled : Bool) : Unit {
        let (tempCurve, tempPoint, _, _) = 10Curve(); 
        set curve = tempCurve;
        set basePoint = tempPoint;
        set modulus = curve::modulus;
        let windowSize = OptimalPointAdditionWindowSize(nQubits);
        use register = Qubit[2 * nQubits + windowSize] {	
            let points = PointTable(basePoint, 
                ECPointClassical(0L, 0L, false, modulus),
                curve,
                windowSize
            ) + [MultiplyClassicalECPoint(basePoint, curve, 2L^windowSize)];

            let xs = LittleEndian(register[0 .. nQubits - 1]);
            let ys = LittleEndian(register[nQubits .. 2 * nQubits - 1]);
            let address = register[2 * nQubits .. 2 * nQubits + windowSize - 1];

            let qPoint = ECPointMontgomeryForm(MontModInt(modulus,xs),MontModInt(modulus, ys));
            ControlledOp(isControlled, SignedWindowedEllipticCurvePointAdditionLowWidth, (points, address, qPoint));
            ClearRegister(register);
        }
    }
}
