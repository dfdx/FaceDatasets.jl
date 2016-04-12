
## PUT face database
## https://biometrics.cie.put.poznan.pl/index.php?option=com_content&view=article&id=4&Itemid=2&lang=en

immutable PutDataset <: FaceDataset
end

immutable PutFrontalDataset <: FaceDataset
end


function shape_to_image_path(shape_path)
    dir, filename = splitdir(shape_path)
    subjdir = basename(dir)
    basedir = dirname(dirname(dir))
    return joinpath(basedir, "images", "0" * subjdir[2:end],
                    replace(filename, ".yml", ".JPG"))
end


function load_images(::Type{PutFrontalDataset}, datadir::AbstractString;
                     downscale_times::Int=3)
    contourdir = joinpath(datadir, "contours")
    contourfiles = walkdir(contourdir)
    files = map(shape_to_image_path, contourfiles)
    function it()
        for file in files
            img = Images.load(file)
            # downscale if needed
            for i=1:downscale_times
                img = restrict(img)
            end
            arr = rgb2arr(img)            
            produce(arr)
        end
    end
    return @task it()
end


function load_shape_put(path::AbstractString)
    # YAML parser couldn't parse it, fall back to a stupid manual method
    lines = split(open(readall, path), "\r\n")
    x_lines = filter(l -> startswith(l, "x"), map(strip, lines))
    xs = [parse(Float64, l[4:end]) for l in x_lines]
    y_lines = filter(l -> startswith(l, "y"), map(strip, lines))
    ys = [parse(Float64, l[4:end]) for l in y_lines]
    return hcat(ys, xs)  # ij coordinates 
end

function load_shapes(::Type{PutFrontalDataset}, datadir::AbstractString;
                     downscale_times::Int=3)
    contourdir = joinpath(datadir, "contours")
    files = walkdir(contourdir)
    function it()
        for file in files
            shape = load_shape_put(file)
            downscaled = shape ./ (2^(downscale_times))
            produce(downscaled)
        end
    end
    return @task it()
end
