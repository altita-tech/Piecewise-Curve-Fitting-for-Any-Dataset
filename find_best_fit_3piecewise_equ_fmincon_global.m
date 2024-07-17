clc
close all
clear all

% Load data
filename = 'dataset.xlsx';
data = readtable(filename, 'Range', 'A:B');
x_data = table2array(data(:, 1));
y_data = table2array(data(:, 2));

% Plot data
% % [left, bottom, width, height]
figure('Position', [100, 100, 800, 600]);
plot(x_data, y_data, 'ko', 'DisplayName', 'Original Data');
hold on
grid on
figure_name = "fmincon scan: 3 piecewise best-fit equation";
title(figure_name)
xlabel("X Data")
ylabel("Y Data")


%% Machine Learning & system optimization
% Equation 1: y1 = a1*x^2 + b1*x + c1
% Equation 2: y2 = a2*x^2 + b2*x + c2
% Equation 3: y3 = a3*x^2 + b3*x + c3
% Breakpoints: min(x_data) < optimal_x0 < optimal_x1 < max(x_data)

% Initial guess for the coefficients
initial_guess = [0.5, 0.5, 0.5, ...
                 0.5, 0.5, 0.5, ...
                 0.5, 0.5, 0.5];

% Optimization options
options = optimoptions('fmincon', 'Display', 'off', 'Algorithm', 'sqp');

% Define bounds for the coefficients and breakpoints
COEFFICIENT_VAL_MIN = -10;
COEFFICIENT_VAL_MAX = 10;
lb = [COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, ...
      COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, ...
      COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN];
ub = [COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, ...
      COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, ...
      COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX];

% Initialize variables
update_optimal_counter = 0;
optimal_params = initial_guess;
optimal_x1_final = 0;
optimal_x2_final = 0;
min_cost_func_result = inf;
% Loop over potential breakpoints
scan_step = 2;
for optimal_x1 = min(x_data) : scan_step : max(x_data)
    for optimal_x2 = optimal_x1 : scan_step : max(x_data)
        % Define the objective function
        optimal_breakpoints = [optimal_x1, optimal_x2];
        objective = @(params) objective_function(params, optimal_breakpoints, x_data, y_data);
        
        % Define the nonlinear constraints
        nonlcon = @(params) continuity_constraints(params, optimal_breakpoints);
    
        % Optimization
        params_result = fmincon(objective, initial_guess, [], [], [], [], lb, ub, nonlcon, options);
        
        % Calculate cost for current optimal_x0
        cost_func_result = objective_function(params_result, optimal_breakpoints, x_data, y_data);
        
        % Update optimal parameters if a lower cost is found
        if cost_func_result < min_cost_func_result
            update_optimal_counter = update_optimal_counter + 1;
            optimal_params = params_result;
            min_cost_func_result = cost_func_result;
            optimal_x1_final = optimal_x1;
            optimal_x2_final = optimal_x2;
    
            fprintf('%d) Cost function = %.10f, optimal_x1 = %.10f, optimal_x2 = %.10f\n', update_optimal_counter, min_cost_func_result, optimal_x1_final, optimal_x2_final);
        end
    end
end


%% Show result
% Extract the optimal coefficients and breakpoints
a1 = optimal_params(1);
b1 = optimal_params(2);
c1 = optimal_params(3);
a2 = optimal_params(4);
b2 = optimal_params(5);
c2 = optimal_params(6);
a3 = optimal_params(7);
b3 = optimal_params(8);
c3 = optimal_params(9);
optimal_breakpoints = [optimal_x1_final, optimal_x2_final];

% Display the results
fprintf('\n');
fprintf('Optimal solution:\n');
fprintf('Objective function = %.10f\n', objective_function(optimal_params, optimal_breakpoints, x_data, y_data));
fprintf('Equation 1: y1 = %.10f*x^2 + %.10f*x + %.10f\n', a1, b1, c1);
fprintf('Equation 2: y2 = %.10f*x^2 + %.10f*x + %.10f\n', a2, b2, c2);
fprintf('Equation 3: y3 = %.10f*x^2 + %.10f*x + %.10f\n', a3, b3, c3);
fprintf('Breakpoint 1 = %.10f\n', optimal_x1_final);
fprintf('Breakpoint 2 = %.10f\n', optimal_x2_final);

