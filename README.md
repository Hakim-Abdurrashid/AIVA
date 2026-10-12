## Folder Structure
```text
aiva-verification-groundtruth/
├── rtl/
│   ├── starter/                 # Starter DUTs (counter, ALU, FSM, simple FIFO)
│   ├── intermediate/            # Intermediate DUTs (UART, round-robin arbiter, protocol controllers)
│   └── advanced/                # Advanced benchmark targets (AXI-Lite peripherals, RISC-V components)
├── specs/
│   ├── templates/               # Standardized specification templates with numbered requirements
│   └── documents/               # Natural-language specifications and expected behaviors for each DUT
├── verification/
│   ├── testbenches/             # Manually written reference testbenches
│   ├── assertions/              # Hand-crafted reference assertions and safety properties
│   ├── coverage/                # Reference functional coverage models
│   └── scoreboards/             # Reference verification scoreboards and expected-result checkers
├── defects/
│   └── seeded_defects/          # Intentionally incorrect versions of DUTs categorized by defect taxonomy
└── fpga/                        # Verification-oriented FPGA implementations, stimulus scripts, and constraints
