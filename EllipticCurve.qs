namespace Driver
{
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Diagnostics;

    function Curve10 () : (ECCurveWeierstrassClassical, ECPointClassical, BigInt, String){
        let modulus = 661L;
        let a = 3L;
        let b = 7L;
        let Gx = 474L;
        let Gy = 312L;
        let order = 665L;
        return (ECCurveWeierstrassClassical(a, b, modulus), ECPointClassical(Gx, Gy, true, modulus), order, "10 bit test curve");
    }

    function Curve256 () : (ECCurveWeierstrassClassical, ECPointClassical, BigInt, String){
        let modulus = 115792089210356248762697446949407573530086143415290314195533631308867097853951L;
        let b = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604bL;
        let a = modulus - 3L;
        let Gx = 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296L;
        let Gy = 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5L;
        let order = 115792089210356248762697446949407573529996955224135760342422259061068512044369L;
        return (ECCurveWeierstrassClassical(a, b, modulus), ECPointClassical(Gx, Gy, true, modulus), order, "NIST P-256");
    }

    operation ClearRegister(register:Qubit[]):Unit {
        for idx in 0..Length(register)-1 {
            AssertMeasurementProbability([PauliZ],[register[idx]],Zero,0.0,"n/a",0.5);
        }	
        ResetAll(register);
    }

    operation ControlledOp<'T>(isControlled : Bool, op : ('T => Unit is Ctl), parameters : 'T) : Unit {
        if (isControlled){
            use controls = Qubit[1] {
                (Controlled op)(controls, (parameters));
                ClearRegister(controls);
            }
        } else {
            op(parameters); }
    }

    operation EllipticCurvePointAdditionEstimator(nQubits : Int, isControlled : Bool) : Unit {
        mutable modulus = 0L;
        mutable basePoint = ECPointClassical(0L,0L,false,0L);
        mutable curve = ECCurveWeierstrassClassical(0L, 0L, 0L);
        if (nQubits == 10){
            let (tempCurve, tempPoint, _, _) = Curve10(); 
            set curve = tempCurve;
            set basePoint = tempPoint;
        } elif (nQubits == 256){
            let (tempCurve, tempPoint, _, _) = Curve256(); 
            set curve = tempCurve;
            set basePoint = tempPoint; 
        } else {
            Fact(false, $"Wrong n");
        }
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
            ControlledOp(isControlled, EllipticCurvePointAddition, (points, address, qPoint));
            ClearRegister(register);
        }
    }

    operation EllipticCurvPointAddition(points : ECPointClassical[], address : Qubit[], point : ECPointMontgomeryForm) : Unit {
        use addressAncilla = Qubit() {
            let addressLength = Length(address);
            let unsignedAddress = address[0 .. addressLength - 2];
            let leftAddress = LittleEndian(unsignedAddress + [addressAncilla]);
            let signQubit = address[addressLength - 1];
            X(signQubit);
            let modulus = point::xs::modulus;
            let nQubits = Length(point::xs::register!);
            use zQubit = Qubit() {

                // set the point(x2-x1, y2-y1)
                use ancillaPointQubits = Qubit[2 * nQubits] {
                    let ancillaPoint = ECPointMontgomeryForm(
                        MontModInt(modulus, LittleEndian(ancillaPointQubits[0..nQubits - 1])),
                        MontModInt(modulus, LittleEndian(ancillaPointQubits[nQubits .. 2 * nQubits - 1]))
                    );
                    (Controlled EqualLookup)(controls, (points, ECPointWrite(_, ancillaPoint, zQubit), leftAddress));
                    (Controlled ModularNegMontgomeryForm)([signQubit], (ancillaPoint::ys));
                    (Controlled Adjoint ModularAddMontgomeryForm)(controls, (ancillaPoint::xs, point::xs));
                    (Controlled Adjoint ModularAddMontgomeryForm)(controls, (ancillaPoint::ys, point::ys));
                    (Controlled ModularNegMontgomeryForm)([signQubit], (ancillaPoint::ys));
                    (Controlled Adjoint EqualLookup)(controls, (points, EncodeClassicalECPointInQuantum(_, ancillaPoint), leftAddress));
                }

                use lambdaqubits = Qubit[nQubits] {
                    let lambdas = MontModInt(modulus, LittleEndian(lambdaqubits));
                    // compute lambda
                    (Controlled ModularDivideAndAddMontgomeryForm)(controls + [zQubit], (point::xs, point::ys, lambdas));
                    // y2-y1 <- lambda * (x2 - x1)
                    ModularMulAndXorMontgomeryForm(point::xs, lambdas, point::ys);
                    // x2 - x1 += 3x1 ( = x2 + 2x1)
                    use ancillaPointQubits = Qubit[nQubits] {
                        let xsMMI = MontModInt(modulus, LittleEndian(ancillaPointQubits[0..nQubits - 1]));
                        (Controlled EqualLookup)(controls, (points, _ClassicalECPointFormat(_, xsMMI), leftAddress));
                        (Controlled ModularAddMontgomeryForm)(controls, (xsMMI, point::xs));
                        (Controlled Adjoint EqualLookup)(controls, (points, _ClassicalECPointFormat(_, xsMMI), leftAddress));
                    }
                    // x2 + 2x1 += lambda^2 ( = x1 - x3)
                    (Adjoint ModularSquMontgomeryFormWindowedGeneric)(ModularAddMontgomeryForm(_, point::xs), lambdas);
                    // x1 - x3 *= lambda
                    ModularMulAndAddMontgomeryForm(point::xs, lambdas, point::ys);
                    // compute lambda
                    (Adjoint Controlled ModularDivideAndAddMontgomeryForm)(controls + [zQubit], (point::xs, point::ys, lambdas));
                }

                //add or sub constant p
                use ancillaPointQubits = Qubit[2 * nQubits + 1] {
                    let ancillaPoint = ECPointMontgomeryForm(
                        MontModInt(modulus, LittleEndian(ancillaPointQubits[0..nQubits - 1])),
                        MontModInt(modulus, LittleEndian(ancillaPointQubits[nQubits .. 2 * nQubits - 1]))
                    ); 
                    (Controlled EqualLookup)(controls, (points, EncodeClassicalECPointInQuantum(_, ancillaPoint), leftAddress));
                    (Controlled ModularNegMontgomeryForm)([signQubit], (ancillaPoint::ys));
                    (Controlled Adjoint ModularAddMontgomeryForm)(controls, (ancillaPoint::xs, point::xs));
                    (Controlled Adjoint ModularAddMontgomeryForm)(controls, (ancillaPoint::ys, point::ys));
                    (Controlled ModularNegMontgomeryForm)(controls + [zQubit], (point::xs));
                    (Controlled ModularNegMontgomeryForm)([signQubit], (ancillaPoint::ys));
                    (Controlled Adjoint EqualLookup)(controls, (points, ECPointWrite(_, ancillaPoint, zQubit), leftAddress));
                }
            }
        }
    }

}
