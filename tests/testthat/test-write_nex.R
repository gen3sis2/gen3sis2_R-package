# Expected Newick strings below were captured from the previous writer.
nex_output <- function(phy, label = "sp", to = 0, connection = FALSE) {
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
  expect_identical(nex_output(phy, to = 1), "1")
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
  # Installed packages expose inst/extdata as extdata, outside the test folder.
  fixture <- system.file("extdata", "TestOutputs", "geodyn_raster",
                         package = "gen3sis2", mustWork = TRUE)
  phy <- read.table(file.path(fixture, "phy.txt"), header = TRUE)
  expect_identical(nex_output(phy, label = "species"),
                   readLines(file.path(fixture, "phy.nex")))
})

test_that("nested histories preserve both continuing and daughter branches", {
  phy <- data.frame(Ancestor = c(1, 1, 2, 1, 3, 2, 5), Descendent = 1:7,
                    Speciation.Time = 10:4, Extinction.Time = -1,
                    Speciation.Type = c("ROOT", rep("SPLIT", 6)))
  expect_identical(nex_output(phy), nex_expected(paste0(
    "((sp1:7,sp4:7):2,((sp2:5,sp6:5):3,",
    "(sp3:6,(sp5:4,sp7:4):2):2):1):1")))
})

test_that("branches stop at duration to for one, two and three roots", {
  for (root_count in 1:3) {
    phy <- data.frame(Ancestor = c(1, 1, 1, 2, 3), Descendent = 1:5,
                      Speciation.Time = c(10, 10, 10, 6, 4),
                      Extinction.Time = c(-1, 0, 2, -1, 1),
                      Speciation.Type = c(rep("ROOT", root_count),
                                          rep("SPLIT", 5 - root_count)))
    expected <- nex_output(phy, to = 0)
    # Translating every event and the simulation end by the same amount must
    # leave all branch durations unchanged. Includes surviving and extinct tips,
    # extinction exactly at the last step, and the synthetic multi-root tip.
    for (stop_time in c(1, 5, 10, 10.5, -5)) {
      shifted <- phy
      shifted$Speciation.Time <- phy$Speciation.Time + stop_time
      shifted$Extinction.Time <- phy$Extinction.Time + stop_time
      expect_identical(nex_output(shifted, to = stop_time), expected)
    }
  }
})

test_that("extant and extinct tips end at the correct nonzero times", {
  phy <- data.frame(Ancestor = c(1, 1, 1), Descendent = 1:3,
                    Speciation.Time = c(20, 15, 12),
                    Extinction.Time = c(9, 13, 10),
                    Speciation.Type = c("ROOT", "SPLIT", "SPLIT"))
  # to=10: species 1 survives (sentinel 9), species 2 died at 13,
  # species 3 died at the final step 10. Only the survivor is clamped.
  expect_identical(nex_output(phy, to = 10),
                   nex_expected("((sp1:2,sp3:2):3,sp2:2):5"))
})

test_that("singleton survival uses the configured final timestep", {
  for (stop_time in c(0, 1, 10)) {
    phy <- nex_phy()[1, ]
    phy$Speciation.Time <- stop_time + 10
    phy$Extinction.Time <- stop_time - 1
    expect_identical(nex_output(phy, to = stop_time), "1")
    phy$Extinction.Time <- stop_time
    expect_identical(nex_output(phy, to = stop_time), "0")
  }
})

test_that("the simulation's survivor marker is clamped to its stopping time", {
  for (stop_time in c(0, 10)) {
    config <- list(gen3sis = list(general = list(duration = list(to = stop_time))))
    phy <- data.frame(Ancestor = c(1, 1), Descendent = 1:2,
                      Speciation.Time = stop_time + c(10, 5),
                      Extinction.Time = stop_time + c(10, 2),
                      Speciation.Type = c("ROOT", "SPLIT"))
    data <- list(phy = phy, all_species = list(
      list(id = 1, abundance = c(cell = 1)),
      list(id = 2, abundance = numeric())))
    updated <- update_extinction_times(config, data, list(ti = stop_time))
    expect_identical(updated$data$phy$Extinction.Time, stop_time + c(-1, 2))
    expect_identical(nex_output(updated$data$phy, to = stop_time),
                     nex_expected("(sp1:5,sp2:3):5"))
  }
})
