{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedLists #-}

module Main where

import Test.HUnit
import Turtle
import Prelude hiding (FilePath)
import qualified Data.Map.Strict as Map
import qualified Control.Foldl as Fold
import qualified Data.Text as T
import qualified Integration
import Common

inputFiles = ["./base/dir1/d1f2.csv",
              "./base/dir2/d2f1.csv",
              "./base/dir1/d1f1.csv",
              "./base/dir2/d2f2.csv"] :: [FilePath]

journalFiles = map (changeExtension "journal") inputFiles

groupedIncludeFiles :: Map.Map FilePath [FilePath]
groupedIncludeFiles = [("./base/dir1-include.journal", ["./base/dir1/d1f2.journal", "./base/dir1/d1f1.journal"]),
                       ("./base/dir2-include.journal", ["./base/dir2/d2f1.journal", "./base/dir2/d2f2.journal"])]

testGroupBy = TestCase (do
                           let grouped = groupValuesBy includeFilePath journalFiles :: Map.Map FilePath [FilePath]
                           assertEqual "Group Files by Dir" groupedIncludeFiles grouped)

testGroupPairs = TestCase (do
                              let actual = groupPairs . pairBy includeFilePath $ journalFiles
                              assertEqual "Group files, paired by the directories they live in" groupedIncludeFiles actual)

testToIncludeLine = TestCase (do
                                 let expected = "!include file1.journal"
                                 let actual = toIncludeLine "./base/dir/" "./base/dir/file1.journal"
                                 assertEqual "Include line" expected actual)
testToIncludeFiles = TestCase (
  do
    let expected = [("./base/dir1-include.journal",
                     "### Generated by hledger-makeitso - DO NOT EDIT ###\n\n" <>
                      "!include dir1/d1f1.journal\n" <>
                      "!include dir1/d1f2.journal\n"),
                    ("./base/dir2-include.journal",
                     "### Generated by hledger-makeitso - DO NOT EDIT ###\n\n" <>
                      "!include dir2/d2f1.journal\n" <>
                      "!include dir2/d2f2.journal\n")]
    let txt = toIncludeFiles groupedIncludeFiles :: Map.Map FilePath Text
    assertEqual "Convert a grouped map of paths, to a map with text contents for each file" expected txt)

unitTests = TestList [testGroupBy, testGroupPairs, testToIncludeLine, testToIncludeFiles]

tests = TestList [unitTests, Integration.tests]

main :: IO Counts
main = do
  counts <- runTestTT tests
  if (errors counts > 0 || failures counts > 0)
    then exit $ ExitFailure 1
    else return counts
