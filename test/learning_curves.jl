module TestLearningCurves

using Test
using Distributed
@everywhere begin
    using MLJBase
    using MLJTuning
    using ..Models
    import ComputationalResources: CPU1, CPUProcesses, CPUThreads
    using Distributed
end
using Random
Random.seed!(1234*myid())
using ..TestUtilities

x1 = rand(100);
x2 = rand(100);
x3 = rand(100);
X = (x1=x1, x2=x2, x3=x3);
y = 2*x1 .+ 5*x2 .- 3*x3 .+ 0.2*rand(100);

@testset_accelerated "learning curves" accel (exclude=[CPUThreads],) begin
    atom = FooBarRegressor()
    ensemble = EnsembleModel(atom=atom, n=50)
    mach = machine(ensemble, X, y)
    r_lambda = range(ensemble, :(atom.lambda),
                     lower=0.0001, upper=0.1, scale=:log10)

    # Something wrong with @test_logs in julia 1.1.1 and
    # 1.0.5. Getting "Internal error: encountered unexpected error in
    # runtime: MethodError(f=typeof(Core.Compiler.fieldindex)(),
    # args=(MLJTuning.DeterministicTunedModel{T, M, R} where R,
    # :acceleration, false), world=0x0000000000000eb9)"
    if accel == CPU1() && VERSION > v"1.2"
            curve = @test_logs((:info, r"No measure"),
                               (:info, r"Training"),
                               learning_curve(mach; range=r_lambda,
                                               acceleration=accel))
    else
        curve = learning_curve(mach; range=r_lambda,
                                acceleration=accel)
    end
    @test curve isa NamedTuple{(:parameter_name,
                                :parameter_scale,
                                :parameter_values,
                                :measurements)}
    @test length(curve.parameter_values) == length(curve.measurements)
    atom.lambda=0.3
    r_n = range(ensemble, :n, lower=10, upper=100)

    curves = learning_curve(mach; range=r_n, resolution=7,
                             acceleration=accel,
                             rngs = MersenneTwister.(1:3),
                             rng_name=:rng)
    @test size(curves.measurements) == (length(curves.parameter_values), 3)
    @test length(curves.parameter_values) == 7

    # individual curves are different:
    @test !(curves.measurements[1,1] ≈ curves.measurements[1,2])
    @test !(curves.measurements[1,1] ≈ curves.measurements[1,3])

    # reproducibility:
    curves2 = learning_curve(mach; range=r_n, resolution=7,
                             acceleration=accel,
                             rngs = 3,
                             rng_name=:rng)
    @test curves2.measurements ≈ curves.measurements

end

end # module
true
