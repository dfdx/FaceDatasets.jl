# FaceDatasets

[![Build Status](https://travis-ci.org/dfdx/FaceDatasets.jl.svg)](https://travis-ci.org/dfdx/FaceDatasets.jl)

Package for making access to popular face datasets easier.

## General usage

    load_images(<dataset_name>, <dataset_params>...)
    load_shapes(<dataset_name>, <dataset_params>...)
    ...

For example, to load images from Tim Cootes' work, type:

    load_images(:cootes)

## Available datasets

Currently, following datasets are available:

1. `:cootes` - images from original work on active appearance models by Tim Cootes. For research usage only. 
2. `:ck` - Cohn-Kanade+ dataset. Since this dataset cannot be redistributed with a package, user is required to [download](http://www.consortium.ri.cmu.edu/ckagree/) it manually, unzip and pass path to it as a `datadir` parameter:

    load_images(:ck, datadir="/data/ck")