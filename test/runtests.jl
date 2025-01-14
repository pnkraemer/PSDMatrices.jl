using Test
using PSDMatrices
using LinearAlgebra
using Suppressor

M_square = [1 1; 2 20]
M_tall = [1 1; 2 20; 3 30]
M_wide = [1 1 1; 2 20 200]
eltypes = (Int64, Float64, BigFloat)

@testset "PSDMatrices.jl" begin
    @testset "eltype=$t | shape=$(size(Mbase))" for t in eltypes,
        Mbase in (M_square, M_tall, M_wide)

        M = t.(Mbase)
        S = PSDMatrix(M)
        X = rand(size(S, 1), size(S, 2))

        @testset "Base" begin
            @test eltype(S) == t
            @test size(S) == size(Matrix(S))
            @test S == S
            @test copy(S) == S
            @test !(copy(S) === S)
            @test typeof(similar(S)) == typeof(S)
            @test (S2 = similar(S); copy!(S2, S); S2 == S)
            if size(M, 1) == size(M, 2)
                @test Matrix(inv(S)) ≈ inv(Matrix(S))
            end
            @suppress_out @test isnothing(show(S))
            @suppress_out @test isnothing(show(stdout, MIME("text/plain"), S))
        end

        @testset "LinearAlgebra" begin
            @test diag(S) ≈ diag(Matrix(S))
            if size(M, 1) == size(M, 2)
                @test det(S) ≈ det(Matrix(S))
                @test logdet(S) ≈ logdet(Matrix(S))
            else
                @test_throws MethodError det(S)
                @test_throws MethodError logdet(S)
            end
            if (size(M, 1) >= size(M, 2))
                @test S \ X ≈ Matrix(S) \ X
                @test X / S ≈ X / Matrix(S)
            end
        end

        @testset "Exports" begin
            @test norm(Matrix(S) - M' * M) == 0.0
            @test Matrix(X_A_Xt(S, X)) ≈ X * Matrix(S) * X'
            @test Matrix(X_A_Xt(A=S, X=X)) ≈ X * Matrix(S) * X'
            @test begin
                product_eltype = typeof(one(eltype(X)) * one(eltype(S)))
                S2 = PSDMatrix(zeros(product_eltype, size(S.R)...))
                X_A_Xt!(S2, S, X)
                Matrix(S2) ≈ Matrix(X_A_Xt(S, X))
            end
            @test begin
                product_eltype = typeof(one(eltype(X)) * one(eltype(S)))
                S2 = PSDMatrix(zeros(product_eltype, size(S.R)...))
                X_A_Xt!(S2, A=S, X=X)
                Matrix(S2) ≈ Matrix(X_A_Xt(S, X))
            end
            @test Matrix(add_qr(S, S)) ≈ Matrix(S) + Matrix(S)
            if (size(M, 1) >= size(M, 2))
                @test Matrix(add_cholesky(S, S)) ≈ Matrix(S) + Matrix(S)
                tri = triangularize_factor(S)
                @test tri.R isa UpperTriangular
                @test Matrix(tri) ≈ Matrix(S)
            end
        end
    end
end
nothing
