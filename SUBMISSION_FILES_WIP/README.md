# Bi-Objective Travelling Thief Problem

## Deliverables

Problem deliverables are located in the **Submissions** directory.

## Installation

Install all required dependencies:

```
pip install -r requirements.txt
```

## Reproducing Outputs
### 1. Build the Cython extension
```
cd TSP_CYTHON
python setup.py build_ext --inplace
```
If any issues in later steps, use TSP_CYTHON2 instead, then:
```
cd TSP_CYTHON2
python setup.py build_ext --inplace
```
Make sure to update the notebook (TTP.ipynb) to point to the correct folder if you switch.

### 2. Open and run the notebook:
Execute all cells to reproduce the results.
```
TTP.ipynb
```

## Generating the Plots

Open and run the notebook:

```
evaluate.ipynb
```
