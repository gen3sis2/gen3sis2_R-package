# Expected Newick strings below were captured from the previous writer.
nex_output <- function(phy, label = "sp", to = 1, connection = FALSE) {
  val <- list(config = list(gen3sis = list(general = list(
    duration = list(to = to)))))
  path <- tempfile(fileext = ".nex")
  on.exit(unlink(path))
  if (connection) {
    con <- file(path, "wt")
    tryCatch(write_nex(phy, label, con), finally = close(con))
  } else {
    write_nex(phy, label, path)
  }
  readLines(path)
}

nex_phy <- function() {
  data.frame(Ancestor = c(1L, 1L, 1L, 2L), Descendent = 1:4,
             Speciation.Time = c(10, 8, 5, 3),
             Extinction.Time = c(2, 1, 0, 0),
             Speciation.Type = c("ROOT", "SPLIT", "SPLIT", "SPLIT"))
}

nex_expected <- function(tree) {
  c("#NEXUS", "begin trees;", paste0("Tree tree = ", tree, ";"), "end;",
    paste0("[!Tree generated with the gen3sis R package, following convention ",
           "of TreeSim and TreeSimGM r-packages]"))
}

test_that("single-root event trees preserve ordering, lengths and NEXUS framing", {
  phy <- nex_phy()
  original <- phy
  expected <- nex_expected("((sp1:3,sp3:5):3,(sp2:2,sp4:3):5):2")
  expect_identical(nex_output(phy), expected)
  expect_identical(phy, original)
  expect_identical(nex_output(phy, connection = TRUE), expected)
  expect_identical(nex_output(phy, label = "species"),
                   gsub("sp([1-4]):", "species\\1:", expected))
})

test_that("multiple roots preserve the synthetic tip and shifted species IDs", {
  phy <- nex_phy()
  phy$Speciation.Type[2] <- "ROOT"
  phy$Speciation.Time[2] <- 10
  phy$Speciation.Type <- factor(phy$Speciation.Type)
  expect_identical(nex_output(phy), nex_expected(
    "((sp1:10,(sp3:2,sp5:3):7):0,(sp2:3,sp4:5):5):0"))
  phy <- phy[1:2, ]
  expect_identical(nex_output(phy), nex_expected(
    "((sp1:10,sp3:9):0,sp2:8):0"))
})

test_that("a lone root retains the live and extinct sentinel outputs", {
  phy <- nex_phy()[1, ]
  expect_identical(nex_output(phy), "0")
  phy$Extinction.Time <- 0
  expect_identical(nex_output(phy), "1")
  phy$Extinction.Time <- -1
  expect_identical(nex_output(phy, to = 0), "1")
})

test_that("simultaneous splits and fractional times retain zero-length edges", {
  phy <- nex_phy()
  phy$Speciation.Time <- c(10.5, 5.5, 5.5, 3.5)
  phy$Extinction.Time <- c(0, -1, 0, 0)
  expect_identical(nex_output(phy), nex_expected(
    "((sp1:5.5,sp3:5.5):0,(sp2:3.5,sp4:3.5):2):5"))
})

test_that("a deep tree serializes without recursion or lost tips", {
  n <- 10000L
  phy <- data.frame(Ancestor = rep(1L, n), Descendent = seq_len(n),
                    Speciation.Time = rev(seq_len(n)), Extinction.Time = 0,
                    Speciation.Type = c("ROOT", rep("SPLIT", n - 1L)))
  tree <- nex_output(phy)[3]
  expect_identical(length(regmatches(tree, gregexpr("sp[0-9]+:", tree))[[1]]), n)
  expect_identical(length(regmatches(tree, gregexpr("\\(", tree))[[1]]), n - 1L)
  expect_identical(length(regmatches(tree, gregexpr("\\)", tree))[[1]]), n - 1L)
  expect_true(endsWith(tree, "):1;"))
})

test_that("the saved simulation phylogeny matches its existing NEXUS output", {
  fixture <- test_path("..", "..", "inst", "extdata", "TestOutputs", "geodyn_raster")
  phy <- read.table(file.path(fixture, "phy.txt"), header = TRUE)
  expect_identical(nex_output(phy, label = "species"),
                   readLines(file.path(fixture, "phy.nex")))
})
