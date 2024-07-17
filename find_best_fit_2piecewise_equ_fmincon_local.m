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
figure_name = "fmincon: 2 piecewise best-fit equation";
title(figure_name)
xlabel("X Data")
ylabel("Y Data")


%% Machine Learning & system optimization
% Equation 1: y1 = a1*x^2 + b1*x + c1
% Equation 2: y2 = a2*x^2 + b2*x + c2
% Breakpoints: min(x_data) < optimal_x0 < max(x_data)

% Initial guess for the coefficients and breakpoints
initial_guess = [0, 0, 0, 0, 0, 0, 35];

% Optimization options
options = optimoptions('fmincon', 'Display', 'off', 'Algorithm', 'sqp');

% Define bounds for the coefficients and breakpoints
COEFFICIENT_VAL_MIN = -10;
COEFFICIENT_VAL_MAX = 10;
lb = [COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, ...
      COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, COEFFICIENT_VAL_MIN, 0];
ub = [COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, ...
      COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, COEFFICIENT_VAL_MAX, max(x_data)];

% Define the objective function
objective = @(params) objective_function(params, x_data, y_data);

% Define the nonlinear constraints
nonlcon = @(params) continuity_constraints(params);

% Optimize
optimal_params = fmincon(objective, initial_guess, [], [], [], [], lb, ub, nonlcon, options);

% Extract the optimal coefficients and breakpoints
a1 = optimal_params(1);
b1 = optimal_params(2);
c1 = optimal_params(3);
a2 = optimal_params(4);
b2 = optimal_params(5);
c2 = optimal_params(6);
optimal_x0 = optimal_params(7);

% Display the results
fprintf('Optimal solution:\n');
fprintf('Objective function = %.10f\n', objective_function(optimal_params, x_data, y_data));
fprintf('Equation 1: y1 = %.10f*x^2 + %.10f*x + %.10f\n', a1, b1, c1);
fprintf('Equation 2: y2 = %.10f*x^2 + %.10f*x + %.10f\n', a2, b2, c2);
fprintf('Breakpoint optimal_x0 = %.10f\n', optimal_x0);


% Calculate the piecewise model
x1 = x_data(x_data < optimal_x0);
x2 = x_data(x_data >= optimal_x0);

y1 = a1*x1.^2 + b1*x1 + c1;
y2 = a2*x2.^2 + b2*x2 + c2;

% Plot the piecewise model
plot(x1, y1, 'r', 'DisplayName', 'Piecewise Fit: y1', 'LineWidth', 2);
plot(x2, y2, 'g', 'DisplayName', 'Piecewise Fit: y2', 'LineWidth', 2);
legend show


% Add the text annotations
annotation_text = sprintf(['Optimal solution:\n', ...
                           'Objective function = %.10f\n', ...
                           'Equation 1: y1 = %.10f*x^2 + %.10f*x + %.10f\n', ...
                           'Equation 2: y2 = %.10f*x^2 + %.10f*x + %.10f\n', ...
                           'Breakpoint optimal_x0 = %.10f'], ...
                           objective_function(optimal_params, x_data, y_data), ...
                           a1, b1, c1, ...
                           a2, b2, c2, ...
                           optimal_x0);
% Position the text on the figure (adjust position as needed)
text(0.05, 0.9, annotation_text, 'Units', 'normalized', 'FontSize', 10, 'VerticalAlignment', 'top');
saveas(gcf, '2_piecewise_best_fit_equation_fmincon.png');


%% Functions
% Cost function definition
function cost = objective_function(params, x, y)
    % Extract parameters
    a1 = params(1);
    b1 = params(2);
    c1 = params(3);
    a2 = params(4);
    b2 = params(5);
    c2 = params(6);
    optimal_x0 = params(7);


    % Piecewise model
    y1 = a1*x.^2 + b1*x + c1;
    y2 = a2*x.^2 + b2*x + c2;

    % Piecewise conditions
    idx1 = x <  optimal_x0;
    idx2 = x >= optimal_x0;

    % Calculate the cost (sum of squared errors)
    cost = sum((y(idx1) - y1(idx1)).^2) + sum((y(idx2) - y2(idx2)).^2);
end

% Continuity constraints definition
function [c, ceq] = continuity_constraints(params)
    % Extract parameters
    a1 = params(1);
    b1 = params(2);
    c1 = params(3);
    a2 = params(4);
    b2 = params(5);
    c2 = params(6);
    optimal_x0 = params(7);

    % Continuity constraints for function values
    y1_at_x0 = a1*optimal_x0^2 + b1*optimal_x0 + c1;
    y2_at_x0 = a2*optimal_x0^2 + b2*optimal_x0 + c2;

    % Continuity constraints for gradients
    gradient1_x0 = 2 * a1 * optimal_x0 + b1;
    gradient2_x0 = 2 * a2 * optimal_x0 + b2;

    % Ensure continuity at the breakpoints
    ceq = [
        y1_at_x0 - y2_at_x0;    % Continuity of function values at x0
        gradient1_x0 - gradient2_x0;   % Continuity of gradients at x0
    ];

    % No inequality constraints defined
    c = [];
end
