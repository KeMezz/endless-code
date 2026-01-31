//
//  FileSystemItemTests.swift
//  EndlessCodeTests
//
//  FileSystemItem 모델 단위 테스트
//

import Testing
import Foundation
@testable import EndlessCode

// MARK: - FileSystemItem Tests

@Suite("FileSystemItem Tests")
struct FileSystemItemTests {
    @Test("File extension returns correct value")
    func fileExtensionReturnsCorrectValue() {
        // Given
        let item = FileSystemItem(
            name: "main.swift",
            path: "/test/main.swift",
            isDirectory: false
        )

        // Then
        #expect(item.fileExtension == "swift")
    }

    @Test("Directory has no file extension")
    func directoryHasNoFileExtension() {
        // Given
        let item = FileSystemItem(
            name: "src",
            path: "/test/src",
            isDirectory: true
        )

        // Then
        #expect(item.fileExtension == nil)
    }

    @Test("File without extension returns nil")
    func fileWithoutExtensionReturnsNil() {
        // Given
        let item = FileSystemItem(
            name: "Makefile",
            path: "/test/Makefile",
            isDirectory: false
        )

        // Then
        #expect(item.fileExtension == nil)
    }

    @Test("File type detected correctly for Swift")
    func fileTypeDetectedCorrectlyForSwift() {
        // Given
        let item = FileSystemItem(
            name: "main.swift",
            path: "/test/main.swift",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .swift)
    }

    @Test("File type detected correctly for JavaScript")
    func fileTypeDetectedCorrectlyForJavaScript() {
        // Given
        let item = FileSystemItem(
            name: "index.js",
            path: "/test/index.js",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .javascript)
    }

    @Test("File type detected correctly for TypeScript")
    func fileTypeDetectedCorrectlyForTypeScript() {
        // Given
        let item = FileSystemItem(
            name: "app.tsx",
            path: "/test/app.tsx",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .typescript)
    }

    @Test("File type detected correctly for Python")
    func fileTypeDetectedCorrectlyForPython() {
        // Given
        let item = FileSystemItem(
            name: "script.py",
            path: "/test/script.py",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .python)
    }

    @Test("File type detected correctly for Rust")
    func fileTypeDetectedCorrectlyForRust() {
        // Given
        let item = FileSystemItem(
            name: "main.rs",
            path: "/test/main.rs",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .rust)
    }

    @Test("File type detected correctly for Go")
    func fileTypeDetectedCorrectlyForGo() {
        // Given
        let item = FileSystemItem(
            name: "main.go",
            path: "/test/main.go",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .go)
    }

    @Test("File type detected correctly for JSON")
    func fileTypeDetectedCorrectlyForJSON() {
        // Given
        let item = FileSystemItem(
            name: "config.json",
            path: "/test/config.json",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .json)
    }

    @Test("File type detected correctly for Markdown")
    func fileTypeDetectedCorrectlyForMarkdown() {
        // Given
        let item = FileSystemItem(
            name: "README.md",
            path: "/test/README.md",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .markdown)
    }

    @Test("File type detected correctly for images")
    func fileTypeDetectedCorrectlyForImages() {
        let extensions = ["png", "jpg", "jpeg", "gif", "svg", "webp"]

        for ext in extensions {
            let item = FileSystemItem(
                name: "image.\(ext)",
                path: "/test/image.\(ext)",
                isDirectory: false
            )
            #expect(item.fileType == .image, "Expected .image for .\(ext)")
        }
    }

    @Test("File type returns folder for directory")
    func fileTypeReturnsFolderForDirectory() {
        // Given
        let item = FileSystemItem(
            name: "src",
            path: "/test/src",
            isDirectory: true
        )

        // Then
        #expect(item.fileType == .folder)
    }

    @Test("File type returns unknown for unrecognized extension")
    func fileTypeReturnsUnknownForUnrecognizedExtension() {
        // Given
        let item = FileSystemItem(
            name: "file.xyz",
            path: "/test/file.xyz",
            isDirectory: false
        )

        // Then
        #expect(item.fileType == .unknown)
    }

    @Test("Depth calculated correctly for root")
    func depthCalculatedCorrectlyForRoot() {
        // Given
        let item = FileSystemItem(
            name: "file.swift",
            path: "/file.swift",
            isDirectory: false
        )

        // Then
        #expect(item.depth == 1)
    }

    @Test("Depth calculated correctly for nested path")
    func depthCalculatedCorrectlyForNestedPath() {
        // Given
        let item = FileSystemItem(
            name: "file.swift",
            path: "/Users/test/project/src/file.swift",
            isDirectory: false
        )

        // Then
        #expect(item.depth == 5)
    }

    @Test("Identifiable conformance uses id")
    func identifiableConformanceUsesId() {
        // Given
        let item = FileSystemItem(
            id: "unique-id",
            name: "test.swift",
            path: "/test.swift",
            isDirectory: false
        )

        // Then
        #expect(item.id == "unique-id")
    }

