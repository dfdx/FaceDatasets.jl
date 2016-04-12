# FaceDatasets

[![Build Status](https://travis-ci.org/dfdx/FaceDatasets.jl.svg)](https://travis-ci.org/dfdx/FaceDatasets.jl)

Package for making access to popular face datasets easier.

## General usage

    load_images(<dataset_name>, <dataset_params>...)  # faces
    load_shapes(<dataset_name>, <dataset_params>...)  # face landmarks
    load_labels(<dataset_name>, <dataset_params>...)  # provided labels

For example, to load `CootesDataset`, enter:

    load_images(CootesDataset)

Note, that all methods return iterable objects: for small datasets they are just arrays, for larger iterators are returned instead. You can always materialize them using:

    collect(load_images(...))


## Available datasets

### Cootes images

`CootesDataset` contains images from Tim Cootes' work on active appearance models. These images come prepacked, so you can use them for testing.

Supported functions:
 * `load_images(CootesDataset)`
 * `load_shapes(CootesDataset)`

### Cohn-Kanade+ dataset

`CKDataset` contains images from [Cohn-Kanade+ Expression Database](http://www.pitt.edu/~emotion/ck-spread.htm). To install this dataset, download it from [this page](http://www.consortium.ri.cmu.edu/ckagree/) and unpack into a directory of your choice. Example of expected directory layout:


```
$ tree -L 2
.
├── cohn-kanade-images
│   ├── S005
│   ├── S010
│   ├── S011
│   ...
│   └── S999
├── Emotion
│   ├── S005
│   ├── S010
│   ├── S011
│   ...
│   └── S999
└── Landmarks
    ├── S005
    ├── S010
    ├── S011
    ...
    └── S999
```

Supported functions:
 * `load_images(CKDataset, datadir, opts...)`
 * `load_shapes(CKDataset, datadir, opts...)`
 * `load_labels(CKDataset, datadir, opts...)`

where `datadir` is base dir for CK dataset and labels are numbers representing 6 basic emotions + neutral facial expression.

Options:

 * `start` - image index to start with
 * `count` - number of images to return
 * `indexes` - concrete indexes to return (`start` and `count` are ignored)
 * `resizeratio` - resize image by this value


### Cohn-Kanade+ (max only) dataset

`CKMaxDataset` - same as Cohn-Kanade+ dataset, but contains only images with maximally expressed emotion (~500 images). Only `resizeration` option is supported, though.


TODO: `KaggleFERDataset`
TODO: `PutFrontalDataset`