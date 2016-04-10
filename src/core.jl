
using Images
using Colors
using MAT

Base.convert{T}(::Type{Matrix{Float64}}, img::Image{Gray{T}}) =
    convert(Array{Float64, 2}, convert(Array, img))


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


############### Cohn-Kanade+ dataset #####################


function load_images_ck(datadir::AbstractString; start=1, count=-1,
                        resizeratio=1.0, indexes=[])
    @assert(datadir != "", "`datadir`
parameter should be specified and point " *
            "to a directory with downloaded CK+ dataset")
    imgdir = joinpath(datadir, "cohn-kanade-images")
    @assert(isdir(imgdir), "Expected to have image directory at $imgdir, " *
            "but it doesn't exist or is not a directory (have you unzipped data?)")
    paths = sort(walkdir(imgdir, pred=(p -> endswith(p, ".png"))))
    if indexes != []
        paths = paths[indexes]
    end
    num = count != -1 ? count : length(paths)  # if count == -1, read all
    num = min(num, length(paths) - start + 1)  # don't cross the bounds
    imgs = Array(Matrix{Float64}, num)
    for i=1:num
        img = load(paths[start + i - 1])
        h, w = size(img)
        new_size = (round(Int, resizeratio * h), round(Int, resizeratio * w))
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


function load_shape_ck(path::AbstractString)
    open(path) do file
        readdlm(file)
    end
end


function load_shapes_ck(datadir::AbstractString; start=1, count=-1,
                        resizeratio=1.0, indexes=[])
    @assert(datadir != "", "`datadir` parameter should be specified and point " *
            "to a directory with downloaded CK+ dataset")
    shapedir = joinpath(datadir, "Landmarks")
    @assert(isdir(shapedir), "Expected to have shape directory at $shapedir, " *
            "but it doesn't exist or is not a directory (have you unzipped data?)")
    paths = sort(walkdir(shapedir, pred=(p -> endswith(p, ".txt"))))
    # for some reason CK+ dataset contains one additional landmark file
    # for non existing image
    paths = paths[[1:6790-1; 6790+1:end]]
    if indexes != []
        paths = paths[indexes]
    end
    num = count != -1 ? count : length(paths)      # if count == -1, read all
    # num = min(num, length(paths) - start + 1 - 1)  # don't cross the bounds; -1 is to fix
                                                   # issue with additional shape file
    shapes = Array(Matrix{Float64}, num)
    for i=1:num
        shape_xy = load_shape_ck(paths[start + i - 1])
        shapes[i] = resizeratio .* [shape_xy[:, 2] shape_xy[:, 1]]
    end
    return shapes
end


function img_path_to_label_path(img_path::AbstractString)
    img_dir = dirname(img_path)
    dir = replace(img_dir, "cohn-kanade-images", "Emotion")
    isdir(dir) || return ""
    filenames = readdir(dir)
    if length(filenames) > 0
        return joinpath(dir, filenames[1])
    else
        return ""
    end
end

function load_labels_ck(datadir::AbstractString)
    @assert(datadir != "", "`datadir` parameter should be specified and " *
            "pointo a directory with downloaded CK+ dataset")
    imgdir = joinpath(datadir, "cohn-kanade-images")
    img_paths = sort(collect_last_items(imgdir))
    paths = map(img_path_to_label_path, img_paths)
    num = length(paths)
    labels = Array(Float64, num)
    for i=1:num
        if isfile(paths[i])
            txt = open(readall, paths[i])
            labels[i] = parse(Float64, txt)
        else
            labels[i] = -1
        end
    end
    return labels
end



############### Cohn-Kanade+ dataset (max only) #####################


function collect_last_items(img_or_lm_dir::AbstractString)
    paths = AbstractString[]
    for subj_subdir in readdir(img_or_lm_dir)
        subj_dir = joinpath(img_or_lm_dir, subj_subdir)
        isdir(subj_dir) || continue
        for expr_subdir in readdir(subj_dir)
            expr_dir = joinpath(subj_dir, expr_subdir)
            isdir(expr_dir) || continue
            items = sort(readdir(expr_dir))
            push!(paths, joinpath(expr_dir, items[end]))
        end
    end
    return paths
