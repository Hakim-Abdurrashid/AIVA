# AIVA
American Computing Machinery's Autonomous Intelligent Verification Agents GitHub Repository.

## Folder Structure
```text
aiva-agent-core/
├── src/
│   ├── parser/                  # Specification ingestion and structured requirement extraction
│   ├── orchestration/           # LLM agent orchestration, prompt templates, and workflow logic
│   ├── generator/               # Verification plan, test, assertion, and coverage generation
│   ├── simulator/               # Automated simulator invocation, error recovery, and result parsing
│   ├── feedback/                # Coverage-feedback ingestion and iterative test-refinement loop
│   └── interface/               # Platform interfaces including CLI, API, or lightweight UI
├── tests/
│   ├── unit/                    # Unit tests for parser, generator, and orchestration modules
│   └── integration/             # End-to-end workflow automation tests
├── configs/                     # Reproducible run configurations, environment settings, and logging profiles
├── docs/                        # Platform architecture documents, module interfaces, and user guides
└── requirements.txt             # Python environment and package dependencies
