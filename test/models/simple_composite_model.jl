export SimpleDeterministicCompositeModel

using MLJBase

"""
    SimpleDeterministicCompositeModel(;regressor=ConstantRegressor(),
                              transformer=FeatureSelector())

Construct a composite model consisting of a transformer
(`Unsupervised` model) followed by a `Deterministic` model. Mainly
intended for internal testing .

"""
mutable struct SimpleDeterministicCompositeModel{L<:Deterministic,
                             T<:Unsupervised} <: DeterministicComposite
    model::L
    transformer::T

end

function SimpleDeterministicCompositeModel(;
                      model=DeterministicConstantRegressor(),
                      transformer=FeatureSelector())

    composite =  SimpleDeterministicCompositeModel(model, transformer)

    message = MLJBase.clean!(composite)
    isempty(message) || @warn message

    return composite

end

MLJBase.is_wrapper(::Type{<:SimpleDeterministicCompositeModel}) = true

function MLJBase.fit(composite::SimpleDeterministicCompositeModel,
                     verbosity::Integer, Xtrain, ytrain)
    X = source(Xtrain) # instantiates a source node
    y = source(ytrain)

    t = machine(composite.transformer, X)
    Xt = transform(t, X)

    l = machine(composite.model, Xt, y)
    yhat = predict(l, Xt)

    mach = machine(Deterministic(), X, y; predict=yhat)
    return!(mach, composite, verbosity)

end

MLJBase.load_path(::Type{<:SimpleDeterministicCompositeModel}) =
    "MLJBase.SimpleDeterministicCompositeModel"
MLJBase.package_uuid(::Type{<:SimpleDeterministicCompositeModel}) = ""
MLJBase.package_url(::Type{<:SimpleDeterministicCompositeModel}) =
    "https://github.com/alan-turing-institute/MLJBase.jl"
MLJBase.is_pure_julia(::Type{<:SimpleDeterministicCompositeModel}) = true
MLJBase.input_scitype(::Type{<:SimpleDeterministicCompositeModel{L,T}}) where {L,T} =
    MLJBase.input_scitype(T)
MLJBase.target_scitype(::Type{<:SimpleDeterministicCompositeModel{L,T}}) where {L,T} =
    MLJBase.target_scitype(L)