    @Test("Hashable conformance based on id only")
    func hashableConformanceBasedOnIdOnly() {
        // Given - 같은 ID, 다른 내용
        let item1 = FileSystemItem(
            id: "id-1",
            name: "test.swift",
            path: "/test.swift",
            isDirectory: false
        )
        let item2 = FileSystemItem(
            id: "id-1",
            name: "different.swift",  // 다른 이름
            path: "/different.swift",  // 다른 경로
            isDirectory: true  // 다른 타입
        )

        // Then - ID가 같으면 해시값도 같음
        #expect(item1.hashValue == item2.hashValue)
        #expect(item1 == item2)
    }

    @Test("Different ids produce different hash")
    func differentIdsProduceDifferentHash() {
        // Given
        let item1 = FileSystemItem(
            id: "id-1",
            name: "test.swift",
            path: "/test.swift",
            isDirectory: false
        )
        let item2 = FileSystemItem(
            id: "id-2",
            name: "test.swift",
            path: "/test.swift",
            isDirectory: false
        )

        // Then
        #expect(item1 != item2)
    }

    @Test("Git status can be set")
    func gitStatusCanBeSet() {
        // Given
        var item = FileSystemItem(
            name: "test.swift",
            path: "/test.swift",
            isDirectory: false
        )

        // When
        item.gitStatus = .modified

        // Then
        #expect(item.gitStatus == .modified)
    }

    @Test("Children can be set")
    func childrenCanBeSet() {
        // Given
        var folder = FileSystemItem(
            name: "src",
            path: "/src",
            isDirectory: true
        )

        let child = FileSystemItem(
            name: "main.swift",
            path: "/src/main.swift",
            isDirectory: false
        )

        // When
        folder.children = [child]

        // Then
        #expect(folder.children?.count == 1)
        #expect(folder.children?.first?.name == "main.swift")
    }

    @Test("Symbolic link flag works")
    func symbolicLinkFlagWorks() {
        // Given
        let item = FileSystemItem(
            name: "link",
            path: "/test/link",
            isDirectory: false,
            isSymbolicLink: true
        )

        // Then
        #expect(item.isSymbolicLink == true)
    }
}

// MARK: - GitFileStatus Tests

@Suite("GitFileStatus Tests")
struct GitFileStatusTests {
    @Test("Modified status has correct raw value")
    func modifiedStatusHasCorrectRawValue() {
        #expect(GitFileStatus.modified.rawValue == "M")
    }

    @Test("Added status has correct raw value")
    func addedStatusHasCorrectRawValue() {
        #expect(GitFileStatus.added.rawValue == "A")
    }

    @Test("Deleted status has correct raw value")
    func deletedStatusHasCorrectRawValue() {
        #expect(GitFileStatus.deleted.rawValue == "D")
    }

    @Test("Renamed status has correct raw value")
    func renamedStatusHasCorrectRawValue() {
        #expect(GitFileStatus.renamed.rawValue == "R")
    }

    @Test("Copied status has correct raw value")
    func copiedStatusHasCorrectRawValue() {
        #expect(GitFileStatus.copied.rawValue == "C")
    }

    @Test("Untracked status has correct raw value")
    func untrackedStatusHasCorrectRawValue() {
        #expect(GitFileStatus.untracked.rawValue == "?")
    }

    @Test("Ignored status has correct raw value")
    func ignoredStatusHasCorrectRawValue() {
        #expect(GitFileStatus.ignored.rawValue == "!")
    }

    @Test("Unmerged status has correct raw value")
    func unmergedStatusHasCorrectRawValue() {
        #expect(GitFileStatus.unmerged.rawValue == "U")
    }

    @Test("Status colors are defined")
    func statusColorsAreDefined() {
        let allStatuses: [GitFileStatus] = [
            .modified, .added, .deleted, .renamed, .copied,
            .untracked, .ignored, .unmerged
        ]

        for status in allStatuses {
            #expect(!status.color.isEmpty, "Color should be defined for \(status)")
        }
    }

    @Test("Status descriptions are defined")
    func statusDescriptionsAreDefined() {
        let allStatuses: [GitFileStatus] = [
            .modified, .added, .deleted, .renamed, .copied,
            .untracked, .ignored, .unmerged
        ]

        for status in allStatuses {
            #expect(!status.description.isEmpty, "Description should be defined for \(status)")
        }
    }

    @Test("Modified status has orange color")
    func modifiedStatusHasOrangeColor() {
        #expect(GitFileStatus.modified.color == "orange")
    }

    @Test("Added status has green color")
    func addedStatusHasGreenColor() {
        #expect(GitFileStatus.added.color == "green")
    }

    @Test("Deleted status has red color")
    func deletedStatusHasRedColor() {
        #expect(GitFileStatus.deleted.color == "red")
    }
}

// MARK: - FileFilterOption Tests

