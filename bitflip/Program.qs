namespace Strathweb.Samples.QSharp.ErrorCorrection {

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
        mutable successCount1 = 0;
        mutable successCount2 = 0;
        mutable successCount3 = 0;

        for i in 1..runs {
            set successCount1 += WithAuxAndManualMeasurement() ? 1 | 0;
            set successCount2 += WithAuxAndAutomaticCorrection() ? 1 | 0;
            set successCount3 += WithParityMeasurement() ? 1 | 0;
        }

        Message("Auxiliary qubits and manual auxiliary register measurement: " 
                    + DoubleAsStringWithFormat(100. * IntAsDouble(successCount1) / IntAsDouble(runs), "N2") + " success rate");
        Message("Auxiliary qubits with no measurement and automatic correction: " 
                    + DoubleAsStringWithFormat(100. * IntAsDouble(successCount2) / IntAsDouble(runs), "N2") + " success rate");
        Message("No explicit auxiliary qubits with parity measurement: " 
                    + DoubleAsStringWithFormat(100. * IntAsDouble(successCount3) / IntAsDouble(runs), "N2") + " success rate");
    }

    operation Encode(register : Qubit[]) : Unit is Adj {
        CNOT(register[0], register[1]);
        CNOT(register[0], register[2]);
    }

    operation WithAuxAndManualMeasurement() : Bool {
        use register = Qubit[3];
        use auxilliary = Qubit[2];

        // start with arbitrary state on 1st qubit
        PrepareState(register[0]);

        // encode it over three qubits
        Encode(register);

        // simulate bit-flipping noise
        let error = DrawRandomInt(0, 2);
        X(register[error]);

        // transfer syndrome to auxilliary
        CNOT(register[0], auxilliary[1]);
        CNOT(register[1], auxilliary[1]);
        CNOT(register[1], auxilliary[0]);
        CNOT(register[2], auxilliary[0]);

        // correct errors
        let aux1 = ResultAsBool(M(auxilliary[0]));
        let aux2 = ResultAsBool(M(auxilliary[1]));

        if aux1 and not aux2 {
            X(register[2]);
        }
        elif aux1 and aux2 {
            X(register[1]);
        }
        elif not aux1 and aux2 {
            X(register[0]);
        }

        // decode back
        Adjoint Encode(register);

        // adjoint initial state to verify it went back to default
        Adjoint PrepareState(register[0]);
        let result = M(register[0]);
        let success = M(register[0]) == Zero;

        ResetAll(register + auxilliary);
        return success;
    }

    operation WithAuxAndAutomaticCorrection() : Bool {
        use register = Qubit[3];
        use auxilliary = Qubit[2];

        // start with arbitrary state on 1st qubit
        PrepareState(register[0]);

        // encode it over three qubits
        Encode(register);

        // simulate bit-flipping noise
        let error = DrawRandomInt(0, 2);
        X(register[error]);

        // transfer syndrome to auxilliary
        CNOT(register[0], auxilliary[1]);
        CNOT(register[1], auxilliary[1]);
        CNOT(register[1], auxilliary[0]);
        CNOT(register[2], auxilliary[0]);

        // correct errors
        CNOT(auxilliary[1], register[0]);
        CNOT(auxilliary[0], register[2]);
        CCNOT(auxilliary[0], auxilliary[1], register[0]);
        CCNOT(auxilliary[0], auxilliary[1], register[1]);
        CCNOT(auxilliary[0], auxilliary[1], register[2]);

        // decode back
        Adjoint Encode(register);

        // adjoint initial state to verify it went back to default
        Adjoint PrepareState(register[0]);
        let result = M(register[0]);
        let success = M(register[0]) == Zero;

        ResetAll(register + auxilliary);
        return success;
    }

    operation WithParityMeasurement() : Bool {
        use register = Qubit[3];

        // start with arbitrary state on 1st qubit
        PrepareState(register[0]);

        // encode it over three qubits
        Encode(register);

        // simulate bit-flipping noise
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
        Adjoint Encode(register);

        // adjoint initial state to verify it went back to default
        Adjoint PrepareState(register[0]);
        let result = M(register[0]);
        let success = M(register[0]) == Zero;

        ResetAll(register);
        return success;
    }

    operation PrepareState(q : Qubit) : Unit is Adj + Ctl {
        Rx(1. * PI() / 2., q);
        Ry(2. * PI() / 3., q);
        Rz(3. * PI() / 4., q);
    }
}