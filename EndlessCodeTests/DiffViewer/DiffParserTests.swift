//
//  DiffParserTests.swift
//  EndlessCodeTests
//
//  DiffParser 단위 테스트 (Swift Testing)
//

import Testing
@testable import EndlessCode

@Suite("DiffParser Tests")
struct DiffParserTests {
    let parser = DiffParser()

    // MARK: - Basic Parsing Tests

    @Test("Parse simple git diff returns file and hunk")
    func parseSimpleGitDiff() throws {
        let diffText = """
        diff --git a/test.swift b/test.swift
        index abc123..def456 100644
        --- a/test.swift
        +++ b/test.swift
        @@ -1,3 +1,4 @@
         import Foundation
        -let old = 1
        +let new = 2
        +let another = 3
         print("done")
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files.count == 1)
        #expect(result.files[0].displayPath == "test.swift")
        #expect(result.files[0].hunks.count == 1)
    }

    @Test("Parse file header extracts paths")
    func parseFileHeader() throws {
        let diffText = """
        diff --git a/Sources/App.swift b/Sources/App.swift
        --- a/Sources/App.swift
        +++ b/Sources/App.swift
        @@ -1,1 +1,1 @@
        -old
        +new
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].oldPath == "Sources/App.swift")
        #expect(result.files[0].newPath == "Sources/App.swift")
    }

    @Test("Parse hunk header extracts line numbers")
    func parseHunkHeader() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -10,5 +12,7 @@ func example()
         context line
        """

        let result = try parser.parse(diffText, isStaged: nil)

        let hunk = result.files[0].hunks[0]
        #expect(hunk.oldStart == 10)
        #expect(hunk.oldCount == 5)
        #expect(hunk.newStart == 12)
        #expect(hunk.newCount == 7)
        #expect(hunk.contextText == "func example()")
    }

    // MARK: - Line Type Tests

    @Test("Parse added line has correct type")
    func parseAddedLine() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,1 +1,2 @@
         existing
        +new line
        """

        let result = try parser.parse(diffText, isStaged: nil)
        let lines = result.files[0].hunks[0].lines

        let addedLine = lines.first { $0.type == .added }
        #expect(addedLine != nil)
        #expect(addedLine?.content == "new line")
        #expect(addedLine?.oldLineNumber == nil)
        #expect(addedLine?.newLineNumber != nil)
    }

    @Test("Parse deleted line has correct type")
    func parseDeletedLine() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,2 +1,1 @@
         existing
        -deleted line
        """

        let result = try parser.parse(diffText, isStaged: nil)
        let lines = result.files[0].hunks[0].lines

        let deletedLine = lines.first { $0.type == .deleted }
        #expect(deletedLine != nil)
        #expect(deletedLine?.content == "deleted line")
        #expect(deletedLine?.oldLineNumber != nil)
        #expect(deletedLine?.newLineNumber == nil)
    }

    @Test("Parse context line has both line numbers")
    func parseContextLine() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,2 +1,2 @@
         context line
        -old
        +new
        """

        let result = try parser.parse(diffText, isStaged: nil)
        let lines = result.files[0].hunks[0].lines

        let contextLine = lines.first { $0.type == .context }
        #expect(contextLine != nil)
        #expect(contextLine?.content == "context line")
        #expect(contextLine?.oldLineNumber == 1)
        #expect(contextLine?.newLineNumber == 1)
    }

    // MARK: - File Status Tests

    @Test("Parse new file detects added status")
    func parseNewFile() throws {
        let diffText = """
        diff --git a/new.txt b/new.txt
        new file mode 100644
        --- /dev/null
        +++ b/new.txt
        @@ -0,0 +1,2 @@
        +line 1
        +line 2
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].fileStatus == .added)
        #expect(result.files[0].oldPath == nil)
        #expect(result.files[0].newPath == "new.txt")
    }

    @Test("Parse deleted file detects deleted status")
    func parseDeletedFile() throws {
        let diffText = """
        diff --git a/old.txt b/old.txt
        deleted file mode 100644
        --- a/old.txt
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -line 1
        -line 2
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].fileStatus == .deleted)
        #expect(result.files[0].oldPath == "old.txt")
    }

    @Test("Parse modified file detects modified status")
    func parseModifiedFile() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,1 +1,1 @@
        -old
        +new
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].fileStatus == .modified)
    }

    @Test("Parse renamed file detects renamed status")
    func parseRenamedFile() throws {
        let diffText = """
        diff --git a/old-name.txt b/new-name.txt
        rename from old-name.txt
        rename to new-name.txt
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].fileStatus == .renamed)
        #expect(result.files[0].oldPath == "old-name.txt")
        #expect(result.files[0].newPath == "new-name.txt")
    }

    // MARK: - Multiple Files Tests

    @Test("Parse multiple files returns all files")
    func parseMultipleFiles() throws {
        let diffText = """
        diff --git a/file1.txt b/file1.txt
        --- a/file1.txt
        +++ b/file1.txt
        @@ -1,1 +1,1 @@
        -old1
        +new1
        diff --git a/file2.txt b/file2.txt
        --- a/file2.txt
        +++ b/file2.txt
        @@ -1,1 +1,1 @@
        -old2
        +new2
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files.count == 2)
        #expect(result.files[0].displayPath == "file1.txt")
        #expect(result.files[1].displayPath == "file2.txt")
    }

    @Test("Parse multiple hunks in same file")
    func parseMultipleHunks() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,3 +1,3 @@
         context
        -old1
        +new1
         more context
        @@ -10,3 +10,3 @@
         another context
        -old2
        +new2
         end context
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].hunks.count == 2)
        #expect(result.files[0].hunks[0].oldStart == 1)
        #expect(result.files[0].hunks[1].oldStart == 10)
    }

    // MARK: - Statistics Tests

    @Test("Calculate additions and deletions correctly")
    func calculateStatistics() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,3 +1,4 @@
         context
        -deleted
        +added1
        +added2
         end
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].additions == 2)
        #expect(result.files[0].deletions == 1)
        #expect(result.totalAdditions == 2)
        #expect(result.totalDeletions == 1)
    }

    // MARK: - Binary File Tests

    @Test("Parse binary file sets isBinary flag")
    func parseBinaryFile() throws {
        let diffText = """
        diff --git a/image.png b/image.png
        Binary files a/image.png and b/image.png differ
        """

        let result = try parser.parse(diffText, isStaged: nil)

        #expect(result.files[0].isBinary == true)
    }

    // MARK: - Staged Status Tests

    @Test("Parse with isStaged preserves staged status")
    func parseWithStagedStatus() throws {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,1 +1,1 @@
        -old
        +new
        """

        let resultStaged = try parser.parse(diffText, isStaged: true)
        let resultUnstaged = try parser.parse(diffText, isStaged: false)

        #expect(resultStaged.isStaged == true)
        #expect(resultUnstaged.isStaged == false)
    }

    // MARK: - Error Tests

    @Test("Parse empty string throws emptyDiff")
    func parseEmptyString() {
        #expect(throws: DiffError.emptyDiff) {
            try parser.parse("", isStaged: nil)
        }
    }

    @Test("Parse non-diff text throws invalidFormat")
    func parseNonDiffText() {
        #expect(throws: DiffError.self) {
            try parser.parse("This is not a diff", isStaged: nil)
        }
    }

    // MARK: - containsDiff Tests

    @Test("containsDiff returns true for valid diff")
    func containsDiffReturnsTrueForValidDiff() {
        let diffText = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        @@ -1,1 +1,1 @@
        """

        #expect(parser.containsDiff(diffText) == true)
    }

    @Test("containsDiff returns false for non-diff text")
    func containsDiffReturnsFalseForNonDiff() {
        let text = "This is just regular text"

        #expect(parser.containsDiff(text) == false)
    }

    @Test("containsDiff detects hunk pattern without git header")
    func containsDiffDetectsHunkPattern() {
        let text = """
        --- a/test.txt
        +++ b/test.txt
        @@ -1,1 +1,1 @@
        -old
        +new
        """

        #expect(parser.containsDiff(text) == true)
    }
}

