
Base.convert{T}(::Type{Matrix{Float64}}, img::Image{Gray{T}}) =
    convert(Array{Float64, 2}, convert(Array, img))

# Base.convert(::Type{Array{Float64, 3}}, img::Image{RGB}) =
#     convert(Array{Float64}, separate(img).data)

rgb2arr(img) = convert(Array{Float64}, separate(img).data)


function walkdir(dir; pred=(_ -> true))
    paths = [joinpath(dir, filename) for filename in readdir(dir)]
    result = Array(AbstractString, 0)
    for path in paths
        if isdir(path)
            append!(result, walkdir(path, pred=pred))
        elseif pred(path)
            push!(result, path)
        end
    end
    return result
end
