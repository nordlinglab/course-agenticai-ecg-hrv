from src.orchestrator import HRVAnalysisOrchestrator
import argparse

def main():
    parser = argparse.ArgumentParser(description="Run HRV Analysis Agent")
    parser.add_argument("--input", required=True, help="Path to ECG or HRV file")
    parser.add_argument("--output", required=True, help="Output folder for reports")
    args = parser.parse_args()

    agent = HRVAnalysisOrchestrator()
    agent.run(args.input, args.output)

if __name__ == "__main__":
    main()