% Calculate the piecewise model
x1 = x_data(x_data <= optimal_x1_final);
x2 = x_data(optimal_x1_final<x_data & x_data<=optimal_x2_final);
x3 = x_data(optimal_x2_final<x_data);
y1 = a1*x1.^2 + b1*x1 + c1;
y2 = a2*x2.^2 + b2*x2 + c2;
y3 = a3*x3.^2 + b3*x3 + c3;

% Plot the piecewise model
plot(x1, y1, 'r', 'DisplayName', 'Piecewise Fit: y1', 'LineWidth', 2);
plot(x2, y2, 'g', 'DisplayName', 'Piecewise Fit: y2', 'LineWidth', 2);
plot(x3, y3, 'b', 'DisplayName', 'Piecewise Fit: y3', 'LineWidth', 2);
legend show

% Add the text annotations
annotation_text = sprintf(['Optimal solution:\n', ...
                           'Objective function = %.10f\n', ...
                           'Equation 1: y1 = %.10f*x^2 + %.10f*x + %.10f\n', ...
                           'Equation 2: y2 = %.10f*x^2 + %.10f*x + %.10f\n', ...
                           'Equation 3: y3 = %.10f*x^2 + %.10f*x + %.10f\n', ...
                           'Breakpoint 1 = %.10f\n', ...
                           'Breakpoint 2 = %.10f'], ...
                           objective_function(optimal_params, optimal_breakpoints, x_data, y_data), ...
                           a1, b1, c1, ...
                           a2, b2, c2, ...
                           a3, b3, c3, ...
                           optimal_x1_final, optimal_x2_final);
% Position the text on the figure (adjust position as needed)
text(0.05, 0.9, annotation_text, 'Units', 'normalized', 'FontSize', 10, 'VerticalAlignment', 'top');
saveas(gcf, '3_piecewise_best_fit_equation_fmincon_scan.png');


%% Functions
% Cost function definition
function cost = objective_function(params, optimal_breakpoints, x_data, y_data)
    % Extract parameters
    a1 = params(1);
    b1 = params(2);
    c1 = params(3);
    a2 = params(4);
    b2 = params(5);
    c2 = params(6);
    a3 = params(7);
    b3 = params(8);
    c3 = params(9);

    % Piecewise model
    y1 = a1*x_data.^2 + b1*x_data + c1;
    y2 = a2*x_data.^2 + b2*x_data + c2;
    y3 = a3*x_data.^2 + b3*x_data + c3;

    % Piecewise conditions
    idx1 = x_data <= optimal_breakpoints(1);
    idx2 = (optimal_breakpoints(1) < x_data) & (x_data <= optimal_breakpoints(2));
    idx3 = optimal_breakpoints(2) < x_data;

    % Calculate the cost (sum of squared errors)
    cost = sum((y_data(idx1) - y1(idx1)).^2) + ...
           sum((y_data(idx2) - y2(idx2)).^2) + ...
           sum((y_data(idx3) - y3(idx3)).^2);
end



% Continuity constraints definition
function [c, ceq] = continuity_constraints(params, optimal_breakpoints)
    % Extract parameters
    a1 = params(1);
    b1 = params(2);
    c1 = params(3);
    a2 = params(4);
    b2 = params(5);
    c2 = params(6);
    a3 = params(7);
    b3 = params(8);
    c3 = params(9);

    % Continuity constraints for function values
    y1_at_x1 = a1*optimal_breakpoints(1)^2 + b1*optimal_breakpoints(1) + c1;
    y2_at_x1 = a2*optimal_breakpoints(1)^2 + b2*optimal_breakpoints(1) + c2;
    y2_at_x2 = a2*optimal_breakpoints(2)^2 + b2*optimal_breakpoints(2) + c2;
    y3_at_x2 = a3*optimal_breakpoints(2)^2 + b3*optimal_breakpoints(2) + c3;

    % Continuity constraints for gradients
    y1_gradient_at_x1 = 2 * a1 * optimal_breakpoints(1) + b1;
    y2_gradient_at_x1 = 2 * a2 * optimal_breakpoints(1) + b2;
    y2_gradient_at_x2 = 2 * a2 * optimal_breakpoints(2) + b2;
    y3_gradient_at_x2 = 2 * a3 * optimal_breakpoints(2) + b3;

    % Ensure continuity at the breakpoints
    ceq = [y1_at_x1 - y2_at_x1;
           y2_at_x2 - y3_at_x2;
           y1_gradient_at_x1 - y2_gradient_at_x1;
           y2_gradient_at_x2 - y3_gradient_at_x2;
    ];

    % No inequality constraints defined
    c = [];
end
