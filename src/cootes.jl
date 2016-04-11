
## Cootes images (from ICAAM project)

immutable CootesDataset <: FaceDataset
end


const COOTES_DATA_DIR = joinpath(Pkg.dir(), "FaceDatasets", "data", "cootes", "data")
const COOTES_IMG_HEIGHT = 480

function load_shape_from_mat(path::AbstractString)
    return matread(path)["annotations"]
end

function load_shapes(::Type{CootesDataset}; count=-1)
    files = sort(filter(x -> endswith(x, ".mat"), readdir(COOTES_DATA_DIR)))
    paths = map(x->joinpath(COOTES_DATA_DIR, x), files)
    n_use = count > 0 ? count : length(paths)
    shapes = Array(Matrix{Float64}, n_use)
    for k=1:n_use
        shape_xy = load_shape_from_mat(paths[k])
        shape_ij = [COOTES_IMG_HEIGHT .- shape_xy[:, 2] shape_xy[:, 1]]
        shapes[k] = shape_ij
    end
    return shapes
end

function load_images(::Type{CootesDataset}; count=-1)
    files = sort(filter(x->endswith(x, ".bmp"), readdir(COOTES_DATA_DIR)))
    paths = map(x->joinpath(COOTES_DATA_DIR, x), files)
    n_use = count > 0 ? count : length(paths)
    imgs = Array(Array{Float64, 3}, n_use)
    for i=1:n_use
        img_rgb = load(paths[i])
        img_rgb = convert(Image{RGB{Float64}}, img_rgb)  # ensure 3-channel RGB
        imgs[i] = convert(Array, separate(img_rgb))
    end
    return imgs
end

