using FaceDatasets
using Base.Test

# Cootes dataset is bundled with a package, so it's safe to load it
load_images(CootesDataset)
load_shapes(CootesDataset)
