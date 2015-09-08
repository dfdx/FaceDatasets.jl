
using Images
using Colors
using MAT

Base.convert{T}(::Type{Matrix{Float64}}, img::Image{Gray{T}}) =
    convert(Array{Float64, 2}, convert(Array, img))


function walkdir(dir; pred=(_ -> true))
    paths = [joinpath(dir, filename) for filename in readdir(dir)]
    result = Array(String, 0)
    for path in paths
        if isdir(path)
            append!(result, walkdir(path, pred=pred))
        elseif pred(path)
            push!(result, path)
        end
    end
    return result
end


############### Cohn-Kanade+ dataset #####################


function load_images_ck(datadir::String; start=1, count=-1,
                        resizeratio=1.0, indexes=[])
    @assert(datadir != "", "`datadir` parameter should be specified and point " *
            "to a directory with downloaded CK+ dataset")
    imgdir = joinpath(datadir, "cohn-kanade-images")
    @assert(isdir(imgdir), "Expected to have image directory at $imgedir, " *
            "but it doesn't exist or is not a directory (have you unzipped data?)")
    paths = sort(walkdir(imgdir, pred=(p -> endswith(p, ".png"))))
    if indexes != []
        paths = paths[indexes]
    end
    num = count != -1 ? count : length(paths)  # if count == -1, read all
    num = min(num, length(paths) - start + 1)  # don't cross the bounds
    imgs = Array(Matrix{Float64}, num)
    for i=1:num
        img = imread(paths[start + i - 1])
        h, w = size(img)
        new_size = (int(resizeratio * h), int(resizeratio * w))
        img = Images.imresize(img, new_size)
        if colorspace(img) != "Gray"
            img = convert(Array{Gray}, img)
        end
        imgs[i] = convert(Matrix{Float64}, img)
        if i % 100 == 0
            info("$i images read")
        end
    end
    return imgs
end


function load_shape_ck(path::String)
    open(path) do file
        readdlm(file)
    end
end


function load_shapes_ck(datadir::String; start=1, count=-1,
                        resizeratio=1.0, indexes=[])
    @assert(datadir != "", "`datadir` parameter should be specified and point " *
            "to a directory with downloaded CK+ dataset")
    shapedir = joinpath(datadir, "Landmarks")
    @assert(isdir(shapedir), "Expected to have shape directory at $shapedir, " *
            "but it doesn't exist or is not a directory (have you unzipped data?)")    
    paths = sort(walkdir(shapedir, pred=(p -> endswith(p, ".txt"))))
    paths = paths[[1:6790-1, 6790+1:end]]
    if indexes != []
        paths = paths[indexes]
    end
    num = count != -1 ? count : length(paths)      # if count == -1, read all
    # num = min(num, length(paths) - start + 1 - 1)  # don't cross the bounds; -1 is to fix
                                                   # issue with additional shape file
    shapes = Array(Matrix{Float64}, num)
    for i=1:num
        # for some reason CK+ dataset contains one additional landmark file
        # for non existing image
        ## if basename(paths[start + i - 1]) == "S109_002_00000008_landmarks.txt"
        ##     start += 1
        ## end
        shape_xy = load_shape_ck(paths[start + i - 1])
        shapes[i] = resizeratio .* [shape_xy[:, 2] shape_xy[:, 1]]
    end
    return shapes
end


############### Cootes images (from ICAAM) ###################

const COOTES_DATA_DIR = joinpath(Pkg.dir(), "FaceDatasets", "data", "cootes", "data")
const COOTES_IMG_HEIGHT = 480

function load_shape_from_mat(path::String)
    return matread(path)["annotations"]
end

function load_shapes_cootes(;count=-1) 
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

function load_images_cootes(;count=-1)    
    files = sort(filter(x->endswith(x, ".bmp"), readdir(COOTES_DATA_DIR)))
    paths = map(x->joinpath(COOTES_DATA_DIR, x), files)
    n_use = count > 0 ? count : length(paths)
    imgs = Array(Array{Float64, 3}, n_use)    
    for i=1:n_use
        img_rgb = imread(paths[i])
        img_rgb = convert(Image{RGB{Float64}}, img_rgb)  # ensure 3-channel RGB
        imgs[i] = convert(Array, separate(img_rgb))
    end    
    return imgs
end



################## Generic functions ######################

const AVAILABLE_DATASETS = [:ck, :cootes]


function load_images(dataset_name::Symbol; datadir="", start=1, count=-1,
                     resizeratio=1.0, indexes=[])
    if dataset_name == :ck
        return load_images_ck(datadir, start=start, count=count,
                              resizeratio=resizeratio, indexes=indexes)
    elseif dataset_name == :cootes
        return load_images_cootes(count=count)
    else
        error("Dataset $dataset_name is not supported, " *
              "available datasets: $AVAILABLE_DATASETS")
    end
end


function load_shapes(dataset_name::Symbol;
                     datadir="", start=1, count=-1,
                     resizeratio=1.0, indexes=[])
    if dataset_name == :ck
        return load_shapes_ck(datadir, start=start, count=count,
                              resizeratio=resizeratio, indexes=indexes)
    elseif dataset_name == :cootes
        return load_shapes_cootes(count=count)
     else
        error("Dataset $dataset_name is not supported, available datasets: $AVAILABLE_DATASETS")
    end
end



