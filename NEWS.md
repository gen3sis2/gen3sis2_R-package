## Version v1.0.0 (Release)

-   The code from `gen3sis` were reworked removing the dependencies from `raster`.
-   Cost function syntax were simplified and enhanced.
-   Distance matrices calculation is now implemented with a dedicated function.
-   Distance matrices cam now be asymmetrical.
-   `gen3sis` landscapes.rds were replaced by spaces.rds, an enhanced version with three types:
    -   raster
    -   H3
    -   points
-   Spaces now carry richer metadata and can be compressed/decompressed with spac3tools for easier sharing and reproducibility.
-   Added an explicit biotic-to-abiotic feedback pathway so simulations can look back from biotic outcomes to the underlying environment.
-   Time logic were redesign. The config and the space can have different time-frames.
-   Plotting was reconstructed with `ggplot2`.
-   Added many new support functions and utilities.

