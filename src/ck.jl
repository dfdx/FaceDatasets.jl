
############### Cohn-Kanade+ dataset #####################

immutable CKDataset <: FaceDataset
end

function load_images(::Type{CKDataset}, datadir::AbstractString;
                     start=1, count=-1,
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


function load_shapes(::Type{CKDataset}, datadir::AbstractString; start=1, count=-1,
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

function load_labels(::Type{CKDataset}, datadir::AbstractString)
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


immutable CKMaxDataset <: FaceDataset
end    


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


function load_images(::Type{CKMaxDataset}, datadir::AbstractString; resizeratio=1.0)
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


function load_shapes(::Type{CKMaxDataset}, datadir::AbstractString; resizeratio=1.0)
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