@Suite("FileFilterOption Tests")
struct FileFilterOptionTests {
    @Test("All cases are defined")
    func allCasesAreDefined() {
        let cases = FileFilterOption.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.all))
        #expect(cases.contains(.modified))
        #expect(cases.contains(.recent))
        #expect(cases.contains(.new))
    }

    @Test("Each option has icon name")
    func eachOptionHasIconName() {
        for option in FileFilterOption.allCases {
            #expect(!option.iconName.isEmpty, "Icon should be defined for \(option)")
        }
    }

    @Test("Each option has id")
    func eachOptionHasId() {
        for option in FileFilterOption.allCases {
            #expect(option.id == option.rawValue)
        }
    }

    @Test("All filter has doc.on.doc icon")
    func allFilterHasCorrectIcon() {
        #expect(FileFilterOption.all.iconName == "doc.on.doc")
    }

    @Test("Modified filter has pencil icon")
    func modifiedFilterHasCorrectIcon() {
        #expect(FileFilterOption.modified.iconName == "pencil")
    }

    @Test("Recent filter has clock icon")
    func recentFilterHasCorrectIcon() {
        #expect(FileFilterOption.recent.iconName == "clock")
    }

    @Test("New filter has plus.circle icon")
    func newFilterHasCorrectIcon() {
        #expect(FileFilterOption.new.iconName == "plus.circle")
    }
}

// MARK: - FileType Tests

@Suite("FileType Tests")
struct FileTypeTests {
    @Test("Each file type has icon name")
    func eachFileTypeHasIconName() {
        let types: [FileType] = [
            .folder, .swift, .javascript, .typescript, .python,
            .rust, .go, .java, .kotlin, .ruby, .php, .html, .css,
            .json, .yaml, .markdown, .text, .image, .video, .audio,
            .pdf, .archive, .binary, .unknown
        ]

        for type in types {
            #expect(!type.iconName.isEmpty, "Icon should be defined for \(type)")
        }
    }

    @Test("Folder type returns folder.fill icon")
    func folderTypeHasCorrectIcon() {
        #expect(FileType.folder.iconName == "folder.fill")
    }

    @Test("Swift type returns swift icon")
    func swiftTypeHasCorrectIcon() {
        #expect(FileType.swift.iconName == "swift")
    }

    @Test("JSON type returns curlybraces icon")
    func jsonTypeHasCorrectIcon() {
        #expect(FileType.json.iconName == "curlybraces")
    }

    @Test("Image type returns photo.fill icon")
    func imageTypeHasCorrectIcon() {
        #expect(FileType.image.iconName == "photo.fill")
    }

    @Test("Extension mapping for jsx returns javascript")
    func jsxExtensionMapsToJavaScript() {
        #expect(FileType.from(extension: "jsx") == .javascript)
    }

    @Test("Extension mapping for tsx returns typescript")
    func tsxExtensionMapsToTypeScript() {
        #expect(FileType.from(extension: "tsx") == .typescript)
    }

    @Test("Extension mapping for pyi returns python")
    func pyiExtensionMapsToPython() {
        #expect(FileType.from(extension: "pyi") == .python)
    }

    @Test("Extension mapping for yml returns yaml")
    func ymlExtensionMapsToYaml() {
        #expect(FileType.from(extension: "yml") == .yaml)
    }

    @Test("Extension mapping for mdx returns markdown")
    func mdxExtensionMapsToMarkdown() {
        #expect(FileType.from(extension: "mdx") == .markdown)
    }
}

// MARK: - FileSystemError Tests

@Suite("FileSystemError Tests")
struct FileSystemErrorTests {
    @Test("PathNotFound error has description")
    func pathNotFoundErrorHasDescription() {
        let error = FileSystemError.pathNotFound("/test/path")
        #expect(error.errorDescription?.contains("/test/path") == true)
    }

    @Test("AccessDenied error has description")
    func accessDeniedErrorHasDescription() {
        let error = FileSystemError.accessDenied("/test/path")
        #expect(error.errorDescription?.contains("/test/path") == true)
    }

    @Test("NotADirectory error has description")
    func notADirectoryErrorHasDescription() {
        let error = FileSystemError.notADirectory("/test/path")
        #expect(error.errorDescription?.contains("/test/path") == true)
    }

    @Test("SymbolicLinkLoop error has description")
    func symbolicLinkLoopErrorHasDescription() {
        let error = FileSystemError.symbolicLinkLoop("/test/path")
        #expect(error.errorDescription?.contains("/test/path") == true)
    }

    @Test("DepthLimitExceeded error has description")
    func depthLimitExceededErrorHasDescription() {
        let error = FileSystemError.depthLimitExceeded(50)
        #expect(error.errorDescription?.contains("50") == true)
    }

    @Test("ReadError has description")
    func readErrorHasDescription() {
        let error = FileSystemError.readError("Test message")
        #expect(error.errorDescription?.contains("Test message") == true)
    }
}
