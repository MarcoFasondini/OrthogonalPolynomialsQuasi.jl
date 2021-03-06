using Base, OrthogonalPolynomialsQuasi, ContinuumArrays, QuasiArrays, FillArrays,
        LazyArrays, BandedMatrices, LinearAlgebra, FastTransforms, IntervalSets,
        InfiniteLinearAlgebra, Test
using ForwardDiff, SemiseparableMatrices, SpecialFunctions, LazyBandedMatrices
import ContinuumArrays: BasisLayout, MappedBasisLayout
import OrthogonalPolynomialsQuasi: jacobimatrix, ∞, ChebyshevInterval, LegendreWeight,
            Clenshaw, forwardrecurrence!, singularities
import LazyArrays: ApplyStyle, colsupport, MemoryLayout, arguments
import SemiseparableMatrices: VcatAlmostBandedLayout
import QuasiArrays: MulQuasiMatrix
import Base: OneTo
import InfiniteLinearAlgebra: KronTrav, Block
import FastTransforms: clenshaw!

@testset "singularities" begin
    x = Inclusion(ChebyshevInterval())
    @test singularities(x) == singularities(exp.(x)) == singularities(x.^2) ==
        singularities(x .+ 1) == singularities(1 .+ x) == singularities(x .+ x) ==
        LegendreWeight()
    @test singularities(exp.(x) .* JacobiWeight(0.1,0.2)) ==
        singularities(JacobiWeight(0.1,0.2) .* exp.(x)) ==
        JacobiWeight(0.1,0.2)

    x = Inclusion(0..1)
    @test singularities(x) == singularities(exp.(x)) == singularities(x.^2) ==
        singularities(x .+ 1) == singularities(1 .+ x) == singularities(x .+ x) ==
        legendreweight(0..1)
end

@testset "weight with coeffs" begin
    x = Inclusion(ChebyshevInterval())
    w = π*x.^2 .+ 2
    Pw = LanczosPolynomial(w)
    J = Pw\(x.*Pw)
    x = 1
    n = 10
    x*Pw[x,1] ≈ J[1,1]*Pw[x,1] + J[1,2]*Pw[x,2]
    x*Pw[x,n] ≈ J[n,n-1]*Pw[x,n-1] + J[n,n]*Pw[x,n] + J[n,n+1]*Pw[x,n+1]
end

@testset "Chebyshev weight times polynomial" begin
    x = Inclusion(ChebyshevInterval())
    w = ChebyshevTWeight()
    ϕ = x.^2
    P = LanczosPolynomial(w.*ϕ)
    J = P\(x.*P)
    x = 1
    n = 10
    x*P[x,1] ≈ J[1,1]*P[x,1] + J[1,2]*P[x,2]
    x*P[x,n] ≈ J[n,n-1]*P[x,n-1] + J[n,n]*P[x,n] + J[n,n+1]*P[x,n+1]
end

include("test_chebyshev.jl")
include("test_legendre.jl")
include("test_ultraspherical.jl")
include("test_jacobi.jl")
include("test_fourier.jl")
include("test_odes.jl")
include("test_normalized.jl")
include("test_lanczos.jl")

@testset "Auto-diff" begin
    U = Ultraspherical(1)
    C = Ultraspherical(2)

    f = x -> ChebyshevT{eltype(x)}()[x,5]
    @test ForwardDiff.derivative(f,0.1) ≈ 4*U[0.1,4]
    f = x -> ChebyshevT{eltype(x)}()[x,5][1]
    @test ForwardDiff.gradient(f,[0.1]) ≈ [4*U[0.1,4]]
    @test ForwardDiff.hessian(f,[0.1]) ≈ [8*C[0.1,3]]

    f = x -> ChebyshevT{eltype(x)}()[x,1:5]
    @test ForwardDiff.derivative(f,0.1) ≈ [0;(1:4).*U[0.1,1:4]]
end
