import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import minimize

# Define the piecewise equations
def equation1(x, a1, b1, c1):
    return a1 * x**2 + b1 * x + c1

def equation2(x, a2, b2, c2):
    return a2 * x**2 + b2 * x + c2


# Gradient functions
def gradient1(x, a1, b1):
    return 2 * a1 * x + b1

def gradient2(x, a2, b2):
    return 2 * a2 * x + b2




# ===============================================================================
# Read data from Excel
file_path = 'li_ion_battery_charging_curve_short.xlsx'
df = pd.read_excel(file_path, header=None)
x_data = df.iloc[:, 0].values
y_data = df.iloc[:, 1].values



# ===============================================================================
# Initial guesses for coefficients
coefficient_init_guess1 = [0.5, 0.5, 0.5]  # initial guesses for a1, b1, c1
coefficient_init_guess2 = [0.5, 0.5, 0.5]  # initial guesses for a2, b2, c2


# Guesses for optimal_x0 and optimal_x1 (adjust these based on your data characteristics)
optimal_x0_guess = 100

param_init_guess = coefficient_init_guess1 + coefficient_init_guess2  + [optimal_x0_guess]

# Define the piecewise function for fitting
def piecewise_function(x, params):
    a1, b1, c1, a2, b2, c2, x0 = params
    
    condition1 = x <= x0
    condition2 = (x > x0)
    piecewise_func = np.piecewise(x, [condition1, condition2],
                               [lambda x: equation1(x, a1, b1, c1),
                                lambda x: equation2(x, a2, b2, c2)])
    
    return piecewise_func

# Objective function to minimize (sum of squared residuals)
def objective_func(params):
    y_model_result = piecewise_function(x_data, params)
    return np.sum((y_data - y_model_result) ** 2)

print(objective_func(param_init_guess))

# Constraints function (custom constraints)
def constraints_equ(params):
    a1, b1, c1, a2, b2, c2, x0 = params
    return [
        equation1(x0, a1, b1, c1) - equation2(x0, a2, b2, c2),
        gradient1(x0, a1, b1) - gradient2(x0, a2, b2),
    ]

# Define constraints in the format required by `minimize`
constraints = [
    {'type': 'eq', 'fun': lambda params: constraints_equ(params)[0]},
    {'type': 'eq', 'fun': lambda params: constraints_equ(params)[1]}
]

# Bounds for the parameters
bounds = ((-50, 50), (-50, 50), (-50, 50), (-50, 50), (-50, 50), (-50, 50), (0, len(x_data)))


# # Callback function to print the objective function value every 100 iterations
# iteration_count = 0
# def callback(params):
#     global iteration_count
#     iteration_count += 1
#     if iteration_count % 1 == 0:
#         print(f"Iteration {iteration_count}: Objective function value = {objective_func(params)}")


# Optimize using minimize
result = minimize(
    objective_func,
    param_init_guess,
    method='SLSQP',
    bounds=bounds,
    constraints=constraints,
    options={
        'maxiter': 10e6,       # Maximum number of iterations
        'tol': 1e-9,           # Tolerance for convergence
        'disp': True           # Display optimization progress
    }
)
print(result)

# Extract fitted parameters
a1, b1, c1, a2, b2, c2, x0 = result.x

# Generate fitted curves for plotting
x_fit = np.linspace(min(x_data), max(x_data), 1000)
y_fit = piecewise_function(x_fit, result.x)

# Display fitted parameters
print(objective_func(result.x))
print("Fitted Parameters:")
print(f"a1: {a1}, b1: {b1}, c1: {c1}")
print(f"a2: {a2}, b2: {b2}, c2: {c2}")


# Plotting
plt.figure(figsize=(10, 6))
plt.scatter(x_data, y_data, label='Original Data', color='blue')
plt.plot(x_fit[x_fit <= x0], y_fit[x_fit <= x0], 'r-', label='Equation 1')
plt.plot(x_fit[(x_fit > x0) ], y_fit[(x_fit > x0)], 'g-', label='Equation 2')
plt.xlabel('X Data')
plt.ylabel('Y Data')
plt.title('Piecewise Best-Fit Equations')
plt.legend()
plt.grid(True)
plt.show()











