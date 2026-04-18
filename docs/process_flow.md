flowchart TD
A(["Splash screen"]) --> A1{"Terminal identity\n(device_identity_key)?"}
A1 -->|"not set"| DS["Device setup\nClaim terminal"]
A1 -->|"set"| B["Login / session restore"]
DS --> B
B --> C{"Shift status\nfrom API?"}

    C -->|"no open shift"| D["Open cash\nEnter float"]
    C -->|"shift open"| E(["Dashboard"])

    D --> E

    E --> F["Check-in"]
    E --> G["Check-out"]
    E --> H["Reports"]
    E --> I["Settings"]
    E --> J["Tap logout"]

    F --> F1["Step 1\nVehicle details"]
    F1 --> F2["Step 2\nBelongings"]
    F2 --> F3["Step 3\nCondition check"]
    F3 --> F4["Step 4\nSignature + print"]
    F4 --> F5(["Vehicle in"])
    F5 -->|"back to dashboard"| E

    G --> G1["Step 1\nScan QR / lookup"]
    G1 --> G2["Step 2\nVehicle review"]
    G2 --> G3["Step 3\nFee computation"]
    G3 --> G4["Step 4\nPayment + print"]
    G4 --> G5(["Vehicle out"])
    G5 -->|"back to dashboard"| E

    H --> H1["Today"]
    H --> H2["Transactions"]
    H --> H3["Cash"]

    I --> I1["Branch"]
    I --> I2["Printer"]
    I --> I3["Users"]

    J --> K{"Close cash\nfirst?"}

    K -->|"yes"| L["Password modal\nConfirm close cash"]
    K -->|"no"| O

    L --> M{"Password\ncorrect?"}
    M -->|"wrong"| N["Show error"]
    N -->|"retry"| L
    M -->|"correct"| P["Close cash\nSubmit tally"]
    P --> O

    O(["Logged out"]) -->|"back to login"| B

    style A fill:#3C3434,color:#fff,stroke:#3C3434
    style DS fill:#1C1C1A,color:#fff,stroke:#E87722
    style E fill:#3C3434,color:#fff,stroke:#3C3434
    style F5 fill:#2E7D52,color:#fff,stroke:#2E7D52
    style G5 fill:#2E7D52,color:#fff,stroke:#2E7D52
    style O fill:#D64045,color:#fff,stroke:#D64045
    style D fill:#E8831A,color:#fff,stroke:#E8831A
    style P fill:#E8831A,color:#fff,stroke:#E8831A
    style L fill:#E8831A,color:#fff,stroke:#E8831A
    style N fill:#D64045,color:#fff,stroke:#D64045