// MARK: - DiffDataSource Tests

@Suite("DiffDataSource Tests")
struct DiffDataSourceTests {
    let dataSource = DiffDataSource()

    @Test("extractFromToolResult returns diff when present")
    func extractFromToolResultReturnsDiff() {
        let output = """
        diff --git a/test.swift b/test.swift
        --- a/test.swift
        +++ b/test.swift
        @@ -1,1 +1,1 @@
        -old
        +new
        """

        let result = dataSource.extractFromToolResult(output)

        #expect(result != nil)
        #expect(result?.files.count == 1)
    }

    @Test("extractFromToolResult returns nil for non-diff")
    func extractFromToolResultReturnsNilForNonDiff() {
        let output = "Just some regular text output"

        let result = dataSource.extractFromToolResult(output)

        #expect(result == nil)
    }

    @Test("isGitDiffOutput returns true for git diff")
    func isGitDiffOutputReturnsTrueForGitDiff() {
        let output = """
        diff --git a/test.txt b/test.txt
        --- a/test.txt
        +++ b/test.txt
        """

        #expect(dataSource.isGitDiffOutput(output) == true)
    }

    @Test("isGitDiffOutput returns false for non-diff")
    func isGitDiffOutputReturnsFalseForNonDiff() {
        let output = "ls -la output"

        #expect(dataSource.isGitDiffOutput(output) == false)
    }
}

// MARK: - DiffStatistics Tests

@Suite("DiffStatistics Tests")
struct DiffStatisticsTests {
    @Test("Statistics calculates totals correctly")
    func statisticsCalculatesTotalsCorrectly() {
        let diff = UnifiedDiff(
            files: [
                DiffFile(
                    oldPath: "a.txt",
                    newPath: "a.txt",
                    hunks: [
                        DiffHunk(
                            header: "@@",
                            oldStart: 1,
                            oldCount: 1,
                            newStart: 1,
                            newCount: 3,
                            lines: [
                                DiffLine(type: .added, content: "1"),
                                DiffLine(type: .added, content: "2"),
                                DiffLine(type: .deleted, content: "3"),
                            ]
                        )
                    ],
                    fileStatus: .modified
                ),
                DiffFile(oldPath: nil, newPath: "b.txt", hunks: [], fileStatus: .added),
            ]
        )

        let statistics = DiffStatistics(from: diff)

        #expect(statistics.totalFiles == 2)
        #expect(statistics.totalAdditions == 2)
        #expect(statistics.totalDeletions == 1)
        #expect(statistics.totalChanges == 3)
        #expect(statistics.filesByStatus[.modified] == 1)
        #expect(statistics.filesByStatus[.added] == 1)
    }
}
