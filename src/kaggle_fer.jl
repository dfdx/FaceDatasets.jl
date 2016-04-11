
############### Kaggle FER Competition ###################
# See https://www.kaggle.com/c/challenges-in-representation-learning-facial-expression-recognition-challenge/ for details

immutable KaggleFERDataset <: FaceDataset
end    

function load_images(::Type{KaggleFERDataset}, datadir::AbstractString)
    datafile = joinpath(datadir, "fer2013.csv")
    if !isfile(datafile)
        throw(ArgumentError("Expected to have CSV file at $datafile"))
    end
    n_images = 35887
    imgs = Vector{Matrix{Float64}}(n_images)
    open(datafile) do f
        readline(f) # skip header
        for (i, line) in zip(1:n_images, eachline(f))
            label, data, _ = split(line, ",")
            arr = [parse(Float64, s) for s in split(data, " ")] / 255
            img = reshape(arr, 48, 48)'
            imgs[i] = img
            if i % 1000 == 0
                info("Loaded $i images")
            end
        end
    end
    return imgs
end


function load_labels(::Type{KaggleFERDataset}, datadir::AbstractString)
    datafile = joinpath(datadir, "fer2013.csv")
    if !isfile(datafile)
        throw(ArgumentError("Expected to have CSV file at $datafile"))
    end
    n_images = 35887
    labels = Vector{Float64}(n_images)
    open(datafile) do f
        readline(f) # skip header
        for (i, line) in zip(1:n_images, eachline(f))
            label, data, _ = split(line, ",")
            labels[i] = parse(Float64, label)
        end
    end
    return labels
end