end


function load_images_ck_max(datadir::AbstractString; resizeratio=1.0)
    @assert(datadir != "", "`datadir`
parameter should be specified and point " *
            "to a directory with downloaded CK+ dataset")
    imgdir = joinpath(datadir, "cohn-kanade-images")
    @assert(isdir(imgdir), "Expected to have image directory at $imgdir, " *
            "but it doesn't exist or is not a directory (have you unzipped data?)")
    paths = sort(collect_last_items(imgdir))
    num = length(paths)
    imgs = Array(Matrix{Float64}, num)
    for i=1:num
        img = load(paths[i])
        h, w = size(img)
        new_size = (round(Int, resizeratio * h), round(Int, resizeratio * w))
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


function load_shapes_ck_max(datadir::AbstractString; resizeratio=1.0)
    @assert(datadir != "", "`datadir` parameter should be specified and point " *
            "to a directory with downloaded CK+ dataset")
    shapedir = joinpath(datadir, "Landmarks")
    @assert(isdir(shapedir), "Expected to have shape directory at $shapedir, " *
            "but it doesn't exist or is not a directory (have you unzipped data?)")
    paths = sort(collect_last_items(shapedir))
    num = length(paths)
    shapes = Array(Matrix{Float64}, num)
    for i=1:num
        shape_xy = load_shape_ck(paths[i])
        shapes[i] = resizeratio .* [shape_xy[:, 2] shape_xy[:, 1]]
    end
    return shapes
end


############### Cootes images (from ICAAM) ###################

const COOTES_DATA_DIR = joinpath(Pkg.dir(), "FaceDatasets", "data", "cootes", "data")
const COOTES_IMG_HEIGHT = 480

function load_shape_from_mat(path::AbstractString)
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
        img_rgb = load(paths[i])
        img_rgb = convert(Image{RGB{Float64}}, img_rgb)  # ensure 3-channel RGB
        imgs[i] = convert(Array, separate(img_rgb))
    end
    return imgs
end


############### Kaggle FER Competition ###################
# See https://www.kaggle.com/c/challenges-in-representation-learning-facial-expression-recognition-challenge/ for details


function load_images_kaggle_fer(datadir::AbstractString)
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


function load_labels_kaggle_fer(datadir::AbstractString)
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



################## Generic functions ######################

const AVAILABLE_DATASETS = [:ck, :ck_max, :cootes, :kaggle_fer]


function load_images(dataset_name::Symbol; datadir="", start=1, count=-1,
                     resizeratio=1.0, indexes=[])
    if dataset_name == :ck
        return load_images_ck(datadir, start=start, count=count,
                              resizeratio=resizeratio, indexes=indexes)
    elseif dataset_name == :ck_max
        return load_images_ck_max(datadir, resizeratio=resizeratio)
    elseif dataset_name == :cootes
        return load_images_cootes(count=count)
    elseif dataset_name == :kaggle_fer
        return load_images_kaggle_fer(datadir)    
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
    elseif dataset_name == :ck_max
        return load_shapes_ck_max(datadir, resizeratio=resizeratio)
    elseif dataset_name == :cootes
        return load_shapes_cootes(count=count)
    elseif dataset_name == :kaggle_fer
        error(":kaggle_fer dataset doesn't provide shape data")    
    else 
        error("Dataset $dataset_name is not supported, available datasets: $AVAILABLE_DATASETS")
    end
end


function load_labels(dataset_name::Symbol;
                     datadir="")
    if dataset_name == :ck
        return load_labels_ck(datadir)
    elseif dataset_name == :ck_max
        return load_labels_ck(datadir)
    elseif dataset_name == :cootes
        error(":cootes dataset doesn't provide labels")
    elseif dataset_name == :kaggle_fer
        return load_labels_kaggle_fer(datadir)    
    else
        error("Dataset $dataset_name is not supported, available datasets: $AVAILABLE_DATASETS")
    end
end
