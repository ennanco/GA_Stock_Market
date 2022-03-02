close all;
clear all;
warning('off');

initial_amount = 100;
sliding_window_size = 5;
bracket = 3;


% Read the movements of the stocks market for a specific year
stocks = csvread('Grupo_1.csv', 1, 2);

[num_days, num_stocks] = size(stocks);
num_variables = 4 * num_stocks; % 4 thresholds strong sold, weak sold, weak buy, strong buy

T = floor(num_days/2); % FIRST TERM which is going to be used to tune the system

train_data = stocks(1:T, :);
test_data = stocks(T+1:end, :);


%%%%%%%%%%%%%%%%%%%%
%  FITNESS FUNC    %
%%%%%%%%%%%%%%%%%%%%
fitness = get_fitness_function(train_data, initial_amount, sliding_window_size);

%%%%%%%%%%%%%%%%%%%%%%
%OPTIONS FOR THE TEST%
%%%%%%%%%%%%%%%%%%%%%%
options = gaoptimset();
options = gaoptimset(options, 'PopInitRange',[zeros(1, num_variables);bracket*ones(1,num_variables)]); % Initial Range
options = gaoptimset(options,'PopulationType' , 'doubleVector');                                    % Population Type
options = gaoptimset(options,'PopulationSize' , 50);                                               % Polulation Size
options = gaoptimset(options,'Generations',1000);                                                    % Generation Limit
options = gaoptimset(options,'StallTimeLimit', 10000);                                               % Time limit
options = gaoptimset(options,'StallGenLimit', 500);                                               % Time limit for generation
options = gaoptimset(options, 'EliteCount', 2);                                                     % Elitism
options = gaoptimset(options, 'SelectionFcn', @selectiontournament);                                % Selection Method
options = gaoptimset(options, 'CrossoverFcn', @crossovertwopoint);                                  % Crossover Function
options = gaoptimset(options, 'CrossoverFraction', 0.90);                                            % Crossover rate
options = gaoptimset(options, 'MutationFcn', {@mutationuniform, 0.15});                             % Mutation Function & Probability
%options = gaoptimset(options, 'UseParallel', false);

%%%%%%%%%%%%%%%%%%%%
%  Display Setup   %
%%%%%%%%%%%%%%%%%%%%
%options = gaoptimset(options, 'Display', 'off');
options = gaoptimset(options, 'PlotInterval', 10);
options = gaoptimset(options,'PlotFcns',@gaplotbestf);

nonlcon = [];    %non linear contraint

lb = zeros(num_variables, 1);
ub = bracket*ones(num_variables,1);

%A = [-1, 1, 0, 0; 0, 0, 1, -1];
%prepare the limitss  to fulfill the inneequetiees 
A = zeros(1,num_variables);
A(1) = -1;
A(2) = 1;
for  i = 2:num_variables/2
    A = [A; -1*circshift(A(end,:), 2,2)];
end
b = zeros(1, num_variables/2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ALGORITHM EXECUTION    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
 [solution,fval,exitflag,output,population,scores] = ...
          ga(fitness, num_variables, ...                                                           % fitness_fun, nvars
             A, b,...                                                                            % inequalities A*x<=b
             [],[],...                                                                             % equalities A*x=b
             lb,ub,...                                                                             % lb and ub
             nonlcon,[], options);                                                                  % nonlcon,IntCon,options

disp('');
disp('Best individual: ');
disp(solution);
disp('Fitness: ');
disp(-fval);

%%%%%%%%%%%%%%%%%%%%%%%%%
%   TEST THE SOLUTION   %
%%%%%%%%%%%%%%%%%%%%%%%%%
prediction = get_fitness_function(test_data, initial_amount, sliding_window_size);
disp('How rich am I?');
disp(-prediction(solution));

