from setuptools import setup, find_packages

setup(
    name='HRVAnalysisAgent',
    version='0.1',
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[
        "anthropic>=0.18.0",
        "numpy>=1.24.0",
        "scipy>=1.11.0",
        "scikit-learn>=1.3.0",
        "pandas>=2.0.0",
        "matplotlib>=3.7.0",
        "reportlab>=4.0.0",
        "joblib>=1.3.0",
        "python-dotenv>=1.0.0",
        "pyyaml>=6.0"
    ],
    entry_points={
        "console_scripts": [
            "run_analysis = scripts.run_analysis:main",
        ],
    },
)
