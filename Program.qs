namespace Strathweb.Samples.QSharp.BitFlipErrorCorrection {

    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Random;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    
    @EntryPoint()
    operation Main() : Unit {
        
        let runs = 4096;
        mutable successCount = 0;

        for i in 1..runs {
            use register = Qubit[3];

            // start with arbitrary state on 1st qubit
            PrepareState(register[0]);

            // encode it over three qubits
            CNOT(register[0], register[1]);
            CNOT(register[0], register[2]);

            // simulate bit -flipping noise
            let error = DrawRandomInt(0, 2);
            X(register[error]);

            // parity measurements Z₀Z₁ and Z₁Z₂
            let parityResult01 = ResultAsBool(Measure([PauliZ, PauliZ, PauliI], register));
            let parityResult12 = ResultAsBool(Measure([PauliI, PauliZ, PauliZ], register));

            if parityResult01 and not parityResult12 {
                X(register[0]);
            }
            elif parityResult01 and parityResult12 {
                X(register[1]);
            }
            elif not parityResult01 and parityResult12 {
                X(register[2]);
            }

            // decode back
            Adjoint CNOT(register[0], register[1]);
            Adjoint CNOT(register[0], register[2]);

            // adjoint initial state to verify it went back to default
            Adjoint PrepareState(register[0]);
            let result = M(register[0]);
            set successCount += M(register[0]) == Zero ? 1 | 0;

            ResetAll(register);
        }

        Message("Success rate: " 
                    + DoubleAsStringWithFormat(100. * IntAsDouble(successCount) / IntAsDouble(runs), "N2"));
    }

    operation PrepareState(q : Qubit) : Unit is Adj + Ctl {
        Rx(1. * PI() / 2., q);
        Ry(2. * PI() / 3., q);
        Rz(3. * PI() / 4., q);
    }
}