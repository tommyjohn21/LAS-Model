%% RandomSeed Unit Test
% The goal of this test is to verify that the seed stored for each
% Simulation is adequate to reproduce it's voltage trace and generated STDP
% matrices (i.e. that with the seed alone, the Simulation can be
% reconstructed). In that case, Simulation itself need not be saved, but
% only the seed as it contains the necessary information.

%% Generate test Simulations (S and T)
% On object construction, seed contains a random (shuffled) rng state
S = Simulation('DefaultSimulationParameters');
T = Simulation('DefaultSimulationParameters');

% Enable on-the-go STDP learning
Plasticize(S), Plasticize(T)

% Prepare Simulations and give a known seizure-inducing input
Prepare(S), Prepare(T)
UpdateInput(S,'Deterministic',3), UpdateInput(T,'Deterministic',3);

% Run Simulations
Run(S)
Run(T)

% Extract traces (V: voltage trace, dW: dW matrix)
[V1,dW1,V2,dW2] = deal(V(S),S.dW,V(T),T.dW);

%% Unit Tests 1 and 2
%%% Unit Test 1
% If passed, we know that S and T have two different seeds, as expected
% since each Simulation captures a new random seed on construction
assert(~isequal(S.seed,T.seed),'S and T have the same seed!')
disp('Passed Unit Test 1')

%%% Unit Test 2
% If passed, we have established that creation of two Simulations with
% default settings produces both different seeds as well as different
% seizures/dW matrices
assert (~all(V1(:)==V2(:)) && ~all(dW1(:)==dW2(:)),'S and T unexpectedly produced the same seizures/dW matrices!')
disp('Passed Unit Test 2')

%% Generate 3rd test Simulation with seed given in S
% On object construction, seed contains shuffled rng state
U = Simulation('DefaultSimulationParameters');
assert(~isequal(S.seed,U.seed),'S and U have the same seed!')

% Prepare for on-the-go STDP learning
Plasticize(U)

% Plug in seed from S; set param to use PresetSeed 
U.seed = S.seed;
U.param.flags.UsePresetSeed = true;

% Prepare Simulation and give a known seizure-inducing input
Prepare(U)
UpdateInput(U,'Deterministic',3);

% Run Simulation
Run(U)

% Extract ground-truth traces
V3 = V(U);  % Voltage trace
dW3 = U.dW; % dW matrix

%% Unit Test 3 and 4
%%% Unit Test 3
% If passed, we know that S and U have the same seeds
%   Although different seeds initially, the updated seed for Simulation U
%   should be presered given the setting U.param.flags.UsePresetSeed
assert(isequal(S.seed,U.seed),'S and U have different seeds!')
disp('Passed Unit Test 3')

%%% Unit Test 4
% If passed, we have established that creation of U with
% updated seed given by S produces the same seizure as S under the same input
% constraints, as well as the same STDP-related dW matrix (i.e. U
% reproduces S given the same seed)
assert (all(V1(:)==V3(:)) && all(dW1(:)==dW3(:)),'S and U unexpectedly produced different seizures/dW matrices!')
disp('Passed Unit Test 4')

%% Unit Test 5 and 6
%%% Unit Test 5
% We want to ensure that resetting a Simulation with true UsePresetSeed
% keeps the appropriate seed
seed1 = U.seed; % Grab current seed from U (note that UsePresetSeed should already be true per Unit Tests 3 and 4)
Reset(U)
seed2 = U.seed;
assert(isequal(seed1,seed2),'Resetting Simulation U caused change in seed depsite UsePresetSeed flag')
disp('Passed Unit Test 5')

%%% Unit Test 6
% Ensure that (re-)Running of simulation after reset produces the same
% seizure
Run(U);
V4 = V(U);  % Voltage trace
dW4 = U.dW; % dW matrix
assert (all(V3(:)==V4(:)) && all(dW3(:)==dW4(:)),'Resetting and (re-)Running U unexpectedly produced different seizures/dW matrices!')
disp('Passed Unit Test 6')

%% Unit Test 7 and 8
%%% Unit Test 7
% Perform Unit Test 5, but on Simulation T, which was already run
% previously with different seed
T.seed = S.seed;
T.param.flags.UsePresetSeed = true;
Reset(T);
assert(isequal(S.seed,T.seed),'Resetting Simulation T after updating seed led to new seed depsite UsePresetSeed flag')
disp('Passed Unit Test 7')

%%% Unit Test 8
% Ensure that (re-)Running of simulation after reset produces the same
% seizure; note that, unlike Unit Test 6, Simulation T has been run
% previously with a *different* seed
Run(T);
V5 = V(T);
dW5 = T.dW;
assert (all(V1(:)==V5(:)) && all(dW1(:)==dW5(:)),'Resetting and (re-)Running T with PresetSeed did not produce expected seizures/dW matrices!')
disp('Passed Unit Test 8')

%% Unit Test 9 and 10
%%% Unit Test 9
% If Simulation T is released from UsePresetSeed, it should produce a new
% seed during Reset
T.seed = S.seed; % First give a known seed
T.param.flags.UsePresetSeed = false;
seed1 = T.seed;
Reset(T)
assert(~isequal(seed1,T.seed),'Despite false UsePresetSeed flag, seed for Simulation T was not regenerated during reset')
disp('Passed Unit Test 9')

%%% Unit Test 10
% Ensure that (re-)Running of simulation after reset produces different
% seizure
Run(T);
V6 = V(T);
dW6 = T.dW;
assert (~all(V5(:)==V6(:)) && ~all(dW5(:)==dW6(:)),'Resetting and (re-)Running T with new seed did not produce different seizure/dW matrix!')
disp('Passed Unit Test 10')

%% Unit Test 11 and 12
%%% Unit Test 11
% Likewise, Resetting *prior* to UsePresetSeed should not change seed
U.param.flags.UsePresetSeed = true;
U.seed = S.seed;
Reset(U);
assert(isequal(U.seed,S.seed),'U and S no longer share a seed, although neither should have changed!')
disp('Passed Unit Test 11')

%%% Unit Test 12
% Subsequent run with UsePresetSeed false should create new seed/seizure/dW matrix
U.param.flags.UsePresetSeed = false;
Run(U)
V7 = V(U);
dW7 = U.dW;
assert (~all(V3(:)==V7(:)) && ~all(dW3(:)==dW7(:)),'Resetting and (re-)Running U with new seed did not produce different seizure/dW matrix!')
disp('Passed Unit Test 12')
